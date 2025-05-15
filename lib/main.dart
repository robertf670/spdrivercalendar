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
import 'package:spdrivercalendar/services/token_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable edge-to-edge display BEFORE other initializations
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize cache service first
  final cacheService = CacheService();
  
  // Run independent initializations in parallel
  // Keep NotificationService().init() here for foreground init
  await Future.wait([
    NotificationService().init(),
    FlutterConfig.configure(),
    StorageService.init(),
    RestDaysService.initialize(),
    GoogleCalendarService.initialize(),
    ShiftService.initialize(),
  ]);

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
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDarkModeNotifier,
      builder: (context, bool isDarkMode, child) {
        return RebuildText(
          child: MaterialApp(
            key: _rebuildKey,
            title: AppConstants.appName,
            theme: AppTheme.lightTheme(), // Provide light theme
            darkTheme: AppTheme.darkTheme(), // Provide dark theme
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, // Control theme mode
            initialRoute: AppConstants.splashRoute, // Start with the splash screen
            routes: {
              // New Splash Route
              AppConstants.splashRoute: (context) => const SplashScreen(),

              // What's New Route
              AppConstants.whatsNewRoute: (context) => WhatsNewScreen(
                onContinue: () {
                  // After viewing what's new, check onboarding status
                  final state = context.findAncestorStateOfType<_SplashScreenState>();
                  if (state != null) {
                    state._checkOnboardingStatus();
                  } else {
                    // Fallback if somehow we can't find the splash screen state
                    Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
                  }
                },
              ),

              // Existing Routes (adjusted callbacks)
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
                  await GoogleCalendarService.saveLoginStatus(true); // Save status directly
                  Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
                },
              ),
              AppConstants.homeRoute: (context) => CalendarScreen(_isDarkModeNotifier),
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _isDarkModeNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    TokenManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Existing logic to force rebuild on resume
      setState(() {});
    }
  }
}

// New SplashScreen Widget
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
    // Wait a frame to ensure context is available
    await Future.delayed(Duration.zero);

    // Check app version first
    final shouldShowWhatsNew = await _checkVersionUpdate();

    if (shouldShowWhatsNew && mounted) {
      // Show What's New screen first
      Navigator.pushReplacementNamed(context, AppConstants.whatsNewRoute);
      return;
    }

    // Otherwise, proceed with normal flow
    await _checkOnboardingStatus();
  }

  Future<bool> _checkVersionUpdate() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Get last seen version
      final lastSeenVersion = await StorageService.getString(AppConstants.lastSeenVersionKey);
      
      // If lastSeenVersion is null (first install), save current version and don't show What's New
      if (lastSeenVersion == null) {
        await StorageService.saveString(AppConstants.lastSeenVersionKey, currentVersion);
        return false;
      }
      
      // If versions are different, show What's New screen
      return lastSeenVersion != currentVersion;
    } catch (e) {
      // In case of error, don't show What's New screen
      return false;
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final hasSeenWelcome = await StorageService.getBool(AppConstants.hasSeenWelcomeKey, defaultValue: false);
    final hasCompletedGoogleLogin = await StorageService.getBool(AppConstants.hasCompletedGoogleLoginKey, defaultValue: false);

    // Determine the correct route based on onboarding status
    String nextRoute;
    if (hasSeenWelcome && hasCompletedGoogleLogin) {
      nextRoute = AppConstants.homeRoute;
    } else if (hasSeenWelcome) { // Welcome seen, but Google Login not complete
      nextRoute = AppConstants.googleLoginRoute;
    } else { // Welcome not seen
      nextRoute = AppConstants.welcomeRoute;
    }

    // Navigate and replace the splash screen
    if (mounted) { // Ensure the widget is still in the tree
      Navigator.pushReplacementNamed(context, nextRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple loading indicator while checking status
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
