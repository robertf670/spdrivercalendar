import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/overtime_duty_event_persister.dart';
import 'package:spdrivercalendar/models/event.dart';

void main() {
  test('spare overtime uses 4-hour window and half title', () async {
    Event? created;
    final persister = OvertimeDutyEventPersister(
      lookupShiftTimes: (zone, shift, date, {bool isOvertimeShift = false}) async =>
          null,
      addEvent: (event) async {
        created = event;
      },
      idFactory: () => 'ot-1',
    );

    final result = await persister.persist(
      overtimeHalfType: 'A',
      shiftDate: DateTime(2026, 8, 4),
      selectedZone: 'Spare',
      selectedShiftNumber: '10:00',
    );

    expect(result.status, OvertimeDutyPersistStatus.success);
    expect(created, isNotNull);
    expect(created!.id, 'ot-1');
    expect(created!.title, '10:00A (OT)');
    // Spare window is 4h; half A with no break uses the midpoint.
    expect(created!.startTime, const TimeOfDay(hour: 10, minute: 0));
    expect(created!.endTime, const TimeOfDay(hour: 12, minute: 0));
  });

  test('first half uses break start from lookup', () async {
    Event? created;
    final persister = OvertimeDutyEventPersister(
      lookupShiftTimes: (zone, shift, date, {bool isOvertimeShift = false}) async =>
          {
        'startTime': const TimeOfDay(hour: 8, minute: 0),
        'endTime': const TimeOfDay(hour: 16, minute: 0),
        'breakStartTime': const TimeOfDay(hour: 12, minute: 0),
        'breakEndTime': const TimeOfDay(hour: 12, minute: 40),
      },
      addEvent: (event) async {
        created = event;
      },
      idFactory: () => 'ot-2',
      loadCsv: (_) async => '',
    );

    final result = await persister.persist(
      overtimeHalfType: 'A',
      shiftDate: DateTime(2026, 8, 4),
      selectedZone: 'Zone 1',
      selectedShiftNumber: 'PZ1/01',
    );

    expect(result.status, OvertimeDutyPersistStatus.success);
    expect(created!.startTime, const TimeOfDay(hour: 8, minute: 0));
    expect(created!.endTime, const TimeOfDay(hour: 12, minute: 0));
  });

  test('returns unavailable when lookup yields null', () async {
    final persister = OvertimeDutyEventPersister(
      lookupShiftTimes: (zone, shift, date, {bool isOvertimeShift = false}) async =>
          null,
      addEvent: (_) async {},
      loadCsv: (_) async => '',
    );

    final result = await persister.persist(
      overtimeHalfType: 'B',
      shiftDate: DateTime(2026, 8, 4),
      selectedZone: 'Zone 2',
      selectedShiftNumber: 'PZ2/01',
    );

    expect(result.status, OvertimeDutyPersistStatus.shiftTimesUnavailable);
  });
}
