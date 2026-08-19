import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/shift_rest_gap.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _duty({
  required String id,
  required String title,
  required DateTime startDate,
  required TimeOfDay startTime,
  required DateTime endDate,
  required TimeOfDay endTime,
  String? sickDayType,
  bool bankHolidayRedundant = false,
  bool isHoliday = false,
}) {
  return Event(
    id: id,
    title: title,
    startDate: startDate,
    startTime: startTime,
    endDate: endDate,
    endTime: endTime,
    sickDayType: sickDayType,
    bankHolidayRedundant: bankHolidayRedundant,
    isHoliday: isHoliday,
  );
}

void main() {
  final today = DateTime(2026, 8, 19);
  final tomorrow = DateTime(2026, 8, 20);

  final lateFinish = _duty(
    id: 'a',
    title: 'PZ1/10',
    startDate: today,
    startTime: const TimeOfDay(hour: 15, minute: 0),
    endDate: today,
    endTime: const TimeOfDay(hour: 23, minute: 50),
  );

  final nextMorning = _duty(
    id: 'b',
    title: 'PZ1/01',
    startDate: tomorrow,
    startTime: const TimeOfDay(hour: 10, minute: 15),
    endDate: tomorrow,
    endTime: const TimeOfDay(hour: 18, minute: 0),
  );

  test('uses sign-off to next report', () {
    final gap = ShiftRestGap.fromSignOffToNextReport(
      current: lateFinish,
      events: [lateFinish, nextMorning],
    );

    expect(gap, const Duration(hours: 10, minutes: 25));
    expect(ShiftRestGap.format(gap!), '10h 25m');
  });

  test('returns null when there is no later duty', () {
    expect(
      ShiftRestGap.fromSignOffToNextReport(
        current: lateFinish,
        events: [lateFinish],
      ),
      isNull,
    );
  });

  test('skips the same duty id (overnight duplicate)', () {
    expect(
      ShiftRestGap.fromSignOffToNextReport(
        current: lateFinish,
        events: [lateFinish, lateFinish],
      ),
      isNull,
    );
  });

  test('returns null when the next duty is not the following day', () {
    final threeDaysLater = _duty(
      id: 'c',
      title: 'PZ1/62',
      startDate: DateTime(2026, 8, 22),
      startTime: const TimeOfDay(hour: 12, minute: 43),
      endDate: DateTime(2026, 8, 22),
      endTime: const TimeOfDay(hour: 21, minute: 30),
    );

    expect(
      ShiftRestGap.fromSignOffToNextReport(
        current: lateFinish,
        events: [lateFinish, threeDaysLater],
      ),
      isNull,
    );
  });

  test('returns null when the following day is sick even if a later duty exists', () {
    final sick = _duty(
      id: 's',
      title: 'PZ1/02',
      startDate: tomorrow,
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endDate: tomorrow,
      endTime: const TimeOfDay(hour: 16, minute: 0),
      sickDayType: 'normal',
    );
    final later = _duty(
      id: 'c',
      title: 'PZ1/03',
      startDate: DateTime(2026, 8, 21),
      startTime: const TimeOfDay(hour: 7, minute: 0),
      endDate: DateTime(2026, 8, 21),
      endTime: const TimeOfDay(hour: 15, minute: 0),
    );

    expect(
      ShiftRestGap.fromSignOffToNextReport(
        current: lateFinish,
        events: [lateFinish, sick, later],
      ),
      isNull,
    );
  });

  test('handles overnight sign-off into the next calendar day', () {
    final overnight = _duty(
      id: 'n',
      title: 'PZ4/20',
      startDate: today,
      startTime: const TimeOfDay(hour: 18, minute: 0),
      endDate: tomorrow,
      endTime: const TimeOfDay(hour: 1, minute: 30),
    );
    final after = _duty(
      id: 'm',
      title: 'PZ1/04',
      startDate: tomorrow,
      startTime: const TimeOfDay(hour: 12, minute: 0),
      endDate: tomorrow,
      endTime: const TimeOfDay(hour: 20, minute: 0),
    );

    final gap = ShiftRestGap.fromSignOffToNextReport(
      current: overnight,
      events: [overnight, after],
    );

    expect(gap, const Duration(hours: 10, minutes: 30));
  });

  test('format omits zero minutes or hours', () {
    expect(ShiftRestGap.format(const Duration(hours: 11)), '11h');
    expect(ShiftRestGap.format(const Duration(minutes: 45)), '45m');
  });
}
