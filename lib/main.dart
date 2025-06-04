import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemChrome
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/welcome/screens/welcome_screen.dart';
import 'package:spdrivercalendar/features/google/screens/google_login_screen.dart';
import 'package:spdrivercalendar/features/calendar/screens/calendar_screen.dart';
import 'package:spdrivercalendar/features/whatsnew/screens/whats_new_screen.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/services/rest_days_service.dart';
import 'package:spdrivercalendar/core/config/flutter_config.dart';
import 'package:spdrivercalendar/core/widgets/rebuild_text.dart';
import 'package:spdrivercalendar/services/notification_service.dart';
import 'package:spdrivercalendar/core/services/cache_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spdrivercalendar/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/settings/screens/version_history_screen.dart';
import 'package:spdrivercalendar/services/update_service.dart';
import 'package:spdrivercalendar/core/widgets/enhanced_update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable edge-to-edge display BEFORE other initializations
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize cache service first
  final cacheService = CacheService();
  
  // Run independent initializations in parallel
  await Future.wait([
    NotificationService().init(),
    FlutterConfig.configure(),
    StorageService.init(),
    RestDaysService.initialize(),
    GoogleCalendarService.initialize(),
    ShiftService.initialize(),
  ]);

  // Initialize EventService AFTER StorageService is ready (as it reads from SharedPreferences)
  await EventService.initializeService();

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
    Key? key,
    required this.isDarkModeInitial,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
      print("App paused, checking for auto-backup.");
      final prefs = await SharedPreferences.getInstance();
      final bool autoBackupEnabled = prefs.getBool(AppConstants.autoBackupEnabledKey) ?? true;

      if (autoBackupEnabled) {
        print("Auto-backup enabled, creating backup...");
        bool success = await BackupService.createAutoBackup();
        if (success) {
          print("Auto-backup successful on app pause.");
        } else {
          print("Auto-backup failed on app pause.");
        }
      }
    } else if (state == AppLifecycleState.resumed) {
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
                  final state = context.findAncestorStateOfType<_SplashScreenState>();
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
                  final isFromSettings = ModalRoute.of(context)?.settings.arguments as bool? ?? false;
                  if (isFromSettings) {
                    Navigator.pop(context);
                  } else {
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
    Key? key,
    required this.isDarkModeNotifier,
    required this.onInitializationComplete,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    await Future.delayed(Duration.zero);

    final shouldShowWhatsNew = await _checkVersionUpdate();

    if (shouldShowWhatsNew && mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.whatsNewRoute);
      return;
    }

    await _checkOnboardingStatus();
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
      Navigator.pushReplacementNamed(context, nextRoute);
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
