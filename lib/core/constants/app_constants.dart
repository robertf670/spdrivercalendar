class AppConstants {
  static const String appName = 'Spare Driver Calendar';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String eventsStorageKey = 'events';
  static const String startDateKey = 'startDate';
  static const String startWeekKey = 'startWeek';
  static const String isDarkModeKey = 'isDarkMode';
  static const String hasSeenWelcomeKey = 'hasSeenWelcome';
  static const String hasCompletedGoogleLoginKey = 'hasCompletedGoogleLogin';
  static const String syncToGoogleCalendarKey = 'syncToGoogleCalendar';
  
  // Routes
  static const String welcomeRoute = '/welcome';
  static const String googleLoginRoute = '/google-login';
  static const String homeRoute = '/home';
}
