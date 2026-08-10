import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/booked_holidays_filter.dart';
import 'package:spdrivercalendar/models/holiday.dart';

Holiday _h(String id, String type, DateTime start, [DateTime? end]) {
  return Holiday(
    id: id,
    type: type,
    startDate: start,
    endDate: end ?? start,
  );
}

void main() {
  final holidays = [
    _h('1', 'winter', DateTime(2025, 12, 1), DateTime(2025, 12, 7)),
    _h('2', 'summer', DateTime(2026, 7, 1), DateTime(2026, 7, 14)),
    _h('3', 'other', DateTime(2026, 3, 1)),
    _h('4', 'day_in_lieu', DateTime(2026, 2, 1)),
    _h('5', 'unpaid', DateTime(2026, 4, 1)),
  ];

  test('annual leave includes winter/summer/other sorted by start', () {
    final booked = filterBookedHolidays(
      holidays: holidays,
      holidayType: 'annualLeave',
    );
    expect(booked.map((h) => h.id), ['1', '3', '2']);
  });

  test('days in lieu only includes day_in_lieu', () {
    final booked = filterBookedHolidays(
      holidays: holidays,
      holidayType: 'daysInLieu',
    );
    expect(booked.map((h) => h.id), ['4']);
  });

  test('after-delete annual leave keeps today and future starts only', () {
    final booked = filterBookedHolidaysAfterDelete(
      holidays: holidays,
      holidayType: 'annualLeave',
      today: DateTime(2026, 3, 1),
    );
    expect(booked.map((h) => h.id), ['3', '2']);
  });
}
