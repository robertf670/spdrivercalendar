import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/calendar_events_by_date.dart';
import 'package:spdrivercalendar/models/event.dart';

void main() {
  test('maps string day keys to DateTime keys', () {
    final event = Event(
      id: 'e1',
      title: 'PZ1/01',
      startDate: DateTime(2026, 8, 4),
      endDate: DateTime(2026, 8, 4),
      startTime: const TimeOfDay(hour: 5, minute: 0),
      endTime: const TimeOfDay(hour: 13, minute: 0),
    );

    final mapped = mapEventsByDate({
      '2026-08-04T00:00:00.000': [event],
    });

    expect(mapped.keys.single, DateTime.parse('2026-08-04T00:00:00.000'));
    expect(mapped.values.single.single, same(event));
  });
}
