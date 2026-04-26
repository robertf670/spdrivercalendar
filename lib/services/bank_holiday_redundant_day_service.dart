import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';

/// Days with no work shift but marked "redundant" on a bank holiday (day off) — [Set] in prefs.
class BankHolidayRedundantDayService {
  static final Set<String> _dateKeys = {};
  static bool _isLoaded = false;

  static String _dateToKey(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  static Future<void> load() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(AppConstants.bankHolidayRedundantDaysKey);
      if (json != null) {
        final list = jsonDecode(json) as List<dynamic>?;
        if (list != null) {
          _dateKeys
            ..clear()
            ..addAll(list.map((e) => e as String));
        }
      }
      _isLoaded = true;
    } catch (_) {
      _isLoaded = true;
    }
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.bankHolidayRedundantDaysKey,
        jsonEncode(_dateKeys.toList()..sort()),
      );
    } catch (_) {}
  }

  /// Mark for a bank holiday with no [Event] (day-only).
  static bool isMarked(DateTime date) {
    return _dateKeys.contains(_dateToKey(date));
  }

  static Future<void> setMarked(DateTime date, bool marked) async {
    await load();
    final key = _dateToKey(date);
    if (marked) {
      _dateKeys.add(key);
    } else {
      _dateKeys.remove(key);
    }
    await _persist();
  }

  /// When a work shift is added, drop the day-only mark so the shift (or its toggle) is the source of truth.
  static Future<void> onWorkShiftAddedToDate(DateTime date) async {
    await load();
    if (_dateKeys.remove(_dateToKey(date))) {
      await _persist();
    }
  }

  static void invalidateCache() {
    _isLoaded = false;
    _dateKeys.clear();
  }
}
