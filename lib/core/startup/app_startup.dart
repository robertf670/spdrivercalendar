import 'dart:async';
import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spdrivercalendar/core/config/flutter_config.dart';
import 'package:spdrivercalendar/core/config/platform_utils.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/firebase_options.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';
import 'package:spdrivercalendar/services/notification_service.dart';
import 'package:spdrivercalendar/services/rest_day_swap_service.dart';
import 'package:spdrivercalendar/services/rest_days_service.dart';
import 'package:spdrivercalendar/services/user_activity_service.dart';

/// Boots the app in two stages so web can paint a splash before heavy work.
class AppStartup {
  static FirebaseAnalytics? analytics;
  static FirebaseAnalyticsObserver? observer;
  static Future<void>? _heavy;

  /// Web waits until the first Flutter frame; Android still inits before [runApp].
  static bool deferHeavyInit({bool? isWeb}) => isWeb ?? PlatformUtils.isWeb;

  static Future<void> essentials() async {
    await Future.wait([
      initializeDateFormatting('en_GB', null),
      initializeDateFormatting('en_US', null),
    ]);
    await StorageService.init();
  }

  static Future<void> ensureHeavyInit() => _heavy ??= _runHeavy();

  static Future<void> _runHeavy() async {
    final isWeb = PlatformUtils.isWeb;
    if (isWeb) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    } else {
      await Firebase.initializeApp();
    }
    analytics = FirebaseAnalytics.instance;
    observer = FirebaseAnalyticsObserver(analytics: analytics!);

    await Future.wait([
      if (!isWeb) NotificationService().init(),
      FlutterConfig.configure(),
      RestDaysService.initialize(),
      RestDaySwapService.initialize(),
      if (!isWeb) GoogleCalendarService.initialize(),
      ShiftService.initialize(),
      ColorCustomizationService.initialize(),
    ]);

    await EventService.initializeService();
    if (!isWeb) {
      await persistBankHolidaysForWidget();
    }
    UserActivityService.trackUserActivity();
    if (isWeb) {
      unawaited(GoogleCalendarService.initialize());
    }
  }

  /// Persists bank holiday dates to SharedPreferences for the home screen widget.
  static Future<void> persistBankHolidaysForWidget() async {
    try {
      final holidays = await RosterService.loadBankHolidays();
      final dateStrings = holidays
          .map(
            (h) =>
                '${h.date.year.toString().padLeft(4, '0')}-${h.date.month.toString().padLeft(2, '0')}-${h.date.day.toString().padLeft(2, '0')}',
          )
          .toList();
      await StorageService.saveString(
        AppConstants.bankHolidayDatesKey,
        jsonEncode(dateStrings),
      );
    } catch (_) {
      // Ignore - widget will fall back to weekday check only
    }
  }
}
