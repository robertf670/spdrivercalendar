import 'package:spdrivercalendar/features/calendar/utils/holiday_day_exclusion.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/holiday.dart';

/// A saved work duty, not a holiday marker or a note.
bool eventIsAddedDuty(Event event) {
  if (event.isHoliday) return false;
  if (event.isWorkShift || event.isWorkForOthers) return true;
  return event.title.contains('(OT)');
}

/// Dates, oldest first, where a saved duty sits on a booked holiday.
///
/// [isRestDay] skips days the driver was not due in.
List<DateTime> dutyDatesOnHolidays({
  required List<Holiday> holidays,
  required List<Event> events,
  bool Function(DateTime date)? isRestDay,
}) {
  final dates = <DateTime>{};
  for (final event in events) {
    if (!eventIsAddedDuty(event)) continue;
    final day = holidayDateOnly(event.startDate);
    if (isRestDay != null && isRestDay(day)) continue;
    if (holidays.any((holiday) => holiday.containsDate(day))) {
      dates.add(day);
    }
  }
  final sorted = dates.toList()..sort();
  return sorted;
}
