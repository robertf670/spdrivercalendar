import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone2_shift_roster.dart';

void main() {
  const weeks = [
    ['R', 'R', '13/34', '13/34', '13/34', '13/34', '13/19'],
    ['R', '13/01', '13/01', '13/01', 'R', '13/12', '13/04'],
    ['13/17', '13/34', 'R', '13/15', '13/15', '13/15', 'R'],
  ];

  test('pins a duty that appears once on that weekday', () {
    expect(
      Zone2ShiftRoster.pinWeekIndex(
        weeks: weeks,
        dayIndex: 2,
        dutyCode: '13/34',
      ),
      0,
    );
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
        dutyCode: '13/15',
      ),
      isNull,
    );
  });

  test('uses rest days to pick one week when the duty repeats', () {
    const ambiguous = [
      ['R', 'R', '13/99', '13/99', '13/99', '13/99', '13/01'],
      ['R', '13/01', '13/99', '13/99', 'R', '13/12', '13/04'],
    ];

    expect(
      Zone2ShiftRoster.pinWeekIndex(
        weeks: ambiguous,
        dayIndex: 2,
        dutyCode: '13/99',
      ),
      isNull,
    );
    expect(
      Zone2ShiftRoster.pinWeekIndex(
        weeks: ambiguous,
        dayIndex: 2,
        dutyCode: '13/99',
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
        dutyCode: '13/99',
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
