import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/work_shift_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/work_shift_event_persister.dart';
import 'package:spdrivercalendar/models/event.dart';

void main() {
  WorkShiftDialogSelection selection({
    required String zone,
    required String shift,
    Map<int, bool>? selectedDays,
    bool repeatDutyThisWeek = false,
    bool repeatUniEuroThisWeek = false,
    Map<int, bool>? uniEuroSelectedDays,
  }) {
    return WorkShiftDialogSelection(
      selectedZone: zone,
      selectedShiftNumber: shift,
      repeatUniEuroThisWeek: repeatUniEuroThisWeek,
      uniEuroSelectedDays: uniEuroSelectedDays ?? const {},
      repeatDutyThisWeek: repeatDutyThisWeek,
      selectedDays: selectedDays ?? const {},
      fillNext12Weeks: false,
      fillNext15Weeks: false,
      fillNext10Weeks: false,
    );
  }

  test('creates fixed-time Union event', () async {
    final created = <Event>[];
    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shift, date) async => null,
      addEvent: (event) async {
        created.add(event);
      },
      eventsForDay: (_) => const [],
      bankHolidayForDate: (_) => null,
      now: () => DateTime(2026, 8, 4, 12),
    );

    final result = await persister.persist(
      shiftDate: DateTime(2026, 8, 4),
      selection: selection(zone: 'Union', shift: ''),
      isMFMarkedIn: false,
      isShiftMarkedIn: false,
      markedInZone: '',
      jamestownEnabled: false,
    );

    expect(result.status, WorkShiftPersistStatus.success);
    expect(created, hasLength(1));
    expect(created.single.title, 'Union');
    expect(created.single.startTime, const TimeOfDay(hour: 9, minute: 0));
    expect(created.single.endTime, const TimeOfDay(hour: 15, minute: 0));
  });

  test('spare shift builds SP title and 8h38 end time', () async {
    final created = <Event>[];
    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shift, date) async => null,
      addEvent: (event) async {
        created.add(event);
      },
      eventsForDay: (_) => const [],
      bankHolidayForDate: (_) => null,
      now: () => DateTime(2026, 8, 4, 12),
    );

    final result = await persister.persist(
      shiftDate: DateTime(2026, 8, 4),
      selection: selection(zone: 'Spare', shift: '05:15'),
      isMFMarkedIn: false,
      isShiftMarkedIn: false,
      markedInZone: '',
      jamestownEnabled: false,
    );

    expect(result.status, WorkShiftPersistStatus.success);
    expect(created.single.title, 'SP0515');
    expect(created.single.startTime, const TimeOfDay(hour: 5, minute: 15));
    expect(created.single.endTime, const TimeOfDay(hour: 13, minute: 53));
  });

  test('missing custom training times returns dedicated status', () async {
    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shift, date) async => null,
      addEvent: (_) async {},
      eventsForDay: (_) => const [],
      bankHolidayForDate: (_) => null,
    );

    final result = await persister.persist(
      shiftDate: DateTime(2026, 8, 4),
      selection: selection(
        zone: 'Training',
        shift: TrainingConstants.customTrainingShiftOption,
      ),
      isMFMarkedIn: false,
      isShiftMarkedIn: false,
      markedInZone: '',
      jamestownEnabled: false,
    );

    expect(result.status, WorkShiftPersistStatus.missingCustomTrainingTimes);
  });

  test('repeats duty across selected weekdays', () async {
    final created = <Event>[];
    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shift, date) async => {
        'startTime': const TimeOfDay(hour: 6, minute: 0),
        'endTime': const TimeOfDay(hour: 14, minute: 0),
        'isNextDay': false,
      },
      addEvent: (event) async {
        created.add(event);
      },
      eventsForDay: (_) => const [],
      bankHolidayForDate: (_) => null,
      now: () => DateTime(2026, 8, 4, 12),
    );

    // Tuesday 4 Aug 2026; repeat Mon+Wed of that week.
    final result = await persister.persist(
      shiftDate: DateTime(2026, 8, 4),
      selection: selection(
        zone: 'Zone 1',
        shift: 'PZ1/01',
        repeatDutyThisWeek: true,
        selectedDays: const {1: true, 2: true, 3: true},
      ),
      isMFMarkedIn: false,
      isShiftMarkedIn: true,
      markedInZone: 'Zone 1',
      jamestownEnabled: false,
    );

    expect(result.status, WorkShiftPersistStatus.success);
    expect(created.map((e) => e.startDate.day).toList(), [4, 3, 5]);
  });
}
