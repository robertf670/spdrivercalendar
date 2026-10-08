import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/spare_meal.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _spare({
  required TimeOfDay start,
  required TimeOfDay end,
  DateTime? endDate,
}) {
  final day = DateTime(2026, 8, 4);
  return Event(
    id: 'sp',
    title: 'SP1200',
    startDate: day,
    startTime: start,
    endDate: endDate ?? day,
    endTime: end,
  );
}

void main() {
  test('12:00 spare original finish is 20:38', () {
    final start = DateTime(2026, 8, 4, 12);
    final finish = SpareMeal.originalFinish(start);
    expect(finish, DateTime(2026, 8, 4, 20, 38));
  });

  test('meal 14:00–15:00 on a 12:00 spare finishes 20:30', () {
    final start = DateTime(2026, 8, 4, 12);
    final mealStart = DateTime(2026, 8, 4, 14);
    expect(
      SpareMeal.finishWithMeal(start: start, mealStart: mealStart),
      DateTime(2026, 8, 4, 20, 30),
    );
  });

  test('keeps original finish when meal end plus 5h 30m is later', () {
    final start = DateTime(2026, 8, 4, 12);
    final mealStart = DateTime(2026, 8, 4, 16);
    // 17:00 + 5h 30m = 22:30, later than 20:38
    expect(
      SpareMeal.finishWithMeal(start: start, mealStart: mealStart),
      DateTime(2026, 8, 4, 20, 38),
    );
  });

  test('late spare original finish rolls into the next day', () {
    final times = SpareMeal.timesForStartClock('19:00');
    expect(times['startTime'], const TimeOfDay(hour: 19, minute: 0));
    expect(times['endTime'], const TimeOfDay(hour: 3, minute: 38));
    expect(times['isNextDay'], isTrue);
  });

  test('apply stores a 1-hour meal and the sooner finish', () {
    final event = _spare(
      start: const TimeOfDay(hour: 12, minute: 0),
      end: const TimeOfDay(hour: 20, minute: 38),
    );

    SpareMeal.apply(event, const TimeOfDay(hour: 14, minute: 0));

    expect(event.breakStartTime, const TimeOfDay(hour: 14, minute: 0));
    expect(event.breakEndTime, const TimeOfDay(hour: 15, minute: 0));
    expect(event.endTime, const TimeOfDay(hour: 20, minute: 30));
    expect(event.endDate, DateTime(2026, 8, 4));
  });

  test('clear restores the original spare finish', () {
    final event = _spare(
      start: const TimeOfDay(hour: 12, minute: 0),
      end: const TimeOfDay(hour: 20, minute: 30),
    );
    event.breakStartTime = const TimeOfDay(hour: 14, minute: 0);
    event.breakEndTime = const TimeOfDay(hour: 15, minute: 0);

    SpareMeal.clear(event);

    expect(event.breakStartTime, isNull);
    expect(event.breakEndTime, isNull);
    expect(event.endTime, const TimeOfDay(hour: 20, minute: 38));
    expect(event.endDate, DateTime(2026, 8, 4));
  });

  test('apply keeps usual finish clock when the new finish is sooner', () {
    final event = _spare(
      start: const TimeOfDay(hour: 12, minute: 0),
      end: const TimeOfDay(hour: 20, minute: 38),
    );
    expect(SpareMeal.originalFinishClock(event), '20:38');
    expect(SpareMeal.hasMovedFinish(event), isFalse);

    SpareMeal.apply(event, const TimeOfDay(hour: 14, minute: 0));

    expect(SpareMeal.originalFinishClock(event), '20:38');
    expect(event.endTime, const TimeOfDay(hour: 20, minute: 30));
    expect(SpareMeal.hasMovedFinish(event), isTrue);
  });

  test('late break does not move finish', () {
    final event = _spare(
      start: const TimeOfDay(hour: 12, minute: 0),
      end: const TimeOfDay(hour: 20, minute: 38),
    );
    SpareMeal.apply(event, const TimeOfDay(hour: 16, minute: 0));
    expect(SpareMeal.hasMovedFinish(event), isFalse);
    expect(event.endTime, const TimeOfDay(hour: 20, minute: 38));
  });

  test('isSpareTitle is SP only', () {
    expect(SpareMeal.isSpareTitle('SP1200'), isTrue);
    expect(SpareMeal.isSpareTitle('22B/01'), isFalse);
    expect(SpareMeal.isSpareTitle('PZ1/01'), isFalse);
  });
}
