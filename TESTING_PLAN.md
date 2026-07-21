# Spare Driver Calendar — Testing Plan

> **Purpose:** A practical testing strategy that supports refactoring and multi-depot rollout — not a blanket “100% coverage” goal.
>
> **Companion doc:** `MODERNISATION_PLAN.md` (phases define *when* to add tests)  
> **Current version:** 3.2.8  
> **Last updated:** July 2026  
> **Status:** Living document

---

## Table of Contents

1. [Current State](#1-current-state)
2. [Testing Philosophy](#2-testing-philosophy)
3. [Test Pyramid for This App](#3-test-pyramid-for-this-app)
4. [Folder Structure](#4-folder-structure)
5. [Priority Tiers (P0–P3)](#5-priority-tiers-p0p3)
6. [Module Test Specifications](#6-module-test-specifications)
7. [First 10 Tests to Write](#7-first-10-tests-to-write)
8. [Phased Rollout (Aligned to Modernisation)](#8-phased-rollout-aligned-to-modernisation)
9. [Mocking & Test Utilities](#9-mocking--test-utilities)
10. [Running Tests Locally](#10-running-tests-locally)
11. [CI Pipeline (Recommended)](#11-ci-pipeline-recommended)
12. [Manual Test Matrix](#12-manual-test-matrix)
13. [What Not to Test](#13-what-not-to-test)
14. [Coverage Targets](#14-coverage-targets)
15. [Progress Tracker](#15-progress-tracker)

---

## 1. Current State

| Metric | Value |
|--------|------:|
| Production Dart (`lib/`) | ~59,671 lines |
| Test Dart (`test/`) | 71 lines |
| Test files | 1 |
| Test-to-code ratio | ~0.1% |

**Existing tests:** `test/unit/services/storage_service_test.dart`  
- 5 tests covering `StorageService` get/save/clear for strings and bools  
- Uses `SharedPreferences.setMockInitialValues({})` — good pattern to reuse

**Gap:** Almost all business logic (rosters, events, statistics, CSV resolution) is untested. Refactors to `calendar_screen.dart`, remote CSVs, and multi-depot are high-risk without a growing test suite.

---

## 2. Testing Philosophy

### Core principle

> **Add tests when you touch or extract code — not as a separate project.**

Tests exist to:

1. **Lock in roster/date math** before calendar decomposition  
2. **Protect event serialisation** before DB migration  
3. **Verify remote CSV cache logic** before Firebase rollout  
4. **Enable safe refactoring** of 60k lines with minimal manual QA  

Tests do **not** exist to:

- Hit an arbitrary coverage percentage  
- Test Flutter framework behaviour  
- Duplicate manual QA for every screen pixel  

### Rules of thumb

| Rule | Rationale |
|------|-----------|
| Test **pure functions** first | Fast, stable, no mocks |
| Test **new extracted classes** in the same PR as extraction | Prevents re-growth of god files |
| Don’t widget-test code you’re about to delete | Waste of effort |
| One failing test = stop and fix before merging | Tests only help if trusted |
| Prefer table-driven tests for date/roster cases | Many edge cases, one test function |

---

## 3. Test Pyramid for This App

```
                    ┌─────────────┐
                    │ Integration │  3–5 flows (later)
                   ┌┴─────────────┴┐
                   │ Widget tests  │  Small extracted widgets (Phase 1+)
                  ┌┴───────────────┴┐
                  │  Unit tests     │  ← START HERE (P0/P1)
                  └─────────────────┘
```

| Layer | Target count (12-month) | Speed | When |
|-------|------------------------:|-------|------|
| Unit | 80–150 tests | < 30s total | Phase 0 onward |
| Widget | 15–30 tests | < 60s total | After calendar split |
| Integration | 3–8 tests | Minutes | After DB + remote CSV stable |

---

## 4. Folder Structure

Organise tests to mirror `lib/`:

```
test/
├── unit/
│   ├── models/
│   │   ├── event_test.dart
│   │   └── assigned_duty_test.dart
│   ├── services/
│   │   ├── storage_service_test.dart      ✅ exists
│   │   ├── roster_service_test.dart
│   │   ├── csv_content_service_test.dart  (Phase 2a)
│   │   └── update_service_test.dart
│   ├── features/
│   │   └── calendar/
│   │       └── calendar_controller_test.dart  (Phase 1)
│   └── constants/
│       └── training_constants_test.dart
├── widget/
│   └── calendar/
│       └── day_cell_test.dart             (Phase 1)
├── integration/
│   └── add_duty_persists_test.dart        (Phase 3)
└── helpers/
    ├── test_fixtures.dart                 # Sample events, dates, manifests
    └── mock_csv_loader.dart               # Phase 2a
```

**Naming:** `{source_file}_test.dart` matching the file under test.

---

## 5. Priority Tiers (P0–P3)

| Tier | When | Focus |
|------|------|-------|
| **P0** | Now (Phase 0) | Pure logic — roster dates, event serialisation, small constants |
| **P1** | Phase 1–2 | Services — storage, CSV cache, update checks, statistics helpers |
| **P2** | Phase 1–2 | Widget tests on **new** small widgets only |
| **P3** | Phase 3+ | Integration flows, migration tests, depot namespacing |

---

## 6. Module Test Specifications

### 6.1 `RosterService` — **P0, highest priority**

**File:** `lib/features/calendar/services/roster_service.dart`  
**Test file:** `test/unit/services/roster_service_test.dart`

| Test case | Input | Expected |
|-----------|-------|----------|
| `getShiftPattern` wraps week index | `weekNumber: 7` | Same as week 2 (`7 % 5 == 2`) |
| `getShiftForDate` on start date | `date == startDate`, `startWeek: 0` | Correct day letter from week 0 pattern |
| `getShiftForDate` one week later | +7 days | Next week in 5-week cycle |
| `getShiftForDate` before start date | Date in past | Correct backward week calculation |
| `getShiftForDate` across year boundary | Dec 31 → Jan 1 | No off-by-one |
| `getRestDaysForWeek` valid index | `0` | Rest days string for week 0 |
| `getRestDaysForWeek` invalid index | `-1` or `99` | `'Invalid'` |
| `isSaturdayService` Dec 24 (weekday) | Non-Sunday Dec 24 | `true` |
| `isSaturdayService` Dec 24 on Sunday | Sunday Dec 24 | `false` |
| `getDayOfWeek` Saturday service date | Dec 27 (weekday) | `'Saturday'` |
| `getShiftFilename` Zone 4 changeover | Date before/after Oct 19 2025 | Correct M-F vs route file (if tested) |

Use **fixed UTC dates** in tests to avoid timezone flakiness:

```dart
final startDate = DateTime.utc(2025, 1, 6); // Example Monday
final targetDate = DateTime.utc(2025, 1, 13); // Following Monday
```

---

### 6.2 `Event` / `AssignedDuty` — **P0**

**File:** `lib/models/event.dart`  
**Test file:** `test/unit/models/event_test.dart`

| Test case | Notes |
|-----------|-------|
| `toMap` → `fromMap` round-trip | Minimal event (id, title, dates, times) |
| Round-trip with `enhancedAssignedDuties` | Multiple duties with bus assignments |
| Round-trip with nullable fields null | `breakStartTime`, `routes`, `notes` all null |
| Round-trip with holiday fields | `isHoliday`, `holidayType` |
| Round-trip with bus breakdown fields | `additionalBusesUsed`, `additionalBusesByDuty` |
| `AssignedDuty.fromLegacyString` | Migration path from old string duties |
| `Event.fromList` legacy CSV row | If still supported — one golden row |

**Why critical:** Phase 3 DB migration and backup v2 depend on stable serialisation.

---

### 6.3 `TrainingConstants` — **P0 (easy win)**

**File:** `lib/core/constants/training_constants.dart`  
**Test file:** `test/unit/constants/training_constants_test.dart`

| Test case | Expected |
|-----------|----------|
| `resolveLocation(null, '')` | `null` |
| `resolveLocation('Garage', '')` | `'Garage'` |
| `resolveLocation('Other', '  Custom  ')` | `'Custom'` |
| `resolveLocation('Other', '')` | `null` |

---

### 6.4 `StorageService` — **P1 (extend existing)**

**File:** `test/unit/services/storage_service_test.dart` ✅

**Add when touching storage:**

| Test case | Notes |
|-----------|-------|
| Cache hit avoids second prefs read | If testable without flakiness |
| `saveString` validation failure path | Document expected throw |
| Depot-namespaced keys (Phase 2b) | `events_birmingham` vs `events_manchester` |
| Migration helper (Phase 3) | SP JSON → DB one-time import |

---

### 6.5 `UpdateService` / version compare — **P1**

**File:** `lib/services/update_service.dart`  
**Test file:** `test/unit/services/update_service_test.dart`

| Test case | Expected |
|-----------|----------|
| `3.2.8` vs `3.2.9` | Newer |
| `3.2.8` vs `3.2.8` | Not newer |
| `3.2.8` vs `3.3.0` | Newer |
| `3.2.8` vs `4.0.0` | Newer |
| Malformed version string | Graceful false / no throw |

Test `_isNewerVersion` via package-visible test hook or extract to pure `VersionUtils` if private.

---

### 6.6 `CsvContentService` — **P1 (Phase 2a)**

**File:** `lib/services/csv_content_service.dart` (to be created)  
**Test file:** `test/unit/services/csv_content_service_test.dart`

| Test case | Notes |
|-----------|-------|
| Manifest diff — no changes | Empty download list |
| Manifest diff — one hash changed | Single file in download list |
| Manifest diff — new file in remote | New file flagged for download |
| `loadCsv` — cache hit | Returns cached content |
| `loadCsv` — cache miss, asset fallback | Returns bundled asset (mock rootBundle) |
| `loadCsv` — both miss | Throws or returns error type |
| `invalidateIndex` after update | Parsed cache cleared |

Use temp directory for cache in tests (`path_provider` mock or direct `Directory.systemTemp`).

---

### 6.7 `RouteService` / duty index — **P1 (Phase 2a+)**

**File:** `lib/features/calendar/services/route_service.dart`  
**Test file:** `test/unit/services/route_service_test.dart`

| Test case | Notes |
|-----------|-------|
| Known shift code → route info | Golden row from sample CSV fixture |
| Unknown shift code | Returns null |
| Zone 4 date changeover filename | Correct CSV selected |
| Cache used on second lookup | Same file not re-parsed |

Provide minimal CSV fixture in `test/fixtures/M-F_DUTIES_PZ1_sample.csv` (3–5 rows).

---

### 6.8 Statistics helpers — **P1**

**File:** `lib/features/statistics/` (extract pure calc functions if embedded in screen)  
**Test file:** `test/unit/features/statistics/statistics_calculator_test.dart`

**Prerequisite:** Extract calculation logic from `statistics_screen.dart` into testable pure functions (same Phase 1 effort as calendar split).

| Test case | Notes |
|-----------|-------|
| Shift type counts for known month | Golden fixture of events |
| Work time totals | Includes/excludes rest days correctly |
| Break statistics edge cases | Late break, full break flags |

---

### 6.9 `CalendarController` — **P1 (Phase 1)**

**File:** `lib/features/calendar/controllers/calendar_controller.dart` (to be created)  
**Test file:** `test/unit/features/calendar/calendar_controller_test.dart`

| Test case | Notes |
|-----------|-------|
| Select day updates focused day | State change |
| Month navigation updates visible range | |
| Load month fetches events for range | Mock EventService |
| Marked-in settings affect displayed pattern | Mock preferences |

Use `ChangeNotifier` listener or Riverpod container in tests.

---

### 6.10 Depot config & namespacing — **P1 (Phase 2b)**

**File:** `lib/features/depot/` (to be created)  
**Test file:** `test/unit/features/depot/depot_config_test.dart`

| Test case | Notes |
|-----------|-------|
| Parse `config.json` fixture | Valid depot config |
| Invalid / missing fields | Graceful error |
| Storage key helper | `eventsKey('birmingham')` → `'events_birmingham'` |
| Switching depot does not read other depot keys | Isolation |

---

### 6.11 Widget tests — **P2 (Phase 1+)**

Only test **extracted** widgets — never the monolithic `calendar_screen.dart`.

| Widget | Test file | Cases |
|--------|-----------|-------|
| Day cell (extracted) | `day_cell_test.dart` | Renders shift letter; selected state |
| Training location dropdown | `custom_training_form_test.dart` | Preset + Other |
| Depot selector (Phase 2b) | `depot_selector_test.dart` | List renders; selection callback |

Use `testWidgets` + `pumpWidget` with `MaterialApp` wrapper.

---

### 6.12 Integration tests — **P3 (Phase 3+)**

**File:** `integration_test/` or `test/integration/`

| Flow | Steps |
|------|-------|
| Add duty persists | Tap day → pick duty → save → restart app → event visible |
| Remote CSV update | Mock manifest bump → check updates → duty list changes |
| Backup restore | Export → clear → import → data matches |
| DB migration | Upgrade from SP-only backup format → events intact |

Integration tests are slow — keep the count small.

---

## 7. First 10 Tests to Write

Start here in **Phase 0** — all unit tests, no new dependencies:

| # | Test | File to create |
|---|------|----------------|
| 1 | `getShiftPattern` wraps at 5 weeks | `roster_service_test.dart` |
| 2 | `getShiftForDate` on start date | `roster_service_test.dart` |
| 3 | `getShiftForDate` 7 days later (next week) | `roster_service_test.dart` |
| 4 | `getShiftForDate` before start date | `roster_service_test.dart` |
| 5 | `isSaturdayService` Dec 24 weekday vs Sunday | `roster_service_test.dart` |
| 6 | Event minimal round-trip `toMap`/`fromMap` | `event_test.dart` |
| 7 | Event with `enhancedAssignedDuties` round-trip | `event_test.dart` |
| 8 | `TrainingConstants.resolveLocation` — 4 cases | `training_constants_test.dart` |
| 9 | Version compare: patch bump is newer | `update_service_test.dart` |
| 10 | Version compare: same version is not newer | `update_service_test.dart` |

**Existing #1–5:** StorageService tests already cover items in that file — roster/event tests are the immediate gap.

**Target after Phase 0:** ~15–20 unit tests, all green, `flutter test` < 10 seconds.

---

## 8. Phased Rollout (Aligned to Modernisation)

| Modernisation phase | Testing deliverables |
|---------------------|---------------------|
| **Phase 0** | First 10 tests (§7); `flutter test` in local workflow; optional CI |
| **Phase 1** | Roster tests expanded; `CalendarController` tests; first widget test on extracted day cell |
| **Phase 2a** | `CsvContentService` manifest diff + cache tests; CSV fixture file; RouteService golden tests |
| **Phase 2b** | Depot config parse + storage key namespacing tests |
| **Phase 3** | Event DB migration tests; integration: add duty persists |
| **Phase 4** | Per-depot config fixture tests; integration: depot download |
| **Phase 5** | Regression widget tests for responsive breakpoints (optional) |

**Gate:** Do not merge a refactor PR without tests for extracted logic.

---

## 9. Mocking & Test Utilities

### Already available (`pubspec.yaml`)

- `flutter_test` — test framework  
- `mockito` + `build_runner` — mocks (generate with `@GenerateMocks`)

### Common mocks

| Dependency | Mock strategy |
|------------|---------------|
| `SharedPreferences` | `SharedPreferences.setMockInitialValues({})` ✅ |
| `rootBundle` / assets | Extract `AssetLoader` interface; fake in tests |
| Firebase Storage | Fake `CsvContentService` with local files — don’t hit Firebase in unit tests |
| Firestore | Not unit tested — mock at repository boundary |
| `http` / Dio | `mockito` or manual `MockClient` |
| File system cache | Temp directory per test in `setUp` / tear down in `tearDown` |

### Shared fixtures (`test/helpers/test_fixtures.dart`)

```dart
// Conceptual contents:
// - sampleEvent()
// - sampleEventWithDuties()
// - sampleStartDate / sampleDates list
// - sampleManifestJson()
// - sampleDepotConfig()
```

Create this file when test #6 is written — avoids copy-paste across tests.

---

## 10. Running Tests Locally

```powershell
# All tests
flutter test

# Single file
flutter test test/unit/services/roster_service_test.dart

# Verbose (debug failing test)
flutter test --reporter expanded

# With coverage (optional)
flutter test --coverage
# Report: coverage/lcov.info (use genhtml or VS Code coverage gutter)
```

**When to run:**

- Before every commit that touches `lib/`  
- After calendar or storage refactors  
- Before tagging a release  

---

## 11. CI Pipeline (Recommended)

Add when you have **≥ 15 unit tests** (Phase 0 complete):

```yaml
# .github/workflows/test.yml (conceptual)
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.x'  # Match pubspec constraint
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

Optional later: `flutter build apk --profile` on `main` only.

---

## 12. Manual Test Matrix

Automated tests won’t cover everything. Run this checklist **before each release**:

### Core calendar

- [ ] Cold start → calendar loads
- [ ] Month forward / back — no jank
- [ ] Tap day — detail panel updates
- [ ] Add duty (Zone 1, 3, UNI) — saves and displays
- [ ] Edit / delete duty
- [ ] Marked-in M-F auto-fill (if enabled)
- [ ] Bank holiday display
- [ ] Overnight duty display preference

### Data & sync

- [ ] Backup create + restore
- [ ] Google Calendar sync (if changed)
- [ ] Remote CSV check + update (Phase 2a+)
- [ ] Offline mode — cached duties work

### Devices

- [ ] Small phone (320px width) — no overflow
- [ ] Standard phone
- [ ] Dark mode

### Platform

- [ ] Android (primary)
- [ ] Web (if shipping web)
- [ ] iOS (if applicable)

---

## 13. What Not to Test

| Skip | Why |
|------|-----|
| `changelog_data.dart` | Static content, not logic |
| `calendar_screen.dart` as-is | Being split — test extracted pieces |
| Firebase SDK internals | Mock at service boundary |
| Google Sign-In OAuth flow | Manual / integration only |
| Every CSV row | Sample fixtures + golden shift codes sufficient |
| Pixel-perfect golden files | High maintenance, low value |
| Third-party packages | Trust `table_calendar`, etc. |

---

## 14. Coverage Targets

Realistic goals — not mandates:

| Milestone | Unit test count | Approx. lib coverage |
|-----------|----------------:|---------------------|
| Phase 0 complete | 15–20 | ~5% (logic-heavy files) |
| Phase 1 complete | 40–60 | ~10–15% |
| Phase 2a complete | 60–80 | ~15–20% |
| Phase 3 complete | 80–120 | ~20–25% |

**Focus coverage on:**

- `roster_service.dart`
- `event.dart`
- `csv_content_service.dart` (new)
- `calendar_controller.dart` (new)
- Statistics pure functions (extracted)

**Do not chase 80% overall** — much of the 60k lines is UI that will be rewritten.

---

## 15. Progress Tracker

Update this table as tests land:

| Test file | Tests | Status |
|-----------|------:|--------|
| `storage_service_test.dart` | 5 | ✅ Done |
| `roster_service_test.dart` | 0 | ⬜ Phase 0 |
| `event_test.dart` | 0 | ⬜ Phase 0 |
| `training_constants_test.dart` | 0 | ⬜ Phase 0 |
| `update_service_test.dart` | 0 | ⬜ Phase 0 |
| `calendar_controller_test.dart` | 0 | ⬜ Phase 1 |
| `csv_content_service_test.dart` | 0 | ⬜ Phase 2a |
| `route_service_test.dart` | 0 | ⬜ Phase 2a |
| `depot_config_test.dart` | 0 | ⬜ Phase 2b |
| `day_cell_test.dart` (widget) | 0 | ⬜ Phase 1 |
| Integration: add duty | 0 | ⬜ Phase 3 |

**CI enabled:** ⬜ No  
**Last full manual matrix run:** —  

---

## Related Documents

| Document | Relationship |
|----------|--------------|
| `MODERNISATION_PLAN.md` §12 | High-level testing summary — this doc is the full spec |
| `CSV_UPDATE_SYSTEM_PLAN.md` | CSV service tests in §6.6 |
| `RESPONSIVE_ISSUES_REPORT.md` | Manual small-screen checks in §12 |

---

*Tests are a tool, not a trophy. Add them where refactors hurt without them.*
