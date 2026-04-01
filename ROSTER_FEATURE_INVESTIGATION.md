# Zone 1 M-F 12-Week Roster Feature – Investigation Summary

## Overview

Add support for Zone 1 M-F marked-in drivers to fill in their 12-week duty roster. When a user enters their duty for an upcoming Monday (e.g. PZ1/56), the system should determine their week in the cycle and auto-populate the next 12 weeks accordingly.

## Roster Data (Implemented)

- **File:** `assets/zone1_mf_12week_roster.json`
- **Content:** 12-week cycle mapping week number → duty code
- **Cycle:** WK1 (PZ1/40) → WK2 (PZ1/43) → … → WK12 (PZ1/71) → repeats
- **Sat/Sun:** Always Rest (R) for M-F drivers

## Current Architecture

### 1. Marked-in Settings
- **Location:** `lib/features/settings/screens/settings_screen.dart`
- **Keys:** `markedInEnabled`, `markedInStatus` (Spare | Shift | M-F), `markedInZone` (Zone 1–4)
- **M-F users:** `markedInStatus == 'M-F'`, `markedInZone == 'Zone 1'` for this feature

### 2. RosterService
- **Location:** `lib/features/calendar/services/roster_service.dart`
- **Current use:** 5-week **Shift** roster (E/L/R/M patterns), not M-F duty codes
- **M-F today:** Treated as Mon–Fri work, Sat–Sun rest; no duty-code roster
- **Note:** Zone 1 M-F 12-week roster is separate from the existing 5-week E/L/R/M roster

### 3. Event/Duty Storage
- **Event model:** `lib/models/event.dart` – `title`, `assignedDuties`, `enhancedAssignedDuties`
- **Duty codes:** Stored as strings (e.g. `PZ1/56`)
- **Events:** One per day; M-F users typically have one duty per Mon–Fri

### 4. How Duties Are Added Today
- **Calendar:** `lib/features/calendar/screens/calendar_screen.dart` – tap day → duty picker
- **Flow:** Pick zone → load CSV (e.g. `M-F_DUTIES_PZ1.csv`) → choose duty → create `Event`
- **No roster logic:** No mapping of “this Monday = Week 6, next week = Week 7” etc.

## What Needs to Be Built

### Phase 1: Data & Lookup (foundation)
- [x] Roster data file (`zone1_mf_12week_roster.json`) – **DONE**
- [ ] Service to load roster and expose helpers:
  - `getWeekIndexForDuty(String dutyCode)` → week index 0–11 (or null)
  - `getDutyForWeekIndex(int index)` → duty code
  - `getDutiesForNext12Weeks(int startWeekIndex)` → list of 12 duty codes

### Phase 2: User Flow (Zone 1 M-F only)
- [ ] Entry point: “Fill 12 weeks from this Monday” for M-F + Zone 1
- [ ] User enters duty for starting Monday (e.g. PZ1/56)
- [ ] System: look up week index (6 for PZ1/56) → compute next 12 weeks
- [ ] Confirm: show preview of 12 weeks before creating events
- [ ] Create events for Mon–Fri only, Sat–Sun remain Rest

### Phase 3: UI & Integration
- [ ] Decide where to place the flow:
  - Option A: New Settings section “Zone 1 M-F Roster”
  - Option B: Calendar action (e.g. long-press on Monday or FAB)
  - Option C: Dedicated “Roster” screen accessible from Settings or home
- [ ] Form: pick starting Monday, enter duty code (or dropdown from roster duties)
- [ ] Validation: only allow duty codes that appear in the roster
- [ ] Show all 12 weeks for confirmation; allow editing before save

### Phase 4: Edge Cases
- [ ] Bank holidays: M-F users rest on bank holidays – do not create work events
- [ ] Overlapping events: if events already exist, offer replace/merge/skip
- [ ] “12 weeks at a time”: UI that supports filling one 12-week block, then later filling the next block
- [ ] Cycle alignment: user may not know which week they’re in; first duty entry defines it

## Key Files to Modify

| File | Purpose |
|------|---------|
| `lib/features/calendar/services/roster_service.dart` | Add Zone 1 M-F 12-week roster loading and lookup |
| `lib/features/calendar/services/event_service.dart` | Create multiple events for 12 weeks |
| `lib/features/settings/screens/settings_screen.dart` or new screen | Roster fill UI for Zone 1 M-F |
| `lib/core/constants/app_constants.dart` | Storage keys for roster start date, last filled week, etc. (if needed) |

## Override & Removability

Roster-populated events behave like any other events. Users can:

- **Delete** a duty (e.g. after swapping with someone)
- **Edit** and change the duty code
- **Manually add** a different duty for that day

The roster only bulk-creates events; those events are not locked. Existing edit/delete/add flows work normally.

## Constraints (from requirements)

- **Scope:** Zone 1 M-F only (not Shift, not other zones)
- **Window:** 12 weeks at a time
- **Days:** Mon–Fri work, Sat–Sun Rest
- **Entry point:** User provides duty for the Monday of the starting week

## Data Model Suggestion

For persistence (optional, if we store user’s cycle phase):
```dart
// Example: which week in the 12-week cycle the user’s roster starts
// Stored when user first fills in: "Starting Monday 2025-03-24 = Week 6 (PZ1/56)"
'zone1MfRosterStartDate': '2025-03-24',  // ISO date of first Monday
'zone1MfRosterStartWeekIndex': 6         // 0–11, derived from duty
```

## Next Steps

1. Implement roster load + lookup in `RosterService` (or a new `Zone1MfRosterService`).
2. Add a minimal UI to test: enter duty → show 12-week preview.
3. Wire up event creation for Mon–Fri over 12 weeks, respecting bank holidays.
4. Decide final UX location and add entry point from Settings or Calendar.
