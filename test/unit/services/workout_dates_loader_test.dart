import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/workout_dates_loader.dart';
import 'package:spdrivercalendar/models/event.dart';

void main() {
  test('monthKey formats year-month', () {
    expect(WorkoutDatesLoader.monthKey(DateTime(2026, 8, 19)), '2026-8');
  });

  test('loadForMonth finds workout break days', () async {
    final day = DateTime(2026, 8, 4);
    final loader = WorkoutDatesLoader(
      preloadMonth: (_) async {},
      eventsForDay: (date) {
        if (date.year == day.year &&
            date.month == day.month &&
            date.day == day.day) {
          return [
            Event(
              id: 'e1',
              title: 'PZ1/01',
              startDate: day,
              endDate: day,
              startTime: const TimeOfDay(hour: 5, minute: 0),
              endTime: const TimeOfDay(hour: 13, minute: 0),
            ),
          ];
        }
        return const [];
      },
      getBreakTime: (event) async =>
          event.title == 'PZ1/01' ? 'workout' : null,
    );

    final dates = await loader.loadForMonth(DateTime(2026, 8, 1));
    expect(dates, {DateTime(2026, 8, 4)});
  });
}
