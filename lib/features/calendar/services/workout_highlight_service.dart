import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';

/// Loads cached workout-highlight dates for the calendar month grid.
class WorkoutHighlightService {
  /// Loads cached workout dates from storage. Returns null if no cache exists.
  static Future<Set<DateTime>?> loadWorkoutDatesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(AppConstants.workoutDatesCacheKey);
      if (json == null || json.isEmpty) return null;

      final List<dynamic> list = jsonDecode(json);
      final set = <DateTime>{};
      for (final s in list) {
        if (s is String) {
          try {
            final d = DateTime.parse(s);
            set.add(DateTime(d.year, d.month, d.day));
          } catch (_) {}
        }
      }
      return set;
    } catch (_) {
      return null;
    }
  }
}
