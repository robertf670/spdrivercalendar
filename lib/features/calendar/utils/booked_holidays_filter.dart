import 'package:spdrivercalendar/models/holiday.dart';

/// Filters holidays for the Booked Holidays dialog (initial open).
///
/// Annual leave includes all winter/summer/other bookings (past and future).
List<Holiday> filterBookedHolidays({
  required List<Holiday> holidays,
  required String holidayType,
}) {
  final booked = <Holiday>[];
  if (holidayType == 'annualLeave') {
    booked.addAll(
      holidays.where(
        (holiday) =>
            holiday.type == 'winter' ||
            holiday.type == 'summer' ||
            holiday.type == 'other',
      ),
    );
  } else if (holidayType == 'daysInLieu') {
    booked.addAll(holidays.where((holiday) => holiday.type == 'day_in_lieu'));
  }
  booked.sort((a, b) => a.startDate.compareTo(b.startDate));
  return booked;
}

/// Filters holidays after a delete in the Booked Holidays dialog.
///
/// Preserves prior behaviour: annual leave keeps only today/future starts.
List<Holiday> filterBookedHolidaysAfterDelete({
  required List<Holiday> holidays,
  required String holidayType,
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final todayNormalized = DateTime(now.year, now.month, now.day);
  final booked = <Holiday>[];

  if (holidayType == 'annualLeave') {
    booked.addAll(
      holidays.where((h) {
        if (h.type != 'winter' && h.type != 'summer' && h.type != 'other') {
          return false;
        }
        final startDateNormalized = DateTime(
          h.startDate.year,
          h.startDate.month,
          h.startDate.day,
        );
        return !startDateNormalized.isBefore(todayNormalized);
      }),
    );
  } else if (holidayType == 'daysInLieu') {
    booked.addAll(holidays.where((h) => h.type == 'day_in_lieu'));
  }

  booked.sort((a, b) => a.startDate.compareTo(b.startDate));
  return booked;
}
