# Spare Driver Shift Calendar - Current Features Plan

This document outlines the features currently implemented in the Spare Driver Shift Calendar application.

## Core Calendar & Display

- [x] **Monthly Calendar View:** Displays a standard monthly calendar using `table_calendar`.
- [x] **Shift Display:**
  - [x] Shows assigned shifts (Early, Late, Middle, Rest) on calendar days based on loaded roster data.
  - [x] Uses distinct colors for different shift types (`E`, `L`, `M`, `R`).
  - [x] Highlights the current day.
- [x] **Bank Holiday Indication:**
  - [x] Highlights bank holidays on the calendar view (red border).
  - [x] Displays a "Bank Holiday" badge on relevant event cards.
- [x] **Holiday Indication:**
  - [x] Highlights user-defined holiday periods on the calendar view (teal background).
  - [x] Displays dedicated holiday cards in the event list.
- [x] **Rest Day Indication:** Displays a "Rest Day" badge on work shifts occurring on a rostered rest day.
- [x] **Event List:** Shows a list of events (shifts, holidays, normal events) for the selected day below the calendar.
- [x] **Navigation:** Allows users to navigate between months and jump to specific months/years.
- [x] **Theme Support:** Adapts to Light and Dark modes.

## Event Management

- [x] **Add Events:**
  - [x] Add "Normal Events" (non-work related) with title, date, and time.
  - [x] Add "Work Shifts" based on roster patterns (requires selecting start date and week number).
- [x] **Edit Events:** Allows editing details of existing normal events and work shifts (excluding Spare shifts directly).
- [x] **Delete Events:** Allows deleting normal events and Spare shifts (via a specific dialog).
- [x] **Event Persistence:** Saves and loads events using local storage (`shared_preferences`).
- [x] **Event Notes:** Allows adding and viewing text notes associated with events.

## Shift & Duty Details (Event Card)

- [x] **Shift Title Display:** Shows the specific shift code (e.g., `PZ1/101`, `SP2`, `12/345`).
- [x] **Time Display:**
  - [x] **PZ Shifts:** Shows "Report" and "Sign Off" times. Shows "Depart" and "Finish" times.
  - [x] **Non-PZ Shifts:** Shows "Start" and "End" times.
- [x] **Location Display (PZ Shifts):** Shows depart and finish locations based on roster data.
- [x] **Break Time Display:**
  - [x] Shows calculated break duration (e.g., "Break: 45m").
  - [x] Indicates "Workout" if no standard break.
  - [x] Shows break start/end locations for PZ shifts (if not a workout).
- [x] **Work Time Display:** Shows calculated work duration based on roster data (e.g., "Work: 7h 30m").
- [x] **Date Display:** Shows the full date of the event.
- [x] **Assigned Duty Display (Spare Shifts):**
  - [x] Lists assigned duties (full or half).
  - [x] Shows start/end times and locations for each assigned duty.
  - [x] Calculates and displays work duration for each assigned duty.
- [x] **Bus Assignment Display:**
  - [x] Shows assigned bus number(s) for the shift (first half, second half, or single bus for workouts).

## Spare Shift Functionality

- [x] **Add Spare Shifts:** Added via the standard "Work Shift" dialog by selecting a Spare Roster.
- [x] **Assign Duties:**
  - [x] Dialog allows assigning Full, First Half (A), or Second Half (B) duties to a Spare shift event.
  - [x] Loads available duties from relevant CSV files based on date and zone.
  - [x] Excludes "Workout" duties from selection.
  - [x] Maximum of two duties (e.g., one A and one B, or two full) can be assigned.
- [x] **Remove Duties:** Allows removing assigned duties from a Spare shift event via the Spare Shift dialog.
- [x] **View Assigned Duties:** Displays details of assigned duties on the `EventCard`.
- [x] **Delete Spare Shift:** Allows deleting the entire Spare shift event card.

## Holiday Management

- [x] **Add Holidays:**
  - [x] Option to add preset Summer (2 weeks) or Winter (1 week) holidays starting on a selected Sunday.
  - [x] Option to add custom "Other" single-day holidays.
- [x] **View Holidays:** Lists existing holidays in the "Add Holidays" dialog.
- [x] **Delete Holidays:** Allows removing existing holidays.
- [x] **Holiday Persistence:** Saves and loads holidays using local storage.
- [x] **Holiday Types:** Differentiates between 'winter', 'summer', and 'other' holidays with distinct icons.

## Bus Assignment

- [x] **Add Bus Number:** Dialog allows adding/editing bus numbers for the first half, second half, or the entire shift (if workout).
- [x] **Persistence:** Saves bus numbers with the event data.

## Settings & Other

- [x] **Settings Menu:** Provides access to:
  - [x] About page
  - [x] Statistics page
  - [x] Holidays management dialog
  - [x] Contacts page
  - [x] Settings page (which includes theme toggle, roster selection, etc.)
- [x] **Roster Loading:** Loads shift patterns and duty details from CSV files included in the app assets. Handles different files based on zone, day of the week, and bank holiday status.
- [x] **Location Mapping:** Maps short location codes from CSVs to full names (e.g., `WH` to `Woodhouse`).

## Potential/Integration Features (Based on Code)

- [ ] **Google Calendar Sync:** Code exists for potentially syncing events and holidays with Google Calendar (`google_calendar_service.dart`, `calendar_test_helper.dart`). *Requires user authentication.* (Note: Current active usage level unclear from static analysis).

## Production Readiness Tasks

- [ ] **Google Calendar Sync Authentication:**
  - [ ] Change OAuth Consent Screen status from 'Testing' to 'Production' in Google Cloud Console.
  - [ ] Complete Google app verification process if required (may need Privacy Policy/ToS links, app details).
- [ ] **Error Handling & Logging:**
  - [ ] Implement a robust logging framework (e.g., `logging` package).
  - [ ] Replace development `print()` statements with proper logging.
  - [ ] Ensure user-facing errors are displayed gracefully (avoid technical details or crashes).
  - [ ] Add more robust error handling around CSV loading/parsing.
- [ ] **Testing:**
  - [ ] Implement Unit Tests for core logic (services, calculations).
  - [ ] Implement Widget Tests for UI components (cards, dialogs).
  - [ ] Implement Integration Tests for key user flows.
- [ ] **State Management:**
  - [ ] Evaluate if a more structured state management solution (Provider, Riverpod, BLoC) is needed for maintainability.
- [ ] **UI/UX Polish:**
  - [x] Review UI for consistency
  - [ ] Implement clear loading indicators for all async operations
  - [ ] Implement helpful 'empty state' views where applicable
  - [ ] Perform accessibility checks (contrast, screen readers).
- [ ] **Build & Distribution:**
  - [ ] Configure release build settings (Android App Bundle, iOS, etc.).
  - [ ] Set up code signing for target platforms.
  - [ ] Create final app icons and splash screens.
  - [ ] Define distribution strategy (App Store, Play Store, etc.).
- [ ] **Documentation:**
  - [ ] Create a user guide explaining features and usage.
  - [ ] Create a Privacy Policy.
  - [ ] Create Terms of Service (Optional but recommended). 