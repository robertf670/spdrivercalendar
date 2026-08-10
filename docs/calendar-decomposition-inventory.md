# Calendar Decomposition Inventory

> **Source:** `lib/features/calendar/screens/calendar_screen.dart`  
> **Current size:** approximately 2,260 lines (composition/orchestration shell)  
> **Phase:** Phase 1 complete — domain rules extracted; screen owns wiring  
> **State-management decision:** Provider with incremental `ChangeNotifier` adoption

## Objective

Reduce `calendar_screen.dart` to a small composition shell without changing calendar data, duty calculations, Jamestown or Donnybrook behaviour, navigation, or visible user behaviour.

This is an incremental extraction. Each step must compile, pass tests, and remain independently reviewable.

## Current responsibilities

Line ranges are approximate and should be refreshed immediately before each extraction.

| Area | Approximate source range | Current responsibility | Intended destination |
|---|---:|---|---|
| Live-update banner | 69–88 and 11926+ | Stable/static banner widgets | `widgets/live_updates_banner.dart` |
| Screen state and initialization | 90–690 | Controllers, settings, current month, lifecycle and service startup | Screen shell initially; then `controllers/calendar_controller.dart` |
| Roster and selected-day logic | 691–795 | Shift selection, rest-day checks, holiday event synthesis | Tested calendar-domain helpers, then controller |
| Add-event and duty flows | 796–3110 | Event dialogs, work shifts, WFO, swaps, CSV duty-time lookup | `flows/add_duty/` and a single duty-time resolver service |
| Google Calendar integration | 3113–3388 | Description building and synchronization | Existing Google service boundary plus a calendar sync coordinator |
| Event editing and status dialogs | 3389–6316 | Edit flow, notes, breaks, overtime, late finish, sickness | Small dialogs/controllers grouped by concern |
| Scaffold and navigation | 6317–6487 and 7357–7413 | Main layout and feature navigation | Final `calendar_screen.dart` shell |
| Month grid and day cells | 6489–7289 | TableCalendar, day styling, selection animation | `widgets/calendar_grid.dart` and `widgets/calendar_day_cell.dart` |
| Selected-day event list | 7290–7356 | Event list for selected date | `widgets/day_detail_section.dart` |
| Holiday display and editing | 7414–10951 | Balances, lists, multi-date selection, holiday dialogs | `holiday/holiday_section.dart` plus focused dialogs |
| Feature navigation | 10952–11140 | Contacts, notes, Bills, Payscale, search, week/year views | Screen shell or route coordinator |
| Overtime flow | 11141–11759 | Half selection and overtime details | `flows/overtime/` |
| Inline private widgets | 11780 onward | Duty notes and selected-cell animation | Dedicated widget/dialog files |

## Existing extraction points

Reuse these boundaries instead of recreating parallel implementations:

- `lib/features/calendar/services/event_service.dart`
- `lib/features/calendar/services/roster_service.dart`
- `lib/features/calendar/services/roster_schedule_service.dart`
- `lib/features/calendar/services/shift_service.dart`
- `lib/features/calendar/services/holiday_service.dart`
- `lib/features/calendar/services/route_service.dart`
- `lib/features/calendar/widgets/shift_details_card.dart`
- `lib/features/calendar/widgets/custom_training_form.dart`
- `lib/features/calendar/dialogs/add_event_dialog.dart`
- `lib/features/calendar/dialogs/days_in_lieu_setup_dialog.dart`
- `lib/features/calendar/dialogs/annual_leave_setup_dialog.dart`
- `lib/features/calendar/screens/week_view_screen.dart`
- `lib/features/calendar/screens/year_view_screen.dart`

Before extracting the month grid, decide whether the currently unused `lib/features/calendar/widgets/calendar_widget.dart` can become the real grid boundary or should be removed. Do not maintain two grid implementations.

`lib/features/calendar/widgets/event_card.dart` is itself very large. Treat its decomposition as separate work so it does not block reducing the screen shell.

## Behavioural invariants

Every Phase 1 change must preserve:

### Calendar and persistence

- Existing events load for the same dates.
- Adding, editing, deleting, and reloading an event produces the same stored data.
- Selected-day and focused-month behaviour remains unchanged.
- Month caching and visible event ordering remain unchanged.
- Holiday-generated entries do not duplicate stored events.

### Rosters and operational features

- Five-week roster calculations and dated roster changes return identical shifts.
- Marked-in M-F and shift behaviour remains unchanged.
- Rest-day swaps continue to override the displayed roster correctly.
- Bank holidays and Saturday-service dates select the same duty files.
- Zone 4 route 23/24 changeover behaviour remains unchanged.
- Jamestown and Donnybrook feature selection, duty lists, and mutual exclusion remain unchanged.
- Depot concepts are not introduced during Phase 1.

### Integrations

- Google Calendar synchronization remains opt-in and produces equivalent event details.
- Backup and restore formats do not change.
- User activity, update checks, and colour customization callbacks continue to run.
- Android and web remain supported.

### UI and responsiveness

- No full-screen flash is introduced on day selection.
- Existing dark/light themes and custom shift colours remain unchanged.
- The calendar works at 320px without horizontal overflow.
- Navigation destinations and back behaviour remain unchanged.

## Incremental extraction order

### Step 1 — Lifecycle safety correction

Add and verify `dispose()` on `CalendarScreenState` for owned animation/scroll controllers, the lifecycle observer, and registered callbacks. This is a focused correction before moving ownership.

### Step 2 — Move self-contained private widgets

Move the live-update banners, selected-day animation wrapper, and duty-notes dialog to dedicated files. Pass data and callbacks explicitly; do not give these widgets service access.

Acceptance:

- No state fields move.
- No persistence or duty logic changes.
- Existing rendering and callbacks remain identical.

### Step 3 — Establish one duty-time lookup boundary

The screen’s CSV time resolution overlaps `RouteService`. Consolidate file selection and duty lookup behind one tested service before moving the add-duty flow.

Acceptance:

- Golden duty lookups cover representative PZ, route 23/24, Jamestown, Donnybrook, UNI, training, and bus-check cases.
- Missing or malformed rows retain current graceful behaviour.
- No remote CSV work is introduced yet.

### Step 4 — Extract calendar day presentation

Create a stateless `CalendarDayCell` that receives display text, colours, badges, selection state, and tap behaviour as inputs.

Acceptance:

- Add widget tests for selected, today, outside-month, rest-day, and event/badge states.
- The widget contains no storage or service calls.

### Step 5 — Extract the month grid

Create `CalendarGrid` around `TableCalendar`. Keep focused-day and selected-day ownership in the screen for this step; communicate only through typed callbacks.

Acceptance:

- Month navigation and day selection match baseline behaviour.
- Rebuild boundaries are visible in profile measurements.
- No business rules are copied into the grid.

### Step 6 — Introduce `CalendarController` with Provider

Add a `ChangeNotifier` for a narrow first state slice:

- selected day
- focused month
- visible-month loading state

Provide it at the calendar feature boundary and use `Consumer`, `Selector`, or `ListenableBuilder` only around widgets that need each state value.

Acceptance:

- Controller unit tests cover selection, month changes, and loading transitions.
- Do not migrate settings, holidays, duty editing, and integrations in the same change.
- Remove replaced `setState` calls rather than leaving two owners for the same state.

### Step 7 — Extract selected-day details

Move the event list and shift summary into `DayDetailSection`, driven by controller state and explicit actions.

### Step 8 — Split feature flows

Move add-duty, event editing/status, overtime, and holiday flows one concern at a time. Add tests around pure logic before moving it.

### Step 9 — Reduce the screen to composition

The final screen should own the scaffold, Provider wiring, navigation coordination, and composition of extracted sections. It should not parse CSV files or implement roster, event, holiday, or synchronization rules.

**Status:** Complete for Phase 1. Remaining screen code is mostly dialog/navigation wiring and lifecycle glue. Domain rules for duty times, holidays, status updates, Google sync, day appearance, roster lookup, and workout highlights are extracted and tested.

## Verification for every extraction

Automated:

```powershell
flutter analyze
flutter test
```

User-run smoke checks:

1. Launch on Android and deployed web.
2. Navigate six months forward and back.
3. Select empty and populated days.
4. Add, edit, delete, and reload a representative duty.
5. Check marked-in/rest-day and swap behaviour.
6. Check Jamestown and Donnybrook duty selection.
7. Check holidays, week view, year view, settings, and back navigation.
8. Repeat the relevant performance-baseline capture after material state changes.

## Phase 1 first change

The first Phase 1 implementation should contain only:

1. Lifecycle cleanup.
2. Extraction of the small private live-update banner widgets.
3. Tests or smoke-check notes proving no behavioural change.

Do not combine the first change with Provider adoption, calendar-grid extraction, or duty-flow changes.
