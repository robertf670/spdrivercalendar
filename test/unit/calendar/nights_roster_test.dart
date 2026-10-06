import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/nights_roster.dart';

void main() {
  final week1Sunday = DateTime(2024, 4, 7);

  test('week 1 from the nights sheet rests Sunday and Friday', () {
    expect(NightsRoster.restDaysLabel(0), 'Sunday, Friday');
    expect(
      NightsRoster.shiftForDate(
        date: week1Sunday,
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      ),
      'R',
    );
    expect(
      NightsRoster.shiftForDate(
        date: DateTime(2024, 4, 12),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      ),
      'R',
    );
    expect(
      NightsRoster.shiftForDate(
        date: DateTime(2024, 4, 8),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      ),
      'W',
    );
  });

  test('four-week cycle matches the sheet and repeats at week 5', () {
    expect(
      NightsRoster.weeks[NightsRoster.weekIndexForDate(
        date: DateTime(2024, 4, 14),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      )],
      'WWWRRWW',
    );
    expect(
      NightsRoster.weeks[NightsRoster.weekIndexForDate(
        date: DateTime(2024, 4, 21),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      )],
      'WWRWWWR',
    );
    expect(
      NightsRoster.weeks[NightsRoster.weekIndexForDate(
        date: DateTime(2024, 4, 28),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      )],
      'RRWWWWW',
    );
    expect(
      NightsRoster.weekIndexForDate(
        date: DateTime(2024, 5, 5),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      ),
      0,
    );
    expect(
      NightsRoster.weeks[NightsRoster.weekIndexForDate(
        date: DateTime(2024, 6, 23),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      )],
      'RRWWWWW',
    );
  });

  test('Saturday rest of week 3 joins Sunday-Monday rest of week 4', () {
    expect(
      NightsRoster.shiftForDate(
        date: DateTime(2024, 4, 27),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      ),
      'R',
    );
    expect(
      NightsRoster.shiftForDate(
        date: DateTime(2024, 4, 28),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      ),
      'R',
    );
    expect(
      NightsRoster.shiftForDate(
        date: DateTime(2024, 4, 29),
        anchorSunday: week1Sunday,
        anchorWeekIndex: 0,
      ),
      'R',
    );
  });
}
