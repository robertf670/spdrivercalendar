import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone1_shift_roster.dart';

void main() {
  const weeks = [
    ['R', 'R', 'PZ1/65', 'PZ1/65', 'PZ1/65', 'PZ1/65', 'PZ1/57'],
    ['R', 'PZ1/21', 'PZ1/21', 'PZ1/21', 'R', 'PZ1/21', 'PZ1/21'],
    ['PZ1/56', 'PZ1/65', 'R', 'PZ1/41', 'PZ1/41', 'PZ1/41', 'R'],
  ];

  test('pins a duty that appears once on that weekday', () {
    expect(
      Zone1ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 0,
        dutyCode: 'PZ1/56',
      ),
      2,
    );
    expect(
      Zone1ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 0,
        dutyCode: 'PZ1/056',
      ),
      2,
    );
  });

  test('returns null when the duty is not on that weekday', () {
    expect(
      Zone1ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 2,
        dutyCode: 'PZ1/56',
      ),
      isNull,
    );
  });

  test('uses rest days to pick one week when the duty repeats', () {
    const ambiguous = [
      ['R', 'R', 'PZ1/65', 'PZ1/65', 'PZ1/65', 'PZ1/65', 'PZ1/57'],
      ['R', 'PZ1/65', 'PZ1/65', 'PZ1/65', 'R', 'PZ1/65', 'PZ1/65'],
    ];

    expect(
      Zone1ShiftRoster.pinWeekIndex(
        weeks: ambiguous,
        dayIndex: 2,
        dutyCode: 'PZ1/65',
      ),
      isNull,
    );
    expect(
      Zone1ShiftRoster.pinWeekIndex(
        weeks: ambiguous,
        dayIndex: 2,
        dutyCode: 'PZ1/65',
        calendarWeekIsRest: const [
          true,
          true,
          false,
          false,
          false,
          false,
          false,
        ],
      ),
      0,
    );
    expect(
      Zone1ShiftRoster.pinWeekIndex(
        weeks: ambiguous,
        dayIndex: 2,
        dutyCode: 'PZ1/65',
        calendarWeekIsRest: const [
          true,
          false,
          false,
          false,
          true,
          false,
          false,
        ],
      ),
      1,
    );
  });

  test('sheet is the 85-week roster', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(await RosterService.loadZone1ShiftRoster(), isTrue);
    expect(RosterService.zone1ShiftWeeks, hasLength(85));
    expect(RosterService.zone1ShiftWeeks.length, Zone1ShiftRoster.cycleLengthWeeks);
    expect(RosterService.getZone1ShiftDayDuty(0, 2), 'PZ1/65');
    expect(RosterService.getZone1ShiftDayDuty(15, 2), 'PZ1/72');
    expect(RosterService.getZone1ShiftDayDuty(84, 1), 'PZ1/64');
    expect(
      Zone1ShiftRoster.pinWeekIndex(
        weeks: RosterService.zone1ShiftWeeks,
        dayIndex: 2,
        dutyCode: 'PZ1/65',
      ),
      0,
    );
  });
}
