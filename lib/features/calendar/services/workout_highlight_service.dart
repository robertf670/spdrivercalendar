import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';

/// Service to compute and cache which calendar dates have workout duties.
/// Used by the "Refresh Workout Highlights" button in Settings to scan all
/// duties across all months, fixing the limitation where only the focused
/// month was previously checked.
class WorkoutHighlightService {
  /// Scans all stored events and computes which dates have workout duties.
  /// Returns the set of dates (year, month, day) and saves to cache.
  static Future<Set<DateTime>> computeAndCacheAllWorkoutDates() async {
    final workoutSet = <DateTime>{};

    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(AppConstants.eventsStorageKey);

      if (eventsJson == null || eventsJson.isEmpty) {
        await _saveWorkoutDatesCache(workoutSet);
        return workoutSet;
      }

      final Map<String, dynamic> decodedData = jsonDecode(eventsJson);

      for (final entry in decodedData.entries) {
        try {
          final eventsData = entry.value;
          if (eventsData is! List<dynamic>) continue;

          for (final eventData in eventsData) {
            if (eventData is! Map<String, dynamic>) continue;

            try {
              if (!_validateEventData(eventData)) continue;

              final event = Event.fromMap(eventData);

              if (event.isHoliday || event.sickDayType != null) continue;

              final dutyCode =
                  event.title.replaceAll('Shift: ', '').trim();
              if (!event.title.startsWith('Shift:') &&
                  !event.title.startsWith('SP') &&
                  !RegExp(r'^\d{1,3}/\d{1,2}').hasMatch(dutyCode) &&
                  !event.title.toUpperCase().contains('PZ')) {
                continue;
              }

              final breakTime = await ShiftService.getBreakTime(event);
              if (breakTime != null &&
                  breakTime.toLowerCase() == 'workout') {
                final d = event.startDate;
                workoutSet.add(DateTime(d.year, d.month, d.day));
                break; // One workout per day is enough
              }
            } catch (_) {
              // Ignore per-event errors
            }
          }
        } catch (_) {
          // Ignore per-date errors
        }
      }

      await _saveWorkoutDatesCache(workoutSet);
      return workoutSet;
    } catch (e) {
      return workoutSet;
    }
  }

  static bool _validateEventData(Map<String, dynamic> data) {
    try {
      if (data['id'] == null ||
          data['title'] == null ||
          data['startDate'] == null ||
          data['endDate'] == null) {
        return false;
      }
      DateTime.parse(data['startDate']);
      DateTime.parse(data['endDate']);
      if (data['startTime'] != null) {
        final startTime = data['startTime'];
        if (startTime['hour'] == null || startTime['minute'] == null) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _saveWorkoutDatesCache(Set<DateTime> dates) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStrings =
        dates.map((d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}').toList();
    await prefs.setString(
        AppConstants.workoutDatesCacheKey, jsonEncode(dateStrings));
  }

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

  /// Clears the workout dates cache (e.g. when user wants to force recompute).
  static Future<void> clearWorkoutDatesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.workoutDatesCacheKey);
  }
}
