import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/calendar_day_appearance.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/models/shift_info.dart';

Event _event({
  String title = 'PZ1/01',
  String? sickDayType,
  bool isWorkForOthers = false,
  bool bankHolidayRedundant = false,
  bool withNote = false,
}) {
  return Event(
    id: 'e1',
    title: title,
    startDate: DateTime(2026, 8, 4),
    endDate: DateTime(2026, 8, 4),
    startTime: const TimeOfDay(hour: 5, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
    sickDayType: sickDayType,
    isWorkForOthers: isWorkForOthers,
    bankHolidayRedundant: bankHolidayRedundant,
    notes: withNote ? 'hello' : null,
  );
}

void main() {
  final shiftInfoMap = {
    'E': ShiftInfo('Early', Colors.green),
    'R': ShiftInfo('Rest', Colors.grey),
    'WFO': ShiftInfo('WFO', Colors.orange),
  };

  test('sick day colour wins over shift colour', () {
    final appearance = resolveCalendarDayAppearance(
      date: DateTime(2026, 8, 4),
      events: [_event(sickDayType: 'normal')],
      rosterShift: 'E',
      shiftInfoMap: shiftInfoMap,
      holidays: const [],
      highlightWorkoutDays: false,
      workoutDates: null,
      hasDayNote: false,
      isBankHoliday: false,
      isBankHolidayRedundantMarked: false,
      dayInLieuColor: Colors.teal,
      workoutColor: Colors.brown,
      sickDayColor: (_) => Colors.red,
      themePrimaryColor: Colors.blue,
      schemePrimaryColor: Colors.indigo,
    );

    expect(appearance.cellColor, Colors.red);
    expect(appearance.backgroundColor, Colors.red.withValues(alpha: 0.3));
  });

  test('rest day colour used when holiday falls on rest', () {
    final appearance = resolveCalendarDayAppearance(
      date: DateTime(2026, 8, 4),
      events: const [],
      rosterShift: 'R',
      shiftInfoMap: shiftInfoMap,
      holidays: [
        Holiday(
          id: 'h1',
          startDate: DateTime(2026, 8, 4),
          endDate: DateTime(2026, 8, 4),
          type: 'winter',
        ),
      ],
      highlightWorkoutDays: false,
      workoutDates: null,
      hasDayNote: false,
      isBankHoliday: false,
      isBankHolidayRedundantMarked: false,
      dayInLieuColor: Colors.teal,
      workoutColor: Colors.brown,
      sickDayColor: (_) => null,
      themePrimaryColor: Colors.blue,
      schemePrimaryColor: Colors.indigo,
    );

    expect(appearance.isHoliday, isTrue);
    expect(appearance.cellColor, Colors.grey);
  });

  test('WFO colour used when present and not holiday', () {
    final appearance = resolveCalendarDayAppearance(
      date: DateTime(2026, 8, 4),
      events: [_event(isWorkForOthers: true)],
      rosterShift: 'R',
      shiftInfoMap: shiftInfoMap,
      holidays: const [],
      highlightWorkoutDays: false,
      workoutDates: null,
      hasDayNote: false,
      isBankHoliday: false,
      isBankHolidayRedundantMarked: false,
      dayInLieuColor: Colors.teal,
      workoutColor: Colors.brown,
      sickDayColor: (_) => null,
      themePrimaryColor: Colors.blue,
      schemePrimaryColor: Colors.indigo,
    );

    expect(appearance.cellColor, Colors.orange);
  });

  test('bank holiday redundant and notes flags', () {
    final appearance = resolveCalendarDayAppearance(
      date: DateTime(2026, 8, 4),
      events: [_event(withNote: true, bankHolidayRedundant: true)],
      rosterShift: 'E',
      shiftInfoMap: shiftInfoMap,
      holidays: const [],
      highlightWorkoutDays: false,
      workoutDates: null,
      hasDayNote: false,
      isBankHoliday: true,
      isBankHolidayRedundantMarked: false,
      dayInLieuColor: Colors.teal,
      workoutColor: Colors.brown,
      sickDayColor: (_) => null,
      themePrimaryColor: Colors.blue,
      schemePrimaryColor: Colors.indigo,
    );

    expect(appearance.hasNotes, isTrue);
    expect(appearance.hasBankHolidayRedundant, isTrue);
    expect(appearance.selectedBorderColor, Colors.red);
  });
}
