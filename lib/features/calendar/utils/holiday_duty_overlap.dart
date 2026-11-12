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
List<DateTime> dutyDatesOnHolidays({
  required List<Holiday> holidays,
  required List<Event> events,
}) {
  final dates = <DateTime>{};
  for (final event in events) {
    if (!eventIsAddedDuty(event)) continue;
    final day = holidayDateOnly(event.startDate);
    if (holidays.any((holiday) => holiday.containsDate(day))) {
      dates.add(day);
    }
  }
  final sorted = dates.toList()..sort();
  return sorted;
}
