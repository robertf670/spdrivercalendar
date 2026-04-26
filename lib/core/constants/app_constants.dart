import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Spare Driver Shift Calendar';
  static const String appVersion = '3.2.4';
  
  // Storage Keys
  static const String eventsStorageKey = 'events';
  static const String dayNotesStorageKey = 'day_notes';
  static const String startDateKey = 'startDate';
  static const String startWeekKey = 'startWeek';
  static const String endDateKey = 'endDate';
  static const String shiftTypeKey = 'shiftType';
  static const String restDaysKey = 'restDays';
  static const String restDaySwapsKey = 'restDaySwaps';
  static const String isDarkModeKey = 'isDarkMode';
  static const String hasSeenWelcomeKey = 'hasSeenWelcome';
  static const String hasCompletedGoogleLoginKey = 'hasCompletedGoogleLogin';
  static const String googleCalendarIdKey = 'googleCalendarId';
  static const String lastGoogleSyncTimeKey = 'lastGoogleSyncTime';
  static const String syncToGoogleCalendarKey = 'syncToGoogleCalendar';
  static const String includeBusAssignmentsInGoogleCalendarKey = 'includeBusAssignmentsInGoogleCalendar';
  static const String includeBustimesLinksInGoogleCalendarKey = 'includeBustimesLinksInGoogleCalendar';
  static const String lastSeenVersionKey = 'lastSeenVersion';

  // Auto-Backup Setting
  static const String autoBackupEnabledKey = 'autoBackupEnabled';
  
  // Display Settings
  static const String showOvernightDutiesOnBothDaysKey = 'showOvernightDutiesOnBothDays';
  static const String showDutyCodesOnCalendarKey = 'showDutyCodesOnCalendar';
  static const String animatedSelectedDayKey = 'animatedSelectedDay';
  static const String highlightWorkoutDaysKey = 'highlightWorkoutDays';
  static const String workoutDatesCacheKey = 'workoutDatesCache';

  // Marked In Status
  static const String markedInEnabledKey = 'markedInEnabled';
  static const String markedInStatusKey = 'markedInStatus';
  static const String markedInZoneKey = 'markedInZone'; // Zone selection when Shift is selected (Zone 1, Zone 3, Zone 4)

  /// When false, the add-duty dialog does not offer Shift Zone 1 15-week roster auto-fill.
  static const bool enableZone1ShiftDutyRosterAutoFill = false;

  // Bank holidays (persisted for home screen widget - JSON array of "yyyy-MM-dd" strings)
  static const String bankHolidayDatesKey = 'bankHolidayDates';

  /// JSON array of ISO local date keys for "redundant (day off)" on bank holidays when no work shift.
  static const String bankHolidayRedundantDaysKey = 'bank_holiday_redundant_days';

  // Pay Rate
  static const String spreadPayRateKey = 'spreadPayRate';

  // Days In Lieu
  static const String daysInLieuBalanceKey = 'daysInLieuBalance';
  static const String hasSetDaysInLieuKey = 'hasSetDaysInLieu';

  // Annual Leave
  static const String annualLeaveBalanceKey = 'annualLeaveBalance';
  static const String hasSetAnnualLeaveKey = 'hasSetAnnualLeave';
  /// Days of annual leave that have "passed" since [annualLeaveLastProcessedDateKey] (forward-only; not all history).
  static const String annualLeaveAutoConsumedKey = 'annualLeaveAutoConsumed';
  /// Last calendar date (yyyy-MM-dd local) fully processed for auto consumption; no backfill before first run.
  static const String annualLeaveLastProcessedDateKey = 'annualLeaveLastProcessedDate';

  // Admin Panel
  static const String adminRememberDeviceKey = 'adminRememberDevice';

  // PWA Web Access (Web only)
  static const String workAccessGrantedKey = 'workAccessGranted';

  // Routes
  static const String splashRoute = '/splash';
  static const String accessRoute = '/access';
  static const String welcomeRoute = '/welcome';
  static const String googleLoginRoute = '/google-login';
  static const String homeRoute = '/home';
  static const String settingsRoute = '/settings';
  static const String statisticsRoute = '/statistics';
  static const String whatsNewRoute = '/whats-new';
  static const String versionHistoryRoute = '/version-history';

  // Colors (example)
  static const Color primaryColor = Colors.blue; // Example primary color

  // Other constants
  // ... add any other app-wide constants here
}
