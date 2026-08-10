import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/models/event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Event _event({
    required String title,
    required DateTime date,
    List<String>? assignedDuties,
  }) {
    return Event(
      id: 'e1',
      title: title,
      startDate: date,
      endDate: date,
      startTime: const TimeOfDay(hour: 7, minute: 0),
      endTime: const TimeOfDay(hour: 12, minute: 0),
      assignedDuties: assignedDuties,
    );
  }

  test('22B/01 with Sunday workout 4/07 resolves to Workout', () async {
    // After Route 23/24 changeover, Sunday PZ4/07 is a workout in SUN_ROUTE2324.csv
    final breakTime = await ShiftService.getBreakTime(
      _event(
        title: '22B/01',
        date: DateTime(2026, 8, 9), // Sunday
        assignedDuties: ['4/07'],
      ),
    );

    expect(breakTime?.toLowerCase(), contains('workout'));
  });

  test('22B/01 with PZ4/07 Sunday also resolves to Workout', () async {
    final breakTime = await ShiftService.getBreakTime(
      _event(
        title: '22B/01',
        date: DateTime(2026, 8, 9),
        assignedDuties: ['PZ4/07'],
      ),
    );

    expect(breakTime?.toLowerCase(), contains('workout'));
  });

  test('22B/01 without assigned duties does not invent break info from title',
      () async {
    final breakTime = await ShiftService.getBreakTime(
      _event(
        title: '22B/01',
        date: DateTime(2026, 8, 9),
      ),
    );

    expect(breakTime, isNull);
  });
}
