import 'package:spdrivercalendar/models/event.dart';

/// Rest time from a duty's sign-off to the next day's report, if any.
class ShiftRestGap {
  ShiftRestGap._();

  /// Countable duty reporting on the calendar day after [current] starts, or null.
  static Event? nextDutyAfter({
    required Event current,
    required List<Event> events,
  }) {
    if (!_isCountableDuty(current)) return null;

    final followingDay = DateTime(
      current.startDate.year,
      current.startDate.month,
      current.startDate.day,
    ).add(const Duration(days: 1));
    final signOff = current.fullEndDateTime;
    Event? next;
    DateTime? nextReport;

    for (final event in events) {
      if (event.id == current.id) continue;
      if (!_isCountableDuty(event)) continue;
      if (!_isSameDay(event.startDate, followingDay)) continue;

      final report = event.fullStartDateTime;
      if (!report.isAfter(signOff)) continue;
      if (nextReport == null || report.isBefore(nextReport)) {
        next = event;
        nextReport = report;
      }
    }

    return next;
  }

  /// Sign-off → next day's report, or null when the following day has no duty.
  static Duration? fromSignOffToNextReport({
    required Event current,
    required List<Event> events,
  }) {
    final next = nextDutyAfter(current: current, events: events);
    if (next == null) return null;

    final gap = next.fullStartDateTime.difference(current.fullEndDateTime);
    if (gap <= Duration.zero) return null;
    return gap;
  }

  static String format(Duration gap) {
    final hours = gap.inHours;
    final minutes = gap.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isCountableDuty(Event event) {
    if (!event.isWorkShift) return false;
    if (event.isHoliday) return false;
    if (event.sickDayType != null) return false;
    if (event.bankHolidayRedundant) return false;
    return true;
  }
}

