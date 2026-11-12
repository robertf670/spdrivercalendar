import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_duty_overlap.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/holiday.dart';

Event _duty(String title, DateTime day, {bool isHoliday = false}) {
  return Event(
    id: title,
    title: title,
    startDate: day,
    startTime: const TimeOfDay(hour: 6, minute: 0),
    endDate: day,
    endTime: const TimeOfDay(hour: 14, minute: 0),
    isHoliday: isHoliday,
  );
}

void main() {
  final winterWeek = Holiday(
    id: 'w1',
    startDate: DateTime(2026, 11, 8),
    endDate: DateTime(2026, 11, 14),
    type: 'winter',
  );

  test('finds a duty already saved on a holiday day', () {
    final dates = dutyDatesOnHolidays(
      holidays: [winterWeek],
      events: [
        _duty('PZ1/20', DateTime(2026, 11, 8)),
        _duty('PZ1/21', DateTime(2026, 11, 16)),
      ],
    );

    expect(dates, [DateTime(2026, 11, 8)]);
  });

  test('ignores a holiday week with no duty on it', () {
    final dates = dutyDatesOnHolidays(
      holidays: [winterWeek],
      events: [
        _duty('Winter Holiday', DateTime(2026, 11, 8), isHoliday: true),
        _duty('Note', DateTime(2026, 11, 9)),
      ],
    );

    expect(dates, isEmpty);
  });

  test('includes overtime on a holiday and skips the same duty twice', () {
    final dates = dutyDatesOnHolidays(
      holidays: [winterWeek],
      events: [
        _duty('20A (OT)', DateTime(2026, 11, 10)),
        _duty('20A (OT)', DateTime(2026, 11, 10)),
      ],
    );

    expect(dates, [DateTime(2026, 11, 10)]);
  });
}
