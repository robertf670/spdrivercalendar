import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone2_shift_roster.dart';

void main() {
  const weeks = [
    ['R', 'R', 'PZ2/34', 'PZ2/34', 'PZ2/34', 'PZ2/34', 'PZ2/19'],
    ['R', 'PZ2/01', 'PZ2/01', 'PZ2/01', 'R', 'PZ2/12', 'PZ2/04'],
    ['PZ2/17', 'PZ2/34', 'R', 'PZ2/15', 'PZ2/15', 'PZ2/15', 'R'],
  ];

  test('pins a duty that appears once on that weekday', () {
    expect(
      Zone2ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 2,
        dutyCode: 'PZ2/34',
      ),
      0,
    );
  });

  test('returns null when the duty is not on that weekday', () {
    expect(
      Zone2ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 2,
        dutyCode: 'PZ2/15',
      ),
      isNull,
    );
  });

  test('uses rest days to pick one week when the duty repeats', () {
    const ambiguous = [
      ['R', 'R', 'PZ2/99', 'PZ2/99', 'PZ2/99', 'PZ2/99', 'PZ2/01'],
      ['R', 'PZ2/01', 'PZ2/99', 'PZ2/99', 'R', 'PZ2/12', 'PZ2/04'],
    ];

    expect(
      Zone2ShiftRoster.pinWeekIndex(
        weeks: ambiguous,
        dayIndex: 2,
        dutyCode: 'PZ2/99',
      ),
      isNull,
    );
    expect(
      Zone2ShiftRoster.pinWeekIndex(
        weeks: ambiguous,
        dayIndex: 2,
        dutyCode: 'PZ2/99',
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
      Zone2ShiftRoster.pinWeekIndex(
        weeks: ambiguous,
        dayIndex: 2,
        dutyCode: 'PZ2/99',
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
}
