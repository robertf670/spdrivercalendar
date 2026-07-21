# Spare Driver Calendar — Modernisation Plan

> **Purpose:** A long-term roadmap to make the app faster, smoother, maintainable, and ready to roll out across **10+ depots** with significantly more data than today.
>
> **Current version:** 3.2.8  
> **Last updated:** July 2026 (remote CSV section added)  
> **Status:** Living document — update as phases complete or priorities shift.

---

## Table of Contents

1. [Vision & Success Criteria](#1-vision--success-criteria)
2. [Current State (Honest Assessment)](#2-current-state-honest-assessment)
3. [Strategic Pillars](#3-strategic-pillars)
4. [Multi-Depot Architecture (Critical Path)](#4-multi-depot-architecture-critical-path)
5. [Data Layer Evolution](#5-data-layer-evolution)
6. [Performance & Smoothness](#6-performance--smoothness)
7. [Codebase Structure & State Management](#7-codebase-structure--state-management)
8. [UI/UX Modernisation](#8-uiux-modernisation)
9. [Remote CSV & Content Management](#9-remote-csv--content-management)
10. [Firebase & Backend Strategy](#10-firebase--backend-strategy)
11. [Security, Admin & Operations](#11-security-admin--operations)
12. [Testing & Quality Gates](#12-testing--quality-gates)
13. [Phased Roadmap](#13-phased-roadmap)
14. [Metrics & Benchmarks](#14-metrics--benchmarks)
15. [Risks & Mitigations](#15-risks--mitigations)
16. [Decision Log](#16-decision-log)

---

## 1. Vision & Success Criteria

### Where we are going

The app today serves drivers at **one operational context** — zones, duty CSVs, rosters, locations, and payscales are largely **hardcoded for a single depot ecosystem**. Rolling out to **10+ depots** means:

- Each depot may have different zones, roster patterns, duty files, routes, locations, contacts, and pay rules.
- Bundling all depot data inside the app binary becomes **impossible** (APK size, update friction, stale data).
- Users need a **depot-aware** experience without carrying irrelevant data for other depots.
- Content updates (duty corrections, new routes, **new CSV files**) must reach all depots **without app store releases**.
- **Duty CSVs must live remotely** (Firebase Storage) so you can add, replace, or correct files on the fly from Firebase Console — not by shipping a new APK.

### What “done” looks like

| Area | Target |
|------|--------|
| **Cold start** | Interactive UI within ~1s; critical data loaded progressively |
| **Calendar** | 60fps month navigation; no full-screen flash on day tap |
| **Multi-depot** | User selects depot once; only that depot’s config/data is loaded |
| **Remote CSVs** | All duty/route CSVs served from Firebase Storage; bundled assets are fallback only |
| **On-the-fly updates** | Upload or edit a CSV in Firebase → users get it on next check (startup or manual), offline-safe via local cache |
| **Data updates** | Duty CSV / roster changes delivered remotely within hours, offline-safe |
| **Maintainability** | No single file > ~1,000 lines; core logic covered by unit tests |
| **Scale** | 10+ depots supported without linear growth in app size or startup time |
| **Reliability** | Notifications, backup, and sync working consistently |

---

## 2. Current State (Honest Assessment)

### Strengths

- **Flutter 3.13+** with **Material 3** theming (`useMaterial3: true`)
- **Feature-based folder structure** under `lib/features/` (calendar, settings, statistics, etc.)
- **Parallel startup initialisation** in `main.dart` via `Future.wait`
- In-memory **month-based event caching** in `EventService`
- **Firebase** already integrated (Analytics, Firestore for live updates, polls, toilet codes, user activity)
- **Remote CSV update plan** documented in `CSV_UPDATE_SYSTEM_PLAN.md`
- **Responsive design rules** and audit in `RESPONSIVE_ISSUES_REPORT.md`
- **Backup system** (auto-backup on app pause, mobile)
- **Google Calendar sync**

### Technical debt & bottlenecks

| Issue | Impact | Location / evidence |
|-------|--------|---------------------|
| **God file: `calendar_screen.dart` (~12,000 lines)** | Massive rebuild scope, hard to optimise, risky to change | `lib/features/calendar/screens/calendar_screen.dart` |
| **Heavy `setState` usage** | Whole screens rebuild for small changes | 99+ calls in calendar alone |
| **`provider` in pubspec but unused** | Missed opportunity for scoped rebuilds | `pubspec.yaml` — no imports |
| **Blocking startup** | Long splash before UI | 8+ services init before `runApp()` |
| **SharedPreferences for all data** | Slow writes (reload + validate every save), not ideal for large JSON | `StorageService`, `EventService` |
| **Hardcoded depot data** | Cannot scale to 10+ depots | `assets/*.csv`, `location_constants.dart`, zone logic in calendar |
| **CSVs bundled in APK only** | Every duty fix requires app release | `RouteService` uses `rootBundle.loadString('assets/...')` |
| **Mixed folder structure** | Confusing ownership | `lib/features/` + legacy `lib/services/`, `lib/screens/` |
| **Static singleton services** | Hard to test, tight coupling | Most `*Service.initialize()` patterns |
| **Minimal test coverage** | Refactors are dangerous | 1 test file in `test/` |
| **Known broken features** | User trust | Notifications (per README) |
| **Platform workaround** | Full app rebuild on resume | `RebuildText` + native channel |

### Data footprint today (single depot)

- **~21 duty/route CSV files** in `assets/`
- **4 roster JSON files** (Zone 1 M-F, Zone 1 Shift, Zone 3 Shift, bank holidays)
- **Location mappings** hardcoded in `location_constants.dart`
- **Pay data** in `pay/` folder
- Firestore used for **shared operational content** (live updates, polls, toilet codes) — not yet for depot config

**At 10 depots (rough estimate):** 200+ CSV files, 40+ roster configs, 10× location maps — **must be remote, lazy-loaded, and depot-scoped**.

---

## 3. Strategic Pillars

All work should align to these five pillars:

```
┌─────────────────────────────────────────────────────────────────┐
│  1. DEPOT-FIRST DATA     Remote, lazy, depot-scoped content     │
│  2. REMOTE CSVs          Firebase Storage; add/update on fly    │
│  3. PERFORMANCE          Measure → fix bottlenecks → guard      │
│  4. ARCHITECTURE         Split god files, proper state mgmt     │
│  5. RELIABILITY          Notifications, backup, offline         │
│  6. OPERATIONS           Admin tools, analytics, rollout control  │
└─────────────────────────────────────────────────────────────────┘
```

**Rule:** Do not start pillar 2 (performance refactors) on the calendar until pillar 3 has a plan for splitting `calendar_screen.dart` — otherwise optimisations will be lost in the next edit.

---

## 4. Multi-Depot Architecture (Critical Path)

This is the **most important structural change** for the 10+ depot goal.

### 4.1 Introduce `Depot` as a first-class concept

Today the app implicitly assumes one depot. Introduce a **Depot configuration model**:

```dart
// Conceptual — not implemented yet
class DepotConfig {
  final String id;              // e.g. "birmingham", "manchester"
  final String displayName;     // e.g. "Birmingham Depot"
  final List<ZoneConfig> zones;   // Zone 1–4, UNI, Jamestown, etc.
  final RosterConfig rosters;   // M-F, Shift, per-zone cycle definitions
  final String payscaleAssetKey; // Remote or bundled reference
  final List<String> contacts;  // Or remote reference
  final Map<String, String> locationMappings;
  final List<String> bankHolidayRegion; // e.g. "england-and-wales"
  final bool featuresEnabled;   // Feature flags per depot
}
```

**User flow:**
1. First launch (or settings) → **Select depot**
2. App downloads **depot manifest** (small JSON) from Firebase Storage / Firestore
3. Only that depot’s CSVs, rosters, and config are cached locally
4. All storage keys that are depot-specific are **namespaced**: `events_{depotId}`, `markedInZone_{depotId}`, etc.
5. User data (their calendar events) stays tied to their chosen depot

### 4.2 Depot manifest structure (Firebase Storage)

```
firebase_storage://
└── depots/
    ├── manifest.json                    # List of all depots + version
    ├── birmingham/
    │   ├── config.json                  # Zones, rosters, feature flags
    │   ├── location_mappings.json
    │   ├── csv_files/
    │   │   ├── manifest.json           # File list + hashes (see §9.4)
    │   │   ├── M-F_DUTIES_PZ1.csv
    │   │   └── ...
    │   ├── rosters/
    │   │   ├── zone1_mf_12week.json
    │   │   └── zone1_shift_86week.json
    │   └── pay/
    │       └── payscale.csv
    ├── manchester/
    │   └── ...
    └── ... (10+ depots)
```

**`manifest.json` example:**
```json
{
  "version": "2026-07-01T00:00:00Z",
  "depots": [
    { "id": "birmingham", "name": "Birmingham", "active": true },
    { "id": "manchester", "name": "Manchester", "active": true }
  ]
}
```

### 4.3 Refactor hardcoded depot logic

| Current hardcoding | Multi-depot replacement |
|--------------------|-------------------------|
| `assets/M-F_DUTIES_PZ1.csv` | `DepotContentService.getCsv(depotId, 'M-F_DUTIES_PZ1')` |
| `location_constants.dart` | Loaded from `depots/{id}/location_mappings.json` |
| Zone 1–4 strings in calendar UI | `DepotConfig.zones` drives dropdown |
| `RosterService.rosterWeeks` (5-week) | Per-depot roster definitions in config |
| `zone1_mf_12week_roster.json` in assets | Per-depot roster files, remote |
| Bank holidays JSON | Region-aware; may differ per depot |
| Jamestown feature (depot-specific?) | Feature flag on `DepotConfig` |

### 4.4 Code zones vs operational zones

Clarify terminology in the codebase:

- **Depot** — physical location (Birmingham, Manchester, …)
- **Zone** — operational area within a depot (PZ1, PZ3, UNI, …)
- **Roster pattern** — shift cycle (5-week E/L/R, 12-week M-F duty, etc.)

Avoid mixing “Zone 1” as both a depot identifier and an in-depot zone.

### 4.5 Migration path for existing users

1. Ship depot selector with **one default depot** pre-selected (current behaviour, zero disruption)
2. Add `depotId` to backup format (version bump)
3. When second depot goes live, existing users keep their data under default depot ID
4. Document that **switching depot** is a destructive or export/import action (user calendar data is depot-specific)

### 4.6 APK / bundle size strategy

| Approach | Pros | Cons |
|----------|------|------|
| Bundle all depots | Offline day one | APK bloat, stale data, unmaintainable at 10+ |
| **Remote-only depot data (recommended)** | Small APK, fresh data | Needs network on first depot setup |
| Hybrid: bundle default depot + remote others | Good first-run UX | Two code paths |

**Recommendation:** Hybrid — bundle **one default depot** for offline-first onboarding; all others download on selection.

---

## 5. Data Layer Evolution

### 5.1 Current: SharedPreferences everywhere

`StorageService` wraps SharedPreferences with cache + write validation (reload + read-back). Robust but **expensive on hot paths** (every event save).

**Keep SharedPreferences for:**
- User settings (dark mode, notification prefs, marked-in status)
- Small flags and tokens
- Selected depot ID
- Last-seen version, onboarding state

**Move to structured local DB for:**
- Events (potentially thousands over years × 10 depots worth of reference data)
- Notes and attachments metadata
- Statistics cache
- Duty lookup indexes (parsed CSV cache)

### 5.2 Recommended local database: **Isar** or **drift**

| Option | Best for |
|--------|----------|
| **Isar** | Fast reads, simple schema, good for mobile-first |
| **drift (SQLite)** | Complex queries, migrations, relational data |

**Migration strategy:**
1. Introduce DB alongside SharedPreferences
2. One-time migration on app upgrade: read SP JSON → write to DB
3. Deprecate SP keys after stable release
4. Backup format includes DB export or remains JSON for portability

### 5.3 Parsed CSV cache

Today `RouteService` parses CSV from assets on demand into `_routeCache`. At scale:

- Pre-build **duty index** per depot (shift code → row) on depot download
- Store as SQLite/Isar table or binary snapshot
- Lookup becomes O(1) instead of parsing 500+ line CSV repeatedly
- Background isolate for initial parse (`compute()`)

### 5.4 Event storage improvements

`EventService` already has month-based caching — extend this:

- Persist events in DB keyed by `(depotId, date)`
- Load visible month ± 1 buffer only
- Debounce saves (300–500ms) instead of immediate SP write per field change
- Batch notification rescheduling

---

## 6. Performance & Smoothness

### 6.1 Measure first (Phase 0 — mandatory)

Before any refactor, capture baselines in **`--profile`** mode:

| Metric | How to measure | Target |
|--------|----------------|--------|
| Cold start to calendar | Timeline + stopwatch | < 2s total, UI < 1s |
| Month swipe jank | DevTools Performance | 0 dropped frames |
| Day tap response | Frame timeline | < 100ms to visual update |
| Event save latency | Log timestamps | < 200ms perceived |
| Memory after 10 min navigation | DevTools Memory | Stable, no leak |

Document results in `docs/performance-baseline.md` (create when Phase 0 runs).

### 6.2 Startup optimisation

**Current:** Everything in `main()` before `runApp()`.

**Target architecture:**
```
main()
  ├─ WidgetsFlutterBinding
  ├─ Firebase.init (required early if using Firestore on splash)
  ├─ StorageService.init (minimal)
  └─ runApp(AppShell)

AppShell (first frame)
  ├─ Show splash / skeleton calendar
  └─ Background: NotificationService, GoogleCalendar, ShiftService, depot manifest…

CalendarScreen
  └─ Load month events async with loading placeholder
```

**Defer:** Google Calendar init, analytics, backup check, non-default depot content.

### 6.3 Calendar rebuild scope

Root cause of jank: `calendar_screen.dart` + pervasive `setState`.

**Fix pattern:**
1. Extract `CalendarController` (ChangeNotifier or Riverpod)
2. Split UI: `CalendarHeader`, `CalendarGrid`, `DayDetailPanel`, `HolidaySection`
3. Use `Selector` / `ListenableBuilder` so day tap only rebuilds day detail
4. `RepaintBoundary` around animated day cells (already partially done)
5. `const` widgets wherever possible

### 6.4 Heavy computation off UI thread

Move to isolates:
- Statistics aggregation (year of shifts)
- CSV parsing on depot download
- Large roster auto-fill (12-week batch)
- Export generation

### 6.5 Remove `RebuildText` workaround

Investigate root cause of text rendering glitch on Android resume. Fix properly (font loading, Impeller, theme rebuild scope) so the entire app doesn’t `setState` on lifecycle resume.

---

## 7. Codebase Structure & State Management

### 7.1 Target folder structure

```
lib/
├── main.dart
├── app/                          # App shell, routing, DI
│   ├── app.dart
│   └── router.dart
├── core/                         # Shared utilities (keep lean)
│   ├── constants/
│   ├── services/
│   └── widgets/
├── features/
│   ├── calendar/
│   │   ├── controllers/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── dialogs/
│   │   └── services/
│   ├── depot/                    # NEW — depot selection & config
│   ├── settings/
│   └── ...
├── data/                         # NEW — repositories, DB, models
│   ├── local/
│   ├── remote/
│   └── repositories/
└── domain/                       # Optional — pure business logic
    └── roster/
```

**Migrate** legacy `lib/services/`, `lib/screens/`, `lib/widgets/` into `features/` over time.

### 7.2 State management decision

**Recommendation: Riverpod** (or use existing **Provider** — already in pubspec).

| Layer | Responsibility |
|-------|----------------|
| **Controllers / Notifiers** | Calendar state, settings, depot selection |
| **Repositories** | Event CRUD, depot content, backup |
| **Services** | Firebase, notifications, Google Calendar |
| **Widgets** | Dumb UI; subscribe via `Consumer` / `Selector` |

**Migration order:**
1. Depot selection + config
2. Calendar (biggest win)
3. Settings
4. Statistics

Do **not** big-bang migrate — one feature per release.

### 7.3 Split `calendar_screen.dart` (mandatory milestone)

Target decomposition:

| Extract to | Approx. lines | Responsibility |
|------------|---------------|----------------|
| `calendar_screen.dart` | 200–400 | Scaffold, navigation, controller wiring |
| `calendar_controller.dart` | 500–800 | State, data loading, business rules |
| `calendar_grid.dart` | 300–500 | Month grid, day cells |
| `day_detail_section.dart` | 400–600 | Selected day events, actions |
| `add_duty_flow/` | 800–1200 | Zone picker, roster auto-fill, duty creation |
| `holiday_section.dart` | 200–300 | Holiday tracking UI |
| Existing dialogs | — | Already partially extracted |

---

## 8. UI/UX Modernisation

### 8.1 Responsive design completion

Finish work tracked in `RESPONSIVE_ISSUES_REPORT.md`:

- [ ] Bills screen — fixed column widths
- [ ] Payscale screen — fixed column widths  
- [ ] About screen — 3-column grid on small phones
- [ ] Admin panel dialog — fixed max dimensions
- [ ] Audit remaining screens against `.cursor/rules/responsive_design.mdc`

### 8.2 Design system

Centralise in `app_theme.dart` + new `app_spacing.dart` / `app_typography.dart`:

- Breakpoint helper: `ResponsiveSizes.of(context)` (single source of truth)
- Standard padding, font scales, icon sizes
- Shared table/grid builders for payscale, bills, timing points

### 8.3 Navigation

Migrate from mixed `routes` + `Navigator.push` to **`go_router`**:

- Deep links for settings sub-pages
- Web URL support per route
- Typed route parameters

### 8.4 Onboarding for multi-depot

Extend welcome flow:

1. Welcome
2. **Select depot** (searchable list)
3. Download depot content (progress indicator)
4. Configure marked-in / rest pattern (existing)
5. Optional Google Calendar connect

### 8.5 Loading & empty states

Replace silent spinners with skeleton loaders on calendar, statistics, and depot download.

---

## 9. Remote CSV & Content Management

> **Goal:** Move all duty and route CSVs out of the app bundle and into **Firebase Storage**, so you can **add new files** and **update existing ones on the fly** without an app release. Users always read from a local cache when offline.
>
> **Detailed implementation spec:** `CSV_UPDATE_SYSTEM_PLAN.md` (single-depot first). This section integrates that plan into the wider modernisation roadmap and extends it for multi-depot.

### 9.1 Why remote CSVs matter

Today (~21 CSV files in `assets/`) are loaded via `rootBundle.loadString('assets/...')` in `RouteService`, duty pickers, and related services. That means:

- Every duty correction requires an **app update**
- Adding a new duty file (new zone, new route set) requires a **code change + release**
- At **10+ depots**, bundling hundreds of CSVs is **not viable**

**End state:** Firebase Storage is the **source of truth**; `assets/` keeps a **minimal fallback set** for first install / offline emergency only.

### 9.2 Migration stages (bundled → remote)

| Stage | When | Behaviour |
|-------|------|-----------|
| **A — Bundled only** | Today | All CSVs in `assets/`; no remote check |
| **B — Hybrid (target for first remote release)** | Phase 2a | Remote cache preferred; `assets/` fallback; manual + startup update check |
| **C — Remote primary** | Phase 4+ | New depots have **no bundled CSVs**; download on depot select; assets only for default depot bootstrap |
| **D — Remote only (long-term)** | Optional | Remove CSVs from APK entirely once cache reliability proven |

Do **not** jump from A to D in one release. Stage B proves the pipeline with low risk.

### 9.3 Firebase Storage layout

**Phase 2a — single depot (current app, before multi-depot):**

```
firebase_storage://
└── csv_files/
    ├── manifest.json                 # Version + file list (see §9.4)
    ├── M-F_DUTIES_PZ1.csv
    ├── M-F_DUTIES_PZ3.csv
    ├── SAT_DUTIES_PZ1.csv
    ├── SUN_ROUTE2324.csv
    ├── UNI_M-F.csv
    ├── JAMESTOWN_DUTIES.csv
    ├── training_duties.csv
    ├── buscheck.csv
    └── ... (all current assets/*.csv)
```

**Phase 2b+ — multi-depot (extends §4.2):**

```
firebase_storage://
└── depots/
    ├── manifest.json
    └── {depotId}/
        └── csv_files/
            ├── manifest.json
            ├── M-F_DUTIES_PZ1.csv
            └── ...
```

### 9.4 Manifest format (`manifest.json`)

Replace a single timestamp-only `version.json` with a **manifest** that supports **new files** and **per-file updates** (required for “add CSV on the fly”):

```json
{
  "version": "2026-07-03T14:30:00Z",
  "description": "Fixed PZ1/56 times; added M-F_DUTIES_PZ5.csv",
  "files": [
    { "name": "M-F_DUTIES_PZ1.csv", "hash": "sha256:abc123...", "sizeBytes": 48210 },
    { "name": "M-F_DUTIES_PZ5.csv", "hash": "sha256:def456...", "sizeBytes": 12400 }
  ]
}
```

**Update rules:**
- **Edit existing CSV** → change file in Storage, bump `version`, update that file’s `hash` in manifest
- **Add new CSV** → upload file, append entry to `files[]`, bump `version`
- **Remove CSV** → remove from manifest (app ignores file; optional cache cleanup)

App compares local manifest to remote: download only files whose `hash` differs or are missing locally.

### 9.5 Local cache structure

```
app_documents_directory/
└── csv_cache/                        # Phase 2a (single depot)
    ├── manifest.json
    ├── M-F_DUTIES_PZ1.csv
    └── ...

app_documents_directory/
└── depots/
    └── {depotId}/
        └── csv_cache/
            ├── manifest.json
            └── *.csv
```

### 9.6 File resolution priority (all CSV consumers)

Every code path that reads a CSV must use **one service** — no direct `rootBundle` calls:

```
1. Local cache (downloaded from Firebase)     ← primary when available
2. Bundled assets (assets/{filename})         ← fallback (Stage B/C)
3. Error / user message                       ← graceful degradation
```

**New service:** `CsvContentService` (or `DepotContentService.getCsv()` in multi-depot phase)

| Method | Purpose |
|--------|---------|
| `init()` | Ensure cache directories exist |
| `loadCsv(String filename)` | Resolve file per priority above |
| `checkForUpdates()` | Compare local vs remote manifest |
| `downloadUpdates()` | Fetch changed/new files only |
| `getLastUpdateTime()` | Settings UI |
| `clearCache()` | Troubleshooting / force re-download |
| `invalidateIndex()` | Clear parsed duty index after update |

**Code to refactor (currently use `rootBundle` / hardcoded assets):**
- `lib/features/calendar/services/route_service.dart`
- Duty picker / add-duty flow in `calendar_screen.dart`
- `JamestownFeatureService` CSV assets
- Any service loading `training_duties.csv`, `buscheck.csv`, UNI CSVs

### 9.7 On-the-fly update workflow (admin)

**Adding or updating a CSV without an app release:**

1. Open **Firebase Console → Storage**
2. Navigate to `csv_files/` (or `depots/{id}/csv_files/`)
3. **Update:** Replace existing `.csv` file (same filename)
4. **Add:** Upload new `.csv` file
5. Edit `manifest.json` — bump `version`, update `files[]` (hashes)
6. Users receive update via:
   - **Background check** on app startup (non-blocking)
   - **Settings → “Check for duty data updates”** (manual, immediate)
   - Optional: in-app banner if manifest `description` is set

**Typical turnaround:** Minutes from upload to users on next app open — no Play Store / GitHub release.

**Future enhancement (Phase 4):** Simple admin UI or script to upload CSV + auto-regenerate manifest hashes.

### 9.8 User-facing behaviour

| Trigger | Behaviour |
|---------|-----------|
| App startup | Background manifest check; download if changed (don’t block UI) |
| Settings tap | “Check for updates” with progress + last updated timestamp |
| After download | Invalidate duty index; duty picker uses new data immediately |
| Offline | Use cached CSVs silently; show “Last updated: …” in settings |
| Download failure | Keep using cache; optional snackbar if manifest unreachable |
| Stale cache (> N days) | Subtle indicator in settings (optional) |

### 9.9 Content update pipeline (full flow)

```
Admin uploads/changes CSV in Firebase Storage
        ↓
Updates manifest.json (version + file hashes)
        ↓
App checks manifest on startup OR manual "Check for updates"
        ↓
Downloads only changed/new files → local csv_cache/
        ↓
Invalidates parsed duty index (RouteService / DB index)
        ↓
Duty picker & route lookup use new data on next access
```

Same pipeline applies per-depot once multi-depot is live — only the Storage path changes.

### 9.10 Offline behaviour

1. **Local cache** — primary for day-to-day use (works fully offline)
2. **Bundled assets** — fallback on first install before first successful download
3. **Never block calendar** — if remote unreachable and cache exists, app works normally

### 9.11 App updates vs content updates

| Type | Delivery | Example |
|------|----------|---------|
| **CSV content update** | Firebase Storage | Fix PZ1/39 start time; add new zone CSV |
| **Roster JSON update** | Firebase Storage (same pipeline) | 12-week roster cycle change |
| **App update** | GitHub releases / Play Store | New feature, UI change, bug fix |
| **Feature flag** | Firestore or depot config | Enable Jamestown for one depot |

**Keep these separate** so duty fixes and new CSV files never require app store review.

### 9.12 Firebase Storage security rules

```text
# Read: authenticated app users (or public read if no auth on mobile — decide in Phase 2a)
# Write: false via client — uploads only via Firebase Console / admin SDK
match /csv_files/{allPaths=**} { allow read: if true; allow write: if false; }
match /depots/{depotId}/csv_files/{allPaths=**} { allow read: if true; allow write: if false; }
```

Tighten read rules if work-access or Firebase Auth is required for your deployment.

### 9.13 Implementation checklist (from `CSV_UPDATE_SYSTEM_PLAN.md`)

**Infrastructure:**
- [ ] Create Firebase Storage folder(s) and upload current `assets/*.csv`
- [ ] Create initial `manifest.json` with all files + hashes
- [ ] Configure Storage rules

**App code:**
- [ ] Create `CsvContentService` with cache + resolution logic
- [ ] Refactor `RouteService` to use `CsvContentService.loadCsv()`
- [ ] Refactor duty picker / calendar CSV loading
- [ ] Background update check on startup (non-blocking)
- [ ] Settings UI: “Check for duty data updates” + last updated time
- [ ] Parsed duty index invalidation after update
- [ ] Extend paths for `depots/{id}/csv_files/` when multi-depot lands

**Testing:**
- [ ] Fresh install: fallback to assets, then download
- [ ] Offline: cached CSVs work
- [ ] Update single CSV remotely: app picks up change
- [ ] Add new CSV to manifest: app downloads and uses it
- [ ] Corrupt download: fallback behaviour

### 9.14 Relationship to multi-depot (§4)

| Phase | CSV scope |
|-------|-----------|
| **2a** | Single `csv_files/` folder — proves remote pipeline for current depot |
| **2b** | Move to `depots/{defaultId}/csv_files/`; same service, different path |
| **4** | Each depot has its own CSV set; user only downloads their depot’s files |

Remote CSV work in **Phase 2a can start before** calendar decomposition finishes — it is largely independent if all consumers go through `CsvContentService`.

---

## 10. Firebase & Backend Strategy

### 10.1 Current Firestore usage

| Collection | Purpose | Multi-depot note |
|------------|---------|------------------|
| Live updates | Announcements | May need `depotIds[]` filter |
| Polls | User polls | Scope per depot or global |
| Toilet codes | Shared codes | Likely depot-specific |
| User activity | Analytics | Add `depotId` field |

### 10.2 Recommended Firestore additions

```
/depots/{depotId}           — config document (or Storage-only)
/liveUpdates/{id}           — add depotIds: string[]
/toiletCodes/{id}           — add depotId: string
/featureFlags/{key}         — global and per-depot overrides
```

### 10.3 Analytics

Add custom dimensions:
- `depot_id`
- `app_version`
- `marked_in_status`

Enables per-depot rollout monitoring.

### 10.4 Cost awareness at 10+ depots

- Firestore reads: prefer Storage for large static files (CSVs)
- Cache manifest locally; check version timestamp, not full file list
- Batch analytics events

---

## 11. Security, Admin & Operations

### 11.1 Admin access

Current: password in `AppConfig` + dart-define. For multi-depot ops:

- [ ] Role-based admin (super admin vs depot admin)
- [ ] Depot admin can upload CSVs for their depot only
- [ ] Audit log for content changes
- [ ] Remove hardcoded passwords from source where possible — use Firebase Auth + custom claims

### 11.2 Rollout control

- **`active: false`** on depot in manifest until ready
- Staged rollout: beta users → one depot → all depots
- In-app banner: “Manchester depot now available”

### 11.3 Backup & restore

Extend backup format:
```json
{
  "backupVersion": 2,
  "depotId": "birmingham",
  "appVersion": "3.2.8",
  "events": [...],
  "settings": {...}
}
```

Validate depot match on restore.

### 11.4 Fix known reliability gaps

- [ ] **Notifications** — currently broken (README); priority for user trust
- [ ] Google Calendar sync error surfacing
- [ ] Auto-backup failure notification

---

## 12. Testing & Quality Gates

> **Full spec:** `TESTING_PLAN.md` — priorities, first 10 tests, folder structure, phased rollout.

### 12.1 Minimum test suite (build over time)

| Priority | Test target |
|----------|-------------|
| P0 | `RosterService` date/week calculations |
| P0 | Event serialisation / deserialisation |
| P0 | Depot config loading + namespacing |
| P1 | `StorageService` / DB migration |
| P1 | CSV duty index lookup |
| P1 | Statistics calculations |
| P2 | Widget tests for calendar day cell |
| P2 | Integration: add duty → persists → reloads |

### 12.2 CI pipeline (recommended)

```yaml
# Conceptual
- flutter analyze
- flutter test
- build apk (profile) — catch compile breaks
```

### 12.3 Manual test matrix per release

- Small phone (320px), mid phone, tablet
- Cold start, month navigation, add/edit/delete duty
- Offline mode, depot download, content update
- Dark mode, backup restore
- Google Calendar sync (if changed)

---

## 13. Phased Roadmap

### Phase 0 — Baseline & foundations (2–3 weeks)

**Goal:** Know your numbers; stop the bleeding.

- [ ] Profile cold start, calendar jank, save latency — document baselines
- [ ] Fix notifications (or document why blocked)
- [ ] Complete critical responsive fixes (bills, payscale)
- [ ] Remove or implement unused `provider` dependency
- [ ] Create `lib/features/depot/` placeholder + `DepotConfig` model (design only)

**Release:** Patch version — no user-visible architecture change.

---

### Phase 1 — Calendar decomposition (4–6 weeks)

**Goal:** Make the calendar maintainable and rebuild-efficient.

- [ ] Extract `CalendarController`
- [ ] Split `calendar_screen.dart` into widgets (see §7.3)
- [ ] Introduce Provider/Riverpod for calendar state
- [ ] Scoped rebuilds on day selection / month change
- [ ] Defer non-critical startup init (§6.2)
- [ ] Unit tests for roster/date logic

**Release:** Minor version — users should feel snappier calendar.

---

### Phase 2a — Remote CSV system (3–4 weeks, can overlap Phase 1)

**Goal:** Duty CSVs stored in Firebase Storage; add/update files on the fly without app releases.

- [ ] Firebase Storage: upload all current `assets/*.csv` + `manifest.json` (see §9.3–9.4)
- [ ] Implement `CsvContentService` (cache, manifest diff, download changed files only)
- [ ] Refactor `RouteService` and duty picker to use `CsvContentService.loadCsv()` — no direct `rootBundle`
- [ ] Background manifest check on startup (non-blocking)
- [ ] Settings: “Check for duty data updates” + last updated timestamp
- [ ] Invalidate parsed duty index after download
- [ ] Test: remote edit, remote **add new file**, offline cache, assets fallback

**Release:** Minor version — users get duty corrections without updating the app.

**Reference:** Full step-by-step in `CSV_UPDATE_SYSTEM_PLAN.md` + §9 of this document.

---

### Phase 2b — Multi-depot foundation (6–8 weeks)

**Goal:** Architecture ready for depot #2; depot #1 unchanged for users.

- [ ] Firebase Storage structure for depots (§4.2) — migrate CSV path to `depots/{id}/csv_files/`
- [ ] Extend `CsvContentService` → `DepotContentService` (depot-scoped cache + manifest)
- [ ] Refactor remaining CSV consumers (Jamestown, training, buscheck, UNI)
- [ ] Move `location_constants.dart` to per-depot JSON
- [ ] Depot selector in onboarding + settings
- [ ] Namespace user storage keys by `depotId`
- [ ] Implement parsed duty index cache

**Release:** Minor version — default depot pre-selected; optional depot switch for testing.

---

### Phase 3 — Data layer migration (4–6 weeks)

**Goal:** Faster saves, ready for large datasets.

- [ ] Introduce Isar/drift for events
- [ ] Migrate events from SharedPreferences (one-time)
- [ ] Debounced / batched saves
- [ ] Background isolate for CSV parse + statistics
- [ ] Backup format v2 with depot ID

**Release:** Minor version — migration runs silently on upgrade.

---

### Phase 4 — Scale to 10+ depots (ongoing)

**Goal:** Operational rollout.

- [ ] Admin upload workflow per depot (Firebase Console or simple admin UI)
- [ ] **Remote-only CSVs for new depots** — no bundled CSVs in APK (Stage C/D, §9.2)
- [ ] Per-depot feature flags
- [ ] Firestore content scoped by depot
- [ ] Rollout playbook (§11.2)
- [ ] Onboard depots 2–10 using manifest + content upload checklist
- [ ] Monitor analytics per depot

**Release:** Per depot — content/config releases independent of app version.

---

### Phase 5 — Polish & modern UX (parallel / ongoing)

- [ ] `go_router` migration
- [ ] Design system / `ResponsiveSizes` helper
- [ ] Skeleton loaders
- [ ] Remove `RebuildText` workaround
- [ ] Web PWA improvements if needed for depot rollout

---

### Roadmap diagram

```
2026 Q3          Q4              2027 Q1         Q2+
─────────────────────────────────────────────────────────
Phase 0 ████
Phase 1     ████████████
Phase 2a        ████████          ← Remote CSVs (Firebase Storage)
Phase 2b            ████████████████
Phase 3                                 ████████████
Phase 4                                         ═══════════►
Phase 5     ···············································►
            (continuous polish alongside other phases)

Note: Phase 2a can overlap Phase 1 — remote CSV work is largely independent.
```

---

## 14. Metrics & Benchmarks

### Performance targets

| Metric | Current (TBD) | Phase 1 target | Phase 3 target |
|--------|---------------|----------------|----------------|
| Cold start → interactive | Measure in Phase 0 | < 1.5s | < 1.0s |
| Month change frame drops | Measure in Phase 0 | ≤ 1 | 0 |
| Event save ( perceived ) | Measure in Phase 0 | < 300ms | < 150ms |
| Depot content download | N/A | < 30s on 4G | < 15s (indexed) |
| APK size | Measure in Phase 0 | No increase | Stable despite 10+ depots |

### Multi-depot rollout metrics

- Active users per depot
- Depot content cache hit rate
- Content update adoption (manifest version lag)
- **CSV update adoption** — % of users on latest manifest within 7 days of upload
- **Remote CSV cache age** — median days since last successful download
- Crash-free sessions per depot
- Support feedback / bug reports per depot launch

---

## 15. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Calendar refactor introduces regressions | High | High | Split incrementally; tests; feature flags |
| 10 depots × CSVs = admin burden | High | Medium | Upload checklist; version.json; depot templates |
| SharedPreferences migration data loss | Medium | Critical | Backup before migrate; validate; rollback path |
| Firebase costs at scale | Low | Medium | Storage for static files; cache aggressively |
| Depot-specific logic still hardcoded | Medium | High | `DepotConfig` drives UI; no `if (depot == x)` in widgets |
| Scope creep (“modernise everything”) | High | Medium | This document + one phase per release |
| Single maintainer bottleneck | Medium | High | Tests, docs, split files — enable future contributors |

---

## 16. Decision Log

Record major decisions here as they are made.

| Date | Decision | Rationale | Alternatives considered |
|------|----------|-----------|-------------------------|
| 2026-07 | Remote CSVs as explicit pillar | Add/update duty files without app releases; required for 10+ depots | Keep all CSVs in APK |
| 2026-07 | Create this plan | 10+ depot goal requires structured approach | Ad-hoc fixes |
| TBD | `manifest.json` with per-file hashes | Supports adding new CSV files on the fly | Single timestamp-only version.json |
| TBD | Riverpod vs Provider | — | Provider already in pubspec |
| TBD | Isar vs drift | — | Stay on SharedPreferences |
| TBD | Hybrid vs remote-only depot bundle | — | Bundle all depots |
| TBD | Firebase Storage vs Firestore for depot config | — | Keep everything in APK |

---

## Appendix A — Per-depot onboarding checklist

When adding a new depot:

- [ ] Create `depots/{id}/config.json` (zones, rosters, features)
- [ ] Upload all duty CSVs (M-F, SAT, SUN × zones) to `depots/{id}/csv_files/`
- [ ] Create `depots/{id}/csv_files/manifest.json` with all file hashes
- [ ] Upload route CSVs if applicable
- [ ] Upload roster JSON files
- [ ] Create `location_mappings.json`
- [ ] Upload payscale data if depot-specific
- [ ] Set bank holiday region
- [ ] Configure toilet codes / contacts (Firestore or config)
- [ ] Set `active: true` in manifest
- [ ] Test: fresh install, depot select, add duty, offline, **remote CSV update + add new file**
- [ ] Monitor analytics for 1 week post-launch

---

## Appendix B — Files to refactor first (priority order)

1. `lib/features/calendar/screens/calendar_screen.dart`
2. **`lib/services/csv_content_service.dart`** (NEW — remote CSV cache + manifest)
3. `lib/features/calendar/services/route_service.dart` (use CsvContentService, not rootBundle)
4. `lib/features/calendar/services/event_service.dart` (DB migration)
5. `lib/core/services/storage_service.dart` (scope + debounce)
6. `lib/core/constants/location_constants.dart` ( → remote JSON)
7. `lib/main.dart` (deferred init + non-blocking CSV update check)
8. `lib/features/calendar/widgets/event_card.dart` (split + setState)
9. `lib/services/jamestown_feature_service.dart` (remote CSV paths)

---

## Appendix C — Related documents

| Document | Purpose |
|----------|---------|
| `TESTING_PLAN.md` | **Primary testing spec** — P0–P3 priorities, first 10 tests, CI, manual matrix |
| `CSV_UPDATE_SYSTEM_PLAN.md` | **Primary spec** for Phase 2a remote CSV implementation |
| `RESPONSIVE_ISSUES_REPORT.md` | UI overflow fixes |
| `ROSTER_FEATURE_INVESTIGATION.md` | Zone 1 M-F roster implementation notes |
| `ZONE1_SHIFT_ROSTER_INVESTIGATION.md` | Zone 1 Shift roster notes |
| `.cursor/rules/responsive_design.mdc` | Responsive standards |
| `.cursor/rules/versionmanagement.mdc` | Version bump checklist |

---

*This plan is intentionally ambitious. Ship value every phase — users should feel improvement even while multi-depot infrastructure is being built.*
