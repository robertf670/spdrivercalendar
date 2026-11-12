import 'package:spdrivercalendar/models/holiday.dart';

DateTime holidayDateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool holidayIsSingleDay(Holiday holiday) {
  final start = holidayDateOnly(holiday.startDate);
  final end = holidayDateOnly(holiday.endDate);
  return start == end;
}

/// Holiday rows left after [day] is taken out of [holiday].
///
/// A one-day booking disappears. A longer booking keeps the days on either side.
List<Holiday> holidayExcludingDay(
  Holiday holiday,
  DateTime day, {
  required String idStamp,
}) {
  final dayOnly = holidayDateOnly(day);
  final start = holidayDateOnly(holiday.startDate);
  final end = holidayDateOnly(holiday.endDate);
  if (dayOnly.isBefore(start) || dayOnly.isAfter(end)) {
    return [holiday];
  }
  if (start == end) {
    return [];
  }

  final pieces = <Holiday>[];
  if (dayOnly.isAfter(start)) {
    pieces.add(Holiday(
      id: '${holiday.id}_${idStamp}_before',
      startDate: start,
      endDate: dayOnly.subtract(const Duration(days: 1)),
      type: holiday.type,
    ));
  }
  if (dayOnly.isBefore(end)) {
    pieces.add(Holiday(
      id: '${holiday.id}_${idStamp}_after',
      startDate: dayOnly.add(const Duration(days: 1)),
      endDate: end,
      type: holiday.type,
    ));
  }
  return pieces;
}
