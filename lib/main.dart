import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/welcome/screens/welcome_screen.dart';
import 'package:spdrivercalendar/features/google/screens/google_login_screen.dart';
import 'package:spdrivercalendar/features/calendar/screens/calendar_screen.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/services/rest_days_service.dart';
import 'package:spdrivercalendar/core/config/flutter_config.dart';
import 'package:spdrivercalendar/core/widgets/rebuild_text.dart';
import 'package:spdrivercalendar/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notification Service
  await NotificationService().init();
  
  // Configure Flutter settings
  await FlutterConfig.configure();

  // Initialize storage service
  await StorageService.init();
  
  // Initialize rest days service
  await RestDaysService.initialize();
  
  // Get user preferences using StorageService instead of direct SharedPreferences
  final isDarkMode = await StorageService.getBool(AppConstants.isDarkModeKey, defaultValue: false);
  
  // Check if the user has completed initial setup
  bool hasCompletedInitialSetup = await StorageService.getString(AppConstants.startDateKey) != null;
  
  // Mark welcome as seen for existing users who have already set up the app
  if (hasCompletedInitialSetup && !await StorageService.getBool(AppConstants.hasSeenWelcomeKey)) {
    await StorageService.saveBool(AppConstants.hasSeenWelcomeKey, true);
  }
  
  // Get onboarding status
  final hasSeenWelcome = await StorageService.getBool(AppConstants.hasSeenWelcomeKey, defaultValue: false);
  final hasCompletedGoogleLogin = await StorageService.getBool(AppConstants.hasCompletedGoogleLoginKey, defaultValue: false);

  // Initialize Google Calendar service
  await GoogleCalendarService.initialize();

  // Initialize bank holidays
  await ShiftService.initialize();

  runApp(MyApp(
    isDarkMode: isDarkMode,
    hasSeenWelcome: hasSeenWelcome,
    hasCompletedGoogleLogin: hasCompletedGoogleLogin,
  ));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final bool hasSeenWelcome;
  final bool hasCompletedGoogleLogin;

  const MyApp({
    Key? key,
    required this.isDarkMode,
    required this.hasSeenWelcome,
    required this.hasCompletedGoogleLogin,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late ValueNotifier<bool> _isDarkModeNotifier;
  late bool _hasSeenWelcome;
  late bool _hasCompletedGoogleLogin;
  String _initialRoute = AppConstants.welcomeRoute;
  final _rebuildKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _isDarkModeNotifier = ValueNotifier(widget.isDarkMode);
    _hasSeenWelcome = widget.hasSeenWelcome;
    _hasCompletedGoogleLogin = widget.hasCompletedGoogleLogin;
    
    // Add observer for lifecycle events
    WidgetsBinding.instance.addObserver(this);
    
    // Determine initial route based on onboarding progress
    if (_hasSeenWelcome && _hasCompletedGoogleLogin) {
      _initialRoute = AppConstants.homeRoute;
    } else if (_hasSeenWelcome && !_hasCompletedGoogleLogin) {
      _initialRoute = AppConstants.googleLoginRoute;
    } else {
      _initialRoute = AppConstants.welcomeRoute;
    }
  }

  void _onWelcomePageComplete() async {
    await StorageService.saveBool(AppConstants.hasSeenWelcomeKey, true);
    setState(() {
      _hasSeenWelcome = true;
    });
  }
  
  void _onGoogleLoginComplete() async {
    await GoogleCalendarService.saveLoginStatus(true);
    setState(() {
      _hasCompletedGoogleLogin = true;
    });
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
            theme: isDarkMode ? AppTheme.darkTheme() : AppTheme.lightTheme(),
            initialRoute: _initialRoute,
            routes: {
              AppConstants.welcomeRoute: (context) => WelcomeScreen(
                onGetStarted: () {
                  _onWelcomePageComplete();
                  // Check if this is the first run or from settings
                  final isFromSettings = ModalRoute.of(context)?.settings.arguments as bool? ?? false;
                  if (isFromSettings) {
                    // If from settings, just go back
                    Navigator.pop(context);
                  } else {
                    // If first run, continue to Google login
                    Navigator.pushReplacementNamed(context, AppConstants.googleLoginRoute);
                  }
                },
              ),
              AppConstants.googleLoginRoute: (context) => GoogleLoginScreen(
                onLoginComplete: () {
                  _onGoogleLoginComplete();
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force a complete rebuild of the entire app when it comes back to foreground
      setState(() {});
    }
  }
}
