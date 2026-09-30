"""Build Zone4_Boards_20260823.json from M-F / Sat / Sun running-board CSVs."""

from __future__ import annotations

import csv
import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_JSON = ROOT / "assets" / "Zone4_Boards_20260823.json"

SOURCES = (
    ("MON-FRI", ROOT / "tool" / "zone4_mf_running_boards_20260823.csv", ROOT / "assets" / "M-F_ROUTE2324_20260823.csv"),
    ("SAT", ROOT / "tool" / "zone4_sat_running_boards_20260823.csv", ROOT / "assets" / "SAT_ROUTE2324_20260823.csv"),
    ("SUN", ROOT / "tool" / "zone4_sun_running_boards_20260823.csv", ROOT / "assets" / "SUN_ROUTE2324_20260823.csv"),
)

TAKE_BUS_RE = re.compile(r"takes?\s+bus|take\s+bus|taake\s+bus", re.I)
TIME_RE = re.compile(r"\b(\d{1,2}:\d{2})\b")


def clean(value: str | None) -> str:
    return (value or "").replace("\xa0", " ").strip()


def pad_cells(raw: list[str], n: int = 12) -> list[str]:
    cells = [clean(c) for c in raw]
    if len(cells) < n:
        cells.extend([""] * (n - len(cells)))
    return cells[:n]


def duty_number(value: str) -> str | None:
    digits = re.sub(r"\D", "", value or "")
    if len(digits) == 3 and digits.startswith("4"):
        return digits
    return None


def shift_code(duty_num: str) -> str:
    n = int(duty_num)
    if 401 <= n <= 440:
        return f"PZ4/{n - 400:02d}"
    if 451 <= n <= 457:
        return f"PZ4/{n - 450}X"
    if 471 <= n <= 474:
        return f"PZ4/{n - 470}N"
    raise ValueError(f"Unknown duty number {duty_num}")


def is_title_row(cells: list[str]) -> bool:
    joined = " ".join(cells)
    if "RUNNING BOARD" in joined or "BUS ATHA CLIATH" in joined:
        return True
    if "Phibsboro Zone" in joined or "Routes 23/24" in joined:
        return True
    if cells[0] == "Route" and cells[3] == "Place":
        return True
    return False


def bus_name(cells: list[str]) -> str | None:
    for cell in cells:
        if re.fullmatch(r"BUS\s+\d+", cell, flags=re.I):
            return cell.upper()
    return None


def side_has_content(side: list[str]) -> bool:
    route, label, num, place, arr, dep = side
    if place or arr or dep or route:
        return True
    return label.lower() in {"duty", "finish"}


def first_time(side: list[str]) -> str | None:
    for part in (side[3], side[4], side[5]):
        match = TIME_RE.search(part)
        if match:
            hh, mm = match.group(1).split(":")
            return f"{int(hh):02d}:{mm}"
    return None


def minutes_from_hhmm(value: str) -> int:
    hh, mm = (int(x) for x in value.split(":"))
    minutes = hh * 60 + mm
    # Night second halves (02:xx) sort after evening first halves.
    # Do not wrap 04:xx–05:xx garage reports or they land after a 10:30 take-up.
    if hh < 4:
        minutes += 24 * 60
    return minutes


def sort_key(segment: list[list[str]]) -> int:
    for row in segment:
        t = first_time(row)
        if t:
            return minutes_from_hhmm(t)
    return 0


def hhmm(value: str) -> str:
    value = clean(value)
    if not value or value.lower() == "nan":
        return "00:00"
    return value[:5]


def load_bill_headers(bill_csv: Path) -> dict[str, dict[str, str]]:
    headers: dict[str, dict[str, str]] = {}
    with bill_csv.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            shift = row["shift"].strip()
            headers[shift] = {
                "duty": row["duty"].strip()[-3:],
                "depot": "7",
                "report": hhmm(row["report"]),
                "depart": hhmm(row["depart"]),
                "signoff": hhmm(row["signoff"]),
                "spread": hhmm(row["spread"]),
                "work": hhmm(row["work"]),
                "relief": hhmm(row["relief"]),
            }
    return headers


def parse_pages(source_csv: Path) -> list[dict]:
    with source_csv.open(encoding="utf-8-sig", newline="") as f:
        rows = [pad_cells(r) for r in csv.reader(f)]

    pages: list[dict] = []
    current: dict | None = None
    for cells in rows:
        if "RUNNING BOARD" in " ".join(cells):
            if current:
                pages.append(current)
            current = {"bus": "", "left": [], "right": []}
            continue
        if current is None:
            continue
        name = bus_name(cells)
        if name:
            current["bus"] = name
        if is_title_row(cells):
            continue
        current["left"].append(cells[0:6])
        current["right"].append(cells[6:12])
    if current:
        pages.append(current)
    return pages


def parse_side(side_rows: list[list[str]]) -> tuple[list[list[str]], list[tuple[str, list[list[str]]]]]:
    """Split a column into an unlabelled prefix and duty segments.

    The prefix is trip rows at the top of the right-hand column before the
    first Duty header — the wrap from the bottom of the left column.
    """
    prefix: list[list[str]] = []
    segments: list[tuple[str, list[list[str]]]] = []
    current_duty: str | None = None
    current_seg: list[list[str]] = []
    capturing_prefix = True

    def flush() -> None:
        nonlocal current_seg
        if current_duty and current_seg:
            segments.append((current_duty, current_seg))
        current_seg = []

    for side in side_rows:
        if not side_has_content(side):
            continue
        route, label, num, place, arr, dep = side
        label_l = label.lower()
        num_duty = duty_number(num)

        if capturing_prefix:
            if label_l == "duty" and num_duty:
                capturing_prefix = False
            else:
                prefix.append(side)
                if label_l == "finish":
                    capturing_prefix = False
                continue

        if label_l == "finish":
            if current_duty:
                current_seg.append(side)
            continue

        if label_l == "duty" and num_duty:
            if current_duty and num_duty != current_duty:
                flush()
            elif current_duty and current_seg and TAKE_BUS_RE.search(
                current_seg[-1][3]
            ):
                flush()
            current_duty = num_duty
            current_seg.append(side)
            continue

        if current_duty:
            current_seg.append(side)

    flush()
    return prefix, segments


def ends_with_finish(segment: list[list[str]]) -> bool:
    return any(row[1].lower() == "finish" for row in segment)


def collect_segments(source_csv: Path) -> dict[str, list[list[list[str]]]]:
    segments: dict[str, list[list[list[str]]]] = defaultdict(list)

    for page in parse_pages(source_csv):
        left_prefix, left_segs = parse_side(page["left"])
        right_prefix, right_segs = parse_side(page["right"])

        if left_prefix:
            # Left-column wrap is unexpected; keep the rows if a duty follows.
            if left_segs:
                left_segs[0][1][0:0] = left_prefix
            elif right_segs:
                right_segs[0][1][0:0] = left_prefix

        if right_prefix and left_segs and not ends_with_finish(left_segs[-1][1]):
            left_segs[-1][1].extend(right_prefix)
        elif right_prefix and right_segs:
            right_segs[0][1][0:0] = right_prefix

        for duty, seg in left_segs + right_segs:
            segments[duty].append(seg)

    return segments


def to_board_row(side: list[str]) -> list[str]:
    route, label, num, place, arr, dep = [clean(c) for c in side]
    if label.lower() == "finish":
        return ["", "Finish", "Duty", "", "", ""]
    if label.lower() == "duty" and duty_number(num):
        return ["", "Duty", duty_number(num) or num, place, "", ""]
    if not place and not arr and not dep:
        return ["", "", "", "", "", ""]
    return [route, "", "", place, arr, dep]


def is_take_bus_only(segment: list[list[str]]) -> bool:
    rows = [row for row in segment if side_has_content(row)]
    if len(rows) != 1:
        return False
    return TAKE_BUS_RE.search(rows[0][3]) is not None


def build_board(segments: list[list[list[str]]]) -> list[list[str]]:
    ordered = [
        seg
        for seg in sorted(segments, key=sort_key)
        if seg and not is_take_bus_only(seg)
    ]
    rows: list[list[str]] = []

    def append_seg(seg: list[list[str]]) -> None:
        for side in seg:
            row = to_board_row(side)
            if row == ["", "Finish", "Duty", "", "", ""]:
                continue
            if row[0] == "" and row[1] == "" and row[3] == "" and row[4] == "" and row[5] == "":
                continue
            rows.append(row)

    if not ordered:
        return rows

    append_seg(ordered[0])
    if len(ordered) > 1:
        rows.append(["---", "", "", "", "", ""])
        for seg in ordered[1:]:
            append_seg(seg)

    if not rows or rows[-1][1] != "Finish":
        rows.append(["", "Finish", "Duty", "", "", ""])
    return rows


def import_day(day_key: str, source_csv: Path, bill_csv: Path) -> dict[str, dict]:
    headers = load_bill_headers(bill_csv)
    segments = collect_segments(source_csv)
    day_output: dict[str, dict] = {}
    missing: list[str] = []

    for shift, header in headers.items():
        duty_num = header["duty"]
        board = build_board(segments.get(duty_num, []))
        if len(board) <= 1:
            missing.append(shift)
        day_output[shift] = {**header, "board": board}

    extra = sorted(set(segments) - {h["duty"] for h in headers.values()})
    print(f"{day_key}: {len(day_output)} duties")
    if missing:
        print(f"  thin/missing: {', '.join(missing)}")
    if extra:
        print(f"  extra source duties: {', '.join(extra)}")
    return day_output


def main() -> None:
    merged: dict[str, dict] = {}
    for day_key, source_csv, bill_csv in SOURCES:
        for shift, day_data in import_day(day_key, source_csv, bill_csv).items():
            merged.setdefault(shift, {})[day_key] = day_data

    OUTPUT_JSON.write_text(
        json.dumps(merged, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {OUTPUT_JSON.name} with {len(merged)} duties")

    samples = (
        ("PZ4/01", "SAT"),
        ("PZ4/01", "SUN"),
        ("PZ4/21", "SAT"),
        ("PZ4/12", "SUN"),
    )
    for shift, day in samples:
        print(f"\n=== {shift} {day} ===")
        for row in merged[shift][day]["board"]:
            print(row)


if __name__ == "__main__":
    main()
