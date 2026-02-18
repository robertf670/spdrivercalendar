import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/welcome/screens/welcome_screen.dart';
import 'package:spdrivercalendar/features/google/screens/google_login_screen.dart';
import 'package:spdrivercalendar/features/calendar/screens/calendar_screen.dart';
import 'package:spdrivercalendar/features/whatsnew/screens/whats_new_screen.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/services/rest_days_service.dart';
import 'package:spdrivercalendar/services/rest_day_swap_service.dart';
import 'package:spdrivercalendar/core/config/flutter_config.dart';
import 'package:spdrivercalendar/core/widgets/rebuild_text.dart';
import 'package:spdrivercalendar/services/notification_service.dart';
import 'package:spdrivercalendar/core/services/cache_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spdrivercalendar/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/settings/screens/version_history_screen.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';
import 'package:spdrivercalendar/services/user_activity_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';

// Global Firebase Analytics instance
late FirebaseAnalytics analytics;
late FirebaseAnalyticsObserver observer;

/// Persists bank holiday dates to SharedPreferences for the home screen widget.
/// The widget reads these to match M-F pattern (bank holidays = Rest for M-F users).
Future<void> _persistBankHolidaysForWidget() async {
  try {
    final holidays = await RosterService.loadBankHolidays();
    final dateStrings = holidays
        .map((h) => '${h.date.year.toString().padLeft(4, '0')}-${h.date.month.toString().padLeft(2, '0')}-${h.date.day.toString().padLeft(2, '0')}')
        .toList();
    await StorageService.saveString(AppConstants.bankHolidayDatesKey, jsonEncode(dateStrings));
  } catch (_) {
    // Ignore - widget will fall back to weekday check only
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable edge-to-edge display BEFORE other initializations
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize locale data for table_calendar (required for en_GB and en_US locales)
  await Future.wait([
    initializeDateFormatting('en_GB', null),
    initializeDateFormatting('en_US', null),
  ]);

  // Initialize cache service first
  final cacheService = CacheService();
  
  // Initialize Firebase first
  await Firebase.initializeApp();
  
  // Initialize Firebase Analytics
  analytics = FirebaseAnalytics.instance;
  observer = FirebaseAnalyticsObserver(analytics: analytics);
  
  // Run independent initializations in parallel
  await Future.wait([
    NotificationService().init(),
    FlutterConfig.configure(),
    StorageService.init(),
    RestDaysService.initialize(),
    RestDaySwapService.initialize(),
    GoogleCalendarService.initialize(),
    ShiftService.initialize(),
    ColorCustomizationService.initialize(),
  ]);

  // Initialize EventService AFTER StorageService is ready (as it reads from SharedPreferences)
  await EventService.initializeService();

  // Persist bank holidays for home screen widget (M-F pattern matching)
  await _persistBankHolidaysForWidget();

  // Track user activity for analytics (after StorageService is ready)
  UserActivityService.trackUserActivity();

  // Get initial dark mode setting after StorageService is initialized
  final isDarkMode = await StorageService.getBool(AppConstants.isDarkModeKey, defaultValue: false);
  
  // Cache the dark mode setting
  cacheService.set(AppConstants.isDarkModeKey, isDarkMode);
  
  runApp(MyApp(
    isDarkModeInitial: isDarkMode,
  ));
}

class MyApp extends StatefulWidget {
  final bool isDarkModeInitial;

  const MyApp({
    super.key,
    required this.isDarkModeInitial,
  });

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late ValueNotifier<bool> _isDarkModeNotifier;
  final _rebuildKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isDarkModeNotifier = ValueNotifier(widget.isDarkModeInitial);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDarkModeNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {

      final prefs = await SharedPreferences.getInstance();
      final bool autoBackupEnabled = prefs.getBool(AppConstants.autoBackupEnabledKey) ?? true;

      if (autoBackupEnabled) {

        bool success = await BackupService.createAutoBackup();
        if (success) {

        } else {

        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // Track user activity when app resumes
      UserActivityService.trackUserActivity();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDarkModeNotifier,
      builder: (context, bool isDarkMode, child) {
        return RebuildText(
          key: _rebuildKey,
          child: MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            navigatorObservers: [observer],
            initialRoute: AppConstants.splashRoute,
            routes: {
              AppConstants.splashRoute: (context) => SplashScreen(
                isDarkModeNotifier: _isDarkModeNotifier,
                onInitializationComplete: (String initialRoute) {
                  Navigator.of(context).pushReplacementNamed(initialRoute);
                },
              ),
              AppConstants.whatsNewRoute: (context) => WhatsNewScreen(
                onContinue: () {
                  final state = context.findAncestorStateOfType<SplashScreenState>();
                  if (state != null) {
                    state._checkOnboardingStatus();
                  } else {
                    Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
                  }
                },
              ),
              AppConstants.welcomeRoute: (context) => WelcomeScreen(
                onGetStarted: () async {
                  await StorageService.saveBool(AppConstants.hasSeenWelcomeKey, true);
                  if (!context.mounted) return;
                  final isFromSettings = ModalRoute.of(context)?.settings.arguments as bool? ?? false;
                  if (isFromSettings) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } else {
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(context, AppConstants.googleLoginRoute);
                  }
                },
              ),
              AppConstants.googleLoginRoute: (context) => GoogleLoginScreen(
                onLoginComplete: () async {
                  Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
                },
              ),
              AppConstants.homeRoute: (context) => CalendarScreen(_isDarkModeNotifier),
              AppConstants.versionHistoryRoute: (context) => const VersionHistoryScreen(),
            },
          ),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final ValueNotifier<bool> isDarkModeNotifier;
  final Function(String) onInitializationComplete;

  const SplashScreen({
    super.key,
    required this.isDarkModeNotifier,
    required this.onInitializationComplete,
  });

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    await Future.delayed(Duration.zero);

    final shouldShowWhatsNew = await _checkVersionUpdate();

    if (shouldShowWhatsNew && mounted) {
      final navigator = Navigator.of(context);
      navigator.pushReplacementNamed(AppConstants.whatsNewRoute);
      return;
    }

    if (mounted) {
      await _checkOnboardingStatus();
    }
  }

  Future<bool> _checkVersionUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final lastSeenVersion = await StorageService.getString(AppConstants.lastSeenVersionKey);
      
      if (lastSeenVersion == null) {
        await StorageService.saveString(AppConstants.lastSeenVersionKey, currentVersion);
        return false;
      }
      
      return lastSeenVersion != currentVersion;
    } catch (e) {
      return false;
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final hasSeenWelcome = await StorageService.getBool(AppConstants.hasSeenWelcomeKey, defaultValue: false);
    final hasCompletedGoogleLogin = await StorageService.getBool(AppConstants.hasCompletedGoogleLoginKey, defaultValue: false);

    String nextRoute;
    if (hasSeenWelcome && hasCompletedGoogleLogin) {
      nextRoute = AppConstants.homeRoute;
    } else if (hasSeenWelcome) {
      nextRoute = AppConstants.googleLoginRoute;
    } else {
      nextRoute = AppConstants.welcomeRoute;
    }

    if (mounted) {
      widget.onInitializationComplete(nextRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
