import 'package:collection/collection.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/calendar/services/workout_highlight_service.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';

typedef WorkoutBreakTimeLookup = Future<String?> Function(Event event);
typedef WorkoutEventsForDay = List<Event> Function(DateTime day);
typedef WorkoutMonthPreloader = Future<void> Function(DateTime month);

/// Loads workout highlight dates for the calendar month grid.
class WorkoutDatesLoader {
  WorkoutDatesLoader({
    Future<Set<DateTime>?> Function()? loadCache,
    WorkoutMonthPreloader? preloadMonth,
    WorkoutEventsForDay? eventsForDay,
    WorkoutBreakTimeLookup? getBreakTime,
  })  : _loadCache = loadCache ?? WorkoutHighlightService.loadWorkoutDatesCache,
        _preloadMonth = preloadMonth ?? EventService.preloadMonth,
        _eventsForDay = eventsForDay ?? EventService.getEventsForDay,
        _getBreakTime = getBreakTime ?? ShiftService.getBreakTime;

  final Future<Set<DateTime>?> Function() _loadCache;
  final WorkoutMonthPreloader _preloadMonth;
  final WorkoutEventsForDay _eventsForDay;
  final WorkoutBreakTimeLookup _getBreakTime;

  static String monthKey(DateTime month) => '${month.year}-${month.month}';

  /// Returns a globally cached set when available.
  Future<Set<DateTime>?> loadCachedDates() => _loadCache();

  /// Scans one month for workout break rows.
  Future<Set<DateTime>> loadForMonth(DateTime month) async {
    final workoutSet = <DateTime>{};
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    await _preloadMonth(month);

    for (var d = firstDay;
        !d.isAfter(lastDay);
        d = d.add(const Duration(days: 1))) {
      final events = _eventsForDay(d);
      for (final event in events) {
        if (event.isHoliday || event.sickDayType != null) continue;
        final title = event.title;
        final dutyCode = title.replaceAll('Shift: ', '').trim();
        if (!title.startsWith('Shift:') &&
            !title.startsWith('SP') &&
            !title.startsWith(DonnybrookFeatureService.shiftPrefix) &&
            !RegExp(r'^\d{1,3}/\d{1,2}').hasMatch(dutyCode) &&
            !title.toUpperCase().contains('PZ')) {
          continue;
        }
        try {
          final breakTime = await _getBreakTime(event);
          if (breakTime != null && breakTime.toLowerCase() == 'workout') {
            workoutSet.add(DateTime(d.year, d.month, d.day));
            break;
          }
        } catch (_) {
          // Ignore per-event errors
        }
      }
    }

    return workoutSet;
  }

  static bool setsEqual(Set<DateTime>? a, Set<DateTime>? b) {
    return const SetEquality<DateTime>().equals(a, b);
  }
}
