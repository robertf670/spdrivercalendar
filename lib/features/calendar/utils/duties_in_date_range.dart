import 'package:spdrivercalendar/models/event.dart';

/// Work-shift duties whose start date falls in [start]–[end] (inclusive).
///
/// Holidays and non-duty events are skipped. Dates are compared as calendar
/// days. Either date order is accepted.
List<Event> dutiesInDateRange({
  required Iterable<Event> events,
  required DateTime start,
  required DateTime end,
}) {
  final rangeStart = DateTime(start.year, start.month, start.day);
  final rangeEnd = DateTime(end.year, end.month, end.day);
  final first = rangeStart.isBefore(rangeEnd) ? rangeStart : rangeEnd;
  final last = rangeStart.isBefore(rangeEnd) ? rangeEnd : rangeStart;

  return events.where((event) {
    if (event.isHoliday || !event.isWorkShift) return false;
    final day = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
    );
    return !day.isBefore(first) && !day.isAfter(last);
  }).toList();
}
