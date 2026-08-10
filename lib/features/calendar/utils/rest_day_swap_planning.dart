import 'package:spdrivercalendar/services/rest_day_swap_service.dart';

/// Pure planning helpers for the rest-day swap flow.
class RestDaySwapPlanning {
  RestDaySwapPlanning._();

  static DateTime normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String dateKey(DateTime date) {
    final day = normalizeDay(date);
    return '${day.year}-${day.month}-${day.day}';
  }

  /// Sunday start of the week containing [selected].
  static DateTime weekStartSunday(DateTime selected) {
    final weekday = selected.weekday % 7; // 0=Sun ... 6=Sat
    return normalizeDay(selected).subtract(Duration(days: weekday));
  }

  static RestDaySwap? findSwapForDate(
    Iterable<RestDaySwap> swaps,
    DateTime selected,
  ) {
    final norm = normalizeDay(selected);
    for (final swap in swaps) {
      final work = normalizeDay(swap.workDate);
      final rest = normalizeDay(swap.restDate);
      if ((work.year == norm.year &&
              work.month == norm.month &&
              work.day == norm.day) ||
          (rest.year == norm.year &&
              rest.month == norm.month &&
              rest.day == norm.day)) {
        return swap;
      }
    }
    return null;
  }

  /// Days in the same week that can be swapped with [selected].
  static List<DateTime> buildCandidates({
    required DateTime selected,
    required bool isWorkDay,
    required Iterable<RestDaySwap> existingSwaps,
    required String Function(DateTime date) rosterShiftForDate,
  }) {
    final weekStart = weekStartSunday(selected);
    final selectedNorm = normalizeDay(selected);
    final swappedDateKeys = <String>{};
    for (final swap in existingSwaps) {
      swappedDateKeys.add(dateKey(swap.workDate));
      swappedDateKeys.add(dateKey(swap.restDate));
    }

    final candidates = <DateTime>[];
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (day.year == selectedNorm.year &&
          day.month == selectedNorm.month &&
          day.day == selectedNorm.day) {
        continue;
      }
      if (swappedDateKeys.contains(dateKey(day))) continue;

      final rosterShift = rosterShiftForDate(day);
      if (isWorkDay && rosterShift == 'R') {
        candidates.add(day);
      } else if (!isWorkDay &&
          rosterShift != 'R' &&
          rosterShift.isNotEmpty) {
        candidates.add(day);
      }
    }
    return candidates;
  }

  static ({DateTime workDate, DateTime restDate}) resolvePair({
    required DateTime selected,
    required DateTime picked,
    required bool isWorkDay,
  }) {
    return (
      workDate: isWorkDay ? selected : picked,
      restDate: isWorkDay ? picked : selected,
    );
  }
}
