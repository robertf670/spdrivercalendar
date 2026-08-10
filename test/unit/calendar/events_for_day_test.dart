import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/events_for_day.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/holiday.dart';

void main() {
  test('prepends synthetic holiday events', () {
    final day = DateTime(2026, 8, 4);
    final persisted = [
      Event(
        id: 'e1',
        title: 'PZ1/01',
        startDate: day,
        endDate: day,
        startTime: const TimeOfDay(hour: 5, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
      ),
    ];

    final events = eventsForDay(
      day: day,
      persistedEvents: persisted,
      holidays: [
        Holiday(
          id: 'h1',
          startDate: day,
          endDate: day,
          type: 'winter',
        ),
      ],
    );

    expect(events, hasLength(2));
    expect(events.first.isHoliday, isTrue);
    expect(events.first.title, 'Winter Holiday');
    expect(events.last.title, 'PZ1/01');
  });

  test('holidayTitleForType covers known types', () {
    expect(holidayTitleForType('day_in_lieu'), 'Day In Lieu');
    expect(holidayTitleForType('other'), 'Holiday');
  });
}
