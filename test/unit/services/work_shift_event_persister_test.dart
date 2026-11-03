import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/work_shift_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/work_shift_event_persister.dart';
import 'package:spdrivercalendar/features/calendar/utils/jamestown_road.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone2_shift_roster.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone4_shift_roster.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';

void main() {
  WorkShiftDialogSelection selection({
    required String zone,
    required String shift,
    Map<int, bool>? selectedDays,
    bool repeatDutyThisWeek = false,
    bool repeatUniEuroThisWeek = false,
    Map<int, bool>? uniEuroSelectedDays,
    bool fillNext35Weeks = false,
    bool fillNextZone4Weeks = false,
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
      fillNext35Weeks: fillNext35Weeks,
      fillNextZone4Weeks: fillNextZone4Weeks,
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

  test('custom spare minute becomes SP title and 8h38 end time', () async {
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
      selection: selection(zone: 'Spare', shift: '19:07'),
      isMFMarkedIn: false,
      isShiftMarkedIn: false,
      markedInZone: '',
      jamestownEnabled: false,
    );

    expect(result.status, WorkShiftPersistStatus.success);
    expect(created.single.title, 'SP1907');
    expect(created.single.startTime, const TimeOfDay(hour: 19, minute: 7));
    expect(created.single.endTime, const TimeOfDay(hour: 3, minute: 45));
    expect(created.single.endDate, DateTime(2026, 8, 5));
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

  test('repeats Zone 2 duty when marked in on Zone 2', () async {
    final created = <Event>[];
    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shift, date) async => {
        'startTime': const TimeOfDay(hour: 5, minute: 37),
        'endTime': const TimeOfDay(hour: 13, minute: 2),
        'isNextDay': false,
      },
      addEvent: (event) async {
        created.add(event);
      },
      eventsForDay: (_) => const [],
      bankHolidayForDate: (_) => null,
      now: () => DateTime(2026, 10, 12, 12),
    );

    // Monday 12 Oct 2026; repeat Tue of that week.
    final result = await persister.persist(
      shiftDate: DateTime(2026, 10, 12),
      selection: selection(
        zone: 'Route 13',
        shift: '13/01',
        repeatDutyThisWeek: true,
        selectedDays: const {1: true, 2: true},
      ),
      isMFMarkedIn: false,
      isShiftMarkedIn: true,
      markedInZone: 'Route 13',
      jamestownEnabled: false,
    );

    expect(result.status, WorkShiftPersistStatus.success);
    expect(created.map((e) => e.title).toSet(), {'13/01'});
    expect(created.map((e) => e.startDate.day).toList(), [12, 13]);
  });

  test('nights repeats a duty onto other weekday work days', () async {
    final created = <Event>[];
    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shift, date) async => {
        'startTime': const TimeOfDay(hour: 22, minute: 0),
        'endTime': const TimeOfDay(hour: 6, minute: 0),
        'isNextDay': true,
      },
      addEvent: (event) async {
        created.add(event);
      },
      eventsForDay: (_) => const [],
      bankHolidayForDate: (_) => BankHoliday(
        name: 'Still work',
        date: DateTime(2024, 4, 8),
      ),
      now: () => DateTime(2024, 4, 9, 12),
    );

    final result = await persister.persist(
      shiftDate: DateTime(2024, 4, 9),
      selection: selection(
        zone: 'Zone 1',
        shift: 'PZ1/91',
        repeatDutyThisWeek: true,
        selectedDays: const {1: true, 2: true, 6: true},
      ),
      isMFMarkedIn: false,
      isShiftMarkedIn: false,
      markedInZone: '',
      jamestownEnabled: false,
      isNightsRoster: true,
    );

    expect(result.status, WorkShiftPersistStatus.success);
    expect(created.map((e) => e.title).toSet(), {'PZ1/91'});
    expect(created.map((e) => e.startDate.day).toList(), [9, 8]);
  });

  test('repeats a Jamestown Road duty across selected weekdays', () async {
    final created = <Event>[];
    final lookedUp = <DateTime>[];
    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shift, date) async {
        lookedUp.add(date);
        expect(zone, JamestownRoad.zoneLabel);
        expect(shift, '311/01');
        return {
          'startTime': const TimeOfDay(hour: 5, minute: 37),
          'endTime': const TimeOfDay(hour: 18, minute: 34),
          'isNextDay': false,
        };
      },
      addEvent: (event) async {
        created.add(event);
      },
      eventsForDay: (_) => const [],
      bankHolidayForDate: (_) => null,
      now: () => DateTime(2026, 10, 12, 12),
    );

    final result = await persister.persist(
      shiftDate: DateTime(2026, 10, 12),
      selection: selection(
        zone: JamestownRoad.zoneLabel,
        shift: '311/01',
        repeatDutyThisWeek: true,
        selectedDays: const {1: true, 2: true, 3: true, 4: true, 5: true},
      ),
      isMFMarkedIn: true,
      isShiftMarkedIn: false,
      markedInZone: JamestownRoad.zoneLabel,
      jamestownEnabled: false,
    );

    expect(result.status, WorkShiftPersistStatus.success);
    expect(created.map((e) => e.title).toSet(), {'311/01'});
    expect(created.map((e) => e.startDate.day).toList(), [12, 13, 14, 15, 16]);
    expect(lookedUp.length, greaterThan(1));
  });

  test('does not fill Zone 2 roster unless the Dev Menu toggle is on', () async {
    final created = <Event>[];
    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shift, date) async => {
        'startTime': const TimeOfDay(hour: 19, minute: 12),
        'endTime': const TimeOfDay(hour: 0, minute: 45),
        'isNextDay': true,
      },
      addEvent: (event) async {
        created.add(event);
      },
      eventsForDay: (_) => const [],
      bankHolidayForDate: (_) => null,
      now: () => DateTime(2026, 10, 13, 12),
    );

    await persister.persist(
      shiftDate: DateTime(2026, 10, 13),
      selection: selection(
        zone: 'Route 13',
        shift: '13/33',
        fillNext35Weeks: true,
      ),
      isMFMarkedIn: false,
      isShiftMarkedIn: true,
      markedInZone: 'Route 13',
      jamestownEnabled: false,
    );

    expect(created, hasLength(1));
    expect(created.single.rosterFillSource, isNull);
  });

  test('fills 35 weeks of Zone 2 duties, skips BH and sat-service weekdays',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await RosterService.loadZone2ShiftRoster(), isTrue);

    final created = <Event>[];
    final occupied = Event(
      id: 'existing',
      title: 'Keep me',
      startDate: DateTime(2026, 10, 15),
      endDate: DateTime(2026, 10, 15),
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 16, minute: 0),
    );
    final christmas = BankHoliday(
      name: 'Christmas Day',
      date: DateTime(2026, 12, 25),
    );
    final lookups = <({DateTime date, String duty})>[];

    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shift, date) async {
        lookups.add((date: date, duty: shift));
        return {
          'startTime': const TimeOfDay(hour: 6, minute: 0),
          'endTime': const TimeOfDay(hour: 14, minute: 0),
          'isNextDay': false,
        };
      },
      addEvent: (event) async {
        created.add(event);
      },
      eventsForDay: (date) {
        if (date.year == 2026 && date.month == 10 && date.day == 15) {
          return [occupied];
        }
        return const [];
      },
      bankHolidayForDate: (date) {
        if (date.year == christmas.date.year &&
            date.month == christmas.date.month &&
            date.day == christmas.date.day) {
          return christmas;
        }
        return null;
      },
      now: () => DateTime(2026, 10, 13, 12),
    );

    final result = await persister.persist(
      shiftDate: DateTime(2026, 10, 13),
      selection: selection(
        zone: 'Route 13',
        shift: '13/33',
        fillNext35Weeks: true,
      ),
      isMFMarkedIn: false,
      isShiftMarkedIn: true,
      markedInZone: 'Route 13',
      jamestownEnabled: false,
      zone2RosterEnabled: true,
    );

    expect(result.status, WorkShiftPersistStatus.success);
    expect(created.length, greaterThan(100));
    expect(
      created.every((e) => e.rosterFillSource == Zone2ShiftRoster.sourceTag),
      isTrue,
    );

    Event? onDay(int year, int month, int day) {
      final matches = created.where((e) =>
          e.startDate.year == year &&
          e.startDate.month == month &&
          e.startDate.day == day);
      return matches.isEmpty ? null : matches.single;
    }

    expect(onDay(2026, 10, 13)?.title, '13/33');
    expect(onDay(2026, 10, 14)?.title, '13/33');
    expect(onDay(2026, 10, 11), isNull);
    expect(onDay(2026, 10, 12), isNull);
    expect(onDay(2026, 10, 15), isNull);
    expect(onDay(2026, 10, 17)?.title, '13/20');
    expect(onDay(2026, 12, 24), isNull);
    expect(onDay(2026, 12, 25), isNull);

    expect(
      lookups.any((lookup) =>
          lookup.date.year == 2026 &&
          lookup.date.month == 10 &&
          lookup.date.day == 17 &&
          lookup.duty == '13/20'),
      isTrue,
    );
  });

  test('Zone 2 fill keeps calendar dates across the October DST fallback',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await RosterService.loadZone2ShiftRoster(), isTrue);

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
      now: () => DateTime(2026, 10, 18, 12),
    );

    await persister.persist(
      shiftDate: DateTime(2026, 10, 18),
      selection: selection(
        zone: 'Route 13',
        shift: '13/04',
        fillNext35Weeks: true,
      ),
      isMFMarkedIn: false,
      isShiftMarkedIn: true,
      markedInZone: 'Route 13',
      jamestownEnabled: false,
      zone2RosterEnabled: true,
    );

    Event? onDay(int year, int month, int day) {
      final matches = created.where((e) =>
          e.startDate.year == year &&
          e.startDate.month == month &&
          e.startDate.day == day);
      return matches.isEmpty ? null : matches.single;
    }

    expect(onDay(2026, 10, 18)?.title, '13/04');
    expect(onDay(2026, 10, 24), isNull);
    expect(onDay(2026, 10, 25), isNull);
    expect(onDay(2026, 10, 26), isNull);
    expect(onDay(2026, 10, 27)?.title, '13/24');
    expect(onDay(2026, 10, 30)?.title, '13/24');
    expect(onDay(2026, 10, 31)?.title, '13/22');
    expect(onDay(2026, 11, 1), isNull);
  });

  test('Zone 4 fill writes the loaded weeks and does not wrap', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await RosterService.loadZone4ShiftRoster(), isTrue);

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
      now: () => DateTime(2026, 8, 23, 12),
    );

    final result = await persister.persist(
      shiftDate: DateTime(2026, 8, 23),
      selection: selection(
        zone: 'Zone 4',
        shift: 'PZ4/05',
        fillNextZone4Weeks: true,
      ),
      isMFMarkedIn: false,
      isShiftMarkedIn: true,
      markedInZone: 'Zone 4',
      jamestownEnabled: false,
      zone4RosterEnabled: true,
    );

    expect(result.status, WorkShiftPersistStatus.success);

    Event? onDay(int year, int month, int day) {
      final matches = created.where((e) =>
          e.startDate.year == year &&
          e.startDate.month == month &&
          e.startDate.day == day);
      return matches.isEmpty ? null : matches.single;
    }

    expect(onDay(2026, 8, 24)?.title, 'PZ4/26');
    expect(onDay(2026, 8, 25)?.title, 'PZ4/26');
    expect(onDay(2026, 8, 26), isNull);
    expect(onDay(2026, 8, 28)?.title, 'PZ4/10');
    expect(onDay(2026, 9, 1)?.title, 'PZ4/35');
    expect(onDay(2026, 11, 1)?.title, 'PZ4/09');
    expect(onDay(2026, 11, 2)?.title, 'PZ4/20');
    expect(onDay(2026, 11, 6)?.title, 'PZ4/02');
    expect(onDay(2026, 11, 8), isNull);
    expect(onDay(2026, 11, 10)?.title, 'PZ4/39');
    expect(onDay(2027, 2, 1)?.title, 'PZ4/38');
    expect(onDay(2027, 2, 7), isNull);
    expect(onDay(2027, 2, 8)?.title, 'PZ4/14');
    expect(onDay(2027, 4, 26)?.title, 'PZ4/25');
    expect(onDay(2027, 5, 2), isNull);
    expect(onDay(2027, 5, 4)?.title, 'PZ4/30');
    expect(onDay(2027, 6, 28)?.title, 'PZ4/10');
    expect(onDay(2027, 7, 3)?.title, 'PZ4/08');
    expect(onDay(2027, 7, 4), isNull);
    expect(
      created.where((e) => e.id.contains('_z4_')).every(
            (e) => e.rosterFillSource == Zone4ShiftRoster.sourceTag,
          ),
      isTrue,
    );
  });

  test('Zone 4 fill wraps from the last week back to week 1', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await RosterService.loadZone4ShiftRoster(), isTrue);

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
      now: () => DateTime(2027, 6, 28, 12),
    );

    await persister.persist(
      shiftDate: DateTime(2027, 6, 28),
      selection: selection(
        zone: 'Zone 4',
        shift: 'PZ4/10',
        fillNextZone4Weeks: true,
      ),
      isMFMarkedIn: false,
      isShiftMarkedIn: true,
      markedInZone: 'Zone 4',
      jamestownEnabled: false,
      zone4RosterEnabled: true,
    );

    Event? onDay(int year, int month, int day) {
      final matches = created.where((e) =>
          e.startDate.year == year &&
          e.startDate.month == month &&
          e.startDate.day == day);
      return matches.isEmpty ? null : matches.single;
    }

    expect(onDay(2027, 6, 29)?.title, 'PZ4/10');
    expect(onDay(2027, 7, 3)?.title, 'PZ4/08');
    expect(onDay(2027, 7, 4)?.title, 'PZ4/05');
    expect(onDay(2027, 7, 5)?.title, 'PZ4/26');
  });
}
