# Zone 1 Shift Roster – Investigation

## Overview

The **Zone 1 Shift roster** is a different beast from the Zone 1 M-F roster:

| Aspect | Zone 1 M-F (done) | Zone 1 Shift (this) |
|--------|-------------------|---------------------|
| **Cycle length** | 12 weeks | **86 weeks** |
| **Fill block** | 12 weeks | **15 weeks** (proposed) |
| **Days per week** | Mon–Fri work, Sat–Sun always Rest | **All 7 days** – rest days (R) rotate |
| **Rest days** | Fixed (Sat, Sun) | **Variable** – must match roster |
| **Duty structure** | Same duty all week | **Different duty per day** |

## Critical: Rest Day Matching

For Shift roster, **rest days vary by week**. Examples from the screenshots:
- **WK 1:** R on Sun, Mon
- **WK 2:** R on Sun, Fri
- **WK 3:** R on Wed, Sat

When filling 15 weeks, we must **only create events on work days**. Days marked "R" in the roster = no event (rest day). This matches how people's rest days work in the rotating pattern.

## Data Structure from Screenshots

- **Columns:** Week | [Duration] | Day1 | Day2 | Day3 | Day4 | Day5 | Day6 | Day7
- **Day order:** Assuming Sun=0 … Sat=6 (typical roster)
- **Values:** Either `"R"` (rest) or `"PZ1/XX"` (duty code)
- **Duration column:** Time values (e.g. 8:03, 5:15) on certain weeks – likely weekly total; can include in JSON for reference or skip for fill logic

## JSON Structure (like M-F but adapted)

```json
{
  "description": "86-week Zone 1 Shift roster. Rest days (R) rotate. 15-week fill blocks.",
  "zone": "1",
  "scheduleType": "Shift",
  "cycleLengthWeeks": 86,
  "fillBlockWeeks": 15,
  "dayNames": ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
  "weeks": [
    {
      "weekNumber": 1,
      "days": ["R", "R", "PZ1/65", "PZ1/65", "PZ1/65", "PZ1/65", "PZ1/57"]
    },
    ...
  ]
}
```

Each `days` array has 7 entries: Sun through Sat. `"R"` = rest (no event), `"PZ1/XX"` = create event with that duty.

## Anchor / Week Lookup

Unlike M-F (one duty per week = easy lookup), Shift has **multiple duties per week**. To find which week a user is in when they add a duty:

1. **Option A:** User picks the **Sunday** of their starting week and a duty from that day (or any day) – we search the roster for a week where that day has that duty.
2. **Option B:** User says "I'm starting Week 12" – direct.
3. **Option C:** User adds one duty (e.g. Monday PZ1/21) – we search for a week where Monday = PZ1/21. Problem: PZ1/21 might appear in multiple weeks on different days. We'd need (dayOfWeek, duty) → weekIndex mapping.

**Recommendation:** Build a lookup map: `(dayIndex, dutyCode)` → list of week indices. When user adds "Monday PZ1/21", we find weeks where Mon = PZ1/21. If unique, use it. If multiple, ask user to pick or use the most recent/next occurrence.

## Fill Logic (15 weeks)

1. User adds a duty for a specific date (e.g. next Monday).
2. We determine the roster week index (0–85) from that date + duty.
3. For the next 15 weeks, for each day:
   - Get roster entry for (weekIndex + weekOffset, dayOfWeek)
   - If "R" → skip (do not create event)
   - If "PZ1/XX" → create event (unless date already has event, or bank holiday)
4. Skip filled days, skip bank holidays (or treat as rest – Shift may have different bank holiday rules).

## Implementation Phases

1. **JSON file** – Build `zone1_shift_86week_roster.json` with structure + all 86 weeks (transcribe from screenshots; weeks 16–32, 39–66 need the middle image data).
2. **RosterService** – Add `loadZone1ShiftRoster()`, `getZone1ShiftDayDuty(weekIndex, dayIndex)`, lookup helpers.
3. **UI** – Checkbox "Auto-fill the next 15 weeks from my roster?" when adding a duty, for **Shift** + Zone 1 users.
4. **Fill logic** – Iterate 15 weeks × 7 days, create events only where roster says PZ1/XX, skip R.

## Saturday Service (Dec 24, 27, 29, 30, 31)

Certain dates run **Saturday service** regardless of weekday: Dec 24, 27, 29, 30, 31 (except when they fall on Sunday). `RosterService.isSaturdayService(date)` returns true for these.

**Effect:**
- `getDayOfWeek(date)` returns `'Saturday'` → duty lookup uses `SAT_DUTIES_PZ1.csv`
- Saturday duties differ from M-F duties (different codes, times, routes)

**Zone 1 Shift 15-week fill:**
- Current logic uses roster column `d` (0–6) matching the calendar day. For Monday Dec 29 (Saturday service), we use Monday column → duty e.g. PZ1/32.
- `_getShiftTimes(duty, targetDate)` loads SAT file (correct) but looks for a Monday-duty code in the SAT file – it may not exist.
- **Fix:** For Saturday service dates, use the roster's **Saturday** column (index 6) for the duty, not the actual weekday. The driver works their Saturday duty on that day.
- `rosterDayIndex = RosterService.isSaturdayService(targetDate) ? 6 : d`
- If roster Saturday = R, skip (rest day). If PZ1/XX, create event – duty will exist in SAT file.

## Saturday Service

**Saturday service dates** (Dec 24, 27, 29, 30, 31 – except when they fall on Sunday) run Saturday bus schedules regardless of actual weekday. The app uses `RosterService.isSaturdayService(date)` and `getDayOfWeek(date)` returns 'Saturday' for these dates, so CSV lookup uses `SAT_DUTIES_PZ1.csv` instead of M-F.

**Impact on Zone 1 Shift 15-week fill:**
- For a date like Monday Dec 29 (Saturday service), the driver works their **Saturday** roster duty, not Monday’s.
- The roster’s Monday column (e.g. PZ1/32) may not exist in the SAT CSV; Saturday duties use different codes.
- **Fix:** When `isSaturdayService(targetDate)` is true, use the roster’s **Saturday** column (dayIndex 6) for the duty, not the actual weekday.
- `_getShiftTimes(zone, duty, targetDate)` already uses `getDayOfWeek(targetDate)`, so it loads the SAT file correctly.
- If the roster’s Saturday column is "R", no event is created (driver rests on that Saturday service date).

## Saturday Service (Dec 24, 27, 29, 30, 31)

These dates run **Saturday schedules** regardless of actual weekday. `RosterService.isSaturdayService(date)` identifies them.

**Impact on 15-week fill:**
- On Saturday service dates (e.g. Monday Dec 29), drivers work their **Saturday** roster slot, not the weekday slot.
- Shift times load from `SAT_DUTIES_PZ1.csv` (already handled by `_getShiftTimes` via `getDayOfWeek`).
- The roster duty must come from the **Saturday** column (dayIndex 6), not the actual weekday.
- **Fix:** Use `rosterDayIndex = isSaturdayService(targetDate) ? 6 : d` when looking up duty.

## Open Questions

1. **Bank holidays** – For Shift roster, are bank holidays rest, or do some people work? (M-F treats them as rest.)
2. **Duration column** – Use for anything (e.g. validation, display) or ignore?
3. **Week definition** – Does the roster week start Sunday or Monday? Affects date math.
4. **86 weeks transcription** – Three screenshots cover different ranges. Need full roster or can we derive a pattern?
