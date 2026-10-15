import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/duties_in_date_range.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _event({
  required String id,
  required String title,
  required DateTime date,
  bool isHoliday = false,
}) {
  return Event(
    id: id,
    title: title,
    startDate: date,
    endDate: date,
    startTime: const TimeOfDay(hour: 6, minute: 0),
    endTime: const TimeOfDay(hour: 14, minute: 0),
    isHoliday: isHoliday,
  );
}

void main() {
  final december = [
    _event(id: 'nov', title: 'PZ2/01', date: DateTime(2026, 11, 30)),
    _event(id: 'dec1', title: 'PZ2/04', date: DateTime(2026, 12, 1)),
    _event(id: 'dec15', title: 'PZ2/18', date: DateTime(2026, 12, 15)),
    _event(id: 'dec31', title: 'PZ2/08', date: DateTime(2026, 12, 31)),
    _event(id: 'jan', title: 'PZ2/11', date: DateTime(2027, 1, 1)),
    _event(
      id: 'hol',
      title: 'Christmas',
      date: DateTime(2026, 12, 25),
      isHoliday: true,
    ),
    _event(id: 'note', title: 'Note', date: DateTime(2026, 12, 10)),
  ];

  test('keeps duties on the inclusive start and end dates', () {
    final found = dutiesInDateRange(
      events: december,
      start: DateTime(2026, 12, 1),
      end: DateTime(2026, 12, 31),
    );

    expect(found.map((e) => e.id), ['dec1', 'dec15', 'dec31']);
  });

  test('accepts dates in either order', () {
    final found = dutiesInDateRange(
      events: december,
      start: DateTime(2026, 12, 31),
      end: DateTime(2026, 12, 1),
    );

    expect(found.map((e) => e.id), ['dec1', 'dec15', 'dec31']);
  });

  test('skips holidays and non-duty events', () {
    final found = dutiesInDateRange(
      events: december,
      start: DateTime(2026, 12, 10),
      end: DateTime(2026, 12, 25),
    );

    expect(found.map((e) => e.id), ['dec15']);
  });
}
