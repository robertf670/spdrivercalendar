import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Spare Driver Shift Calendar';
  static const String appVersion = '2.8.1';
  
  // Storage Keys
  static const String eventsStorageKey = 'events';
  static const String startDateKey = 'startDate';
  static const String startWeekKey = 'startWeek';
  static const String endDateKey = 'endDate';
  static const String shiftTypeKey = 'shiftType';
  static const String restDaysKey = 'restDays';
  static const String isDarkModeKey = 'isDarkMode';
  static const String hasSeenWelcomeKey = 'hasSeenWelcome';
  static const String hasCompletedGoogleLoginKey = 'hasCompletedGoogleLogin';
  static const String googleCalendarIdKey = 'googleCalendarId';
  static const String lastGoogleSyncTimeKey = 'lastGoogleSyncTime';
  static const String syncToGoogleCalendarKey = 'syncToGoogleCalendar';
  static const String lastSeenVersionKey = 'lastSeenVersion';

  // Auto-Backup Setting
  static const String autoBackupEnabledKey = 'autoBackupEnabled';

  // Routes
  static const String splashRoute = '/splash';
  static const String welcomeRoute = '/welcome';
  static const String googleLoginRoute = '/google-login';
  static const String homeRoute = '/home';
  static const String settingsRoute = '/settings';
  static const String statisticsRoute = '/statistics';
  static const String aboutRoute = '/about';
  static const String whatsNewRoute = '/whats-new';
  static const String versionHistoryRoute = '/version-history';

  // Colors (example)
  static const Color primaryColor = Colors.blue; // Example primary color

  // Other constants
  // ... add any other app-wide constants here
}
