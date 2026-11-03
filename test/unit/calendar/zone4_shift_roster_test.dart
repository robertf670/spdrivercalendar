import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone4_shift_roster.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await RosterService.loadZone4ShiftRoster();
  });

  test('loads the 45-week cycle', () async {
    final loaded = await RosterService.loadZone4ShiftRoster();
    expect(loaded, isTrue);
    expect(RosterService.zone4RosterComplete, isTrue);
    expect(RosterService.zone4ShiftWeeks, hasLength(45));
    expect(RosterService.getZone4ShiftDayDuty(0, 0), 'PZ4/05');
    expect(RosterService.getZone4ShiftDayDuty(0, 1), 'PZ4/26');
    expect(RosterService.getZone4ShiftDayDuty(0, 3), 'R');
    expect(RosterService.getZone4ShiftDayDuty(1, 6), 'PZ4/26');
    expect(RosterService.getZone4ShiftDayDuty(10, 0), 'PZ4/09');
    expect(RosterService.getZone4ShiftDayDuty(10, 4), 'PZ4/17');
    expect(RosterService.getZone4ShiftDayDuty(11, 0), 'R');
    expect(RosterService.getZone4ShiftDayDuty(11, 2), 'PZ4/39');
    expect(RosterService.getZone4ShiftDayDuty(11, 6), 'PZ4/29');
    expect(RosterService.getZone4ShiftDayDuty(23, 0), 'PZ4/11');
    expect(RosterService.getZone4ShiftDayDuty(23, 1), 'PZ4/38');
    expect(RosterService.getZone4ShiftDayDuty(24, 1), 'PZ4/14');
    expect(RosterService.getZone4ShiftDayDuty(24, 6), 'PZ4/01');
    expect(RosterService.getZone4ShiftDayDuty(35, 0), 'PZ4/04');
    expect(RosterService.getZone4ShiftDayDuty(35, 1), 'PZ4/25');
    expect(RosterService.getZone4ShiftDayDuty(36, 2), 'PZ4/30');
    expect(RosterService.getZone4ShiftDayDuty(36, 6), 'PZ4/22');
    expect(RosterService.getZone4ShiftDayDuty(44, 1), 'PZ4/10');
    expect(RosterService.getZone4ShiftDayDuty(44, 6), 'PZ4/08');
  });

  test('pins PZ4/05 on Sunday as week 1 and treats PZ4/5 as the same duty', () {
    final weeks = RosterService.zone4ShiftWeeks;
    expect(
      Zone4ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 0,
        dutyCode: 'PZ4/05',
      ),
      0,
    );
    expect(
      Zone4ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 0,
        dutyCode: 'PZ4/5',
      ),
      0,
    );
  });

  test('PZ4/37 on a Sunday and Monday rest week is week 7', () {
    const sunMonRest = [true, true, false, false, false, false, false];
    final weeks = RosterService.zone4ShiftWeeks;

    expect(
      Zone4ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 2,
        dutyCode: 'PZ4/37',
        calendarWeekIsRest: sunMonRest,
      ),
      6,
    );
    expect(
      Zone4ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 1,
        dutyCode: 'PZ4/37',
        calendarWeekIsRest: sunMonRest,
      ),
      isNull,
    );
  });

  test('does not wrap an unfinished roster back to week 1', () {
    expect(
      Zone4ShiftRoster.filledWeekIndex(
        pinnedWeek: 10,
        offset: 1,
        length: 11,
        complete: false,
      ),
      isNull,
    );
    expect(
      Zone4ShiftRoster.filledWeekIndex(
        pinnedWeek: 44,
        offset: 1,
        length: 45,
        complete: true,
      ),
      0,
    );
  });
}
