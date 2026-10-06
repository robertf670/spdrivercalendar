import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/roster_shift_lookup.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';

void main() {
  test('M-F marked-in returns W on weekdays and R on weekends', () {
    expect(
      rosterShiftForDate(
        date: DateTime(2026, 8, 4), // Tuesday
        startDate: DateTime(2026, 1, 4),
        startWeek: 0,
        markedInEnabled: true,
        markedInStatus: 'M-F',
        bankHolidayForDate: (_) => null,
      ),
      'W',
    );
    expect(
      rosterShiftForDate(
        date: DateTime(2026, 8, 8), // Saturday
        startDate: DateTime(2026, 1, 4),
        startWeek: 0,
        markedInEnabled: true,
        markedInStatus: 'M-F',
        bankHolidayForDate: (_) => null,
      ),
      'R',
    );
  });

  test('M-F marked-in treats bank holidays as rest', () {
    expect(
      rosterShiftForDate(
        date: DateTime(2026, 8, 4),
        startDate: DateTime(2026, 1, 4),
        startWeek: 0,
        markedInEnabled: true,
        markedInStatus: 'M-F',
        bankHolidayForDate: (_) => BankHoliday(
          name: 'Test',
          date: DateTime(2026, 8, 4),
        ),
      ),
      'R',
    );
  });

  test('4 Day spare roster returns W Friday–Monday without marked-in', () {
    expect(
      rosterShiftForDate(
        date: DateTime(2026, 10, 16), // Friday
        startDate: DateTime(2026, 1, 4),
        startWeek: 0,
        markedInEnabled: false,
        markedInStatus: '4 Day',
        bankHolidayForDate: (_) => null,
      ),
      'W',
    );
    expect(
      rosterShiftForDate(
        date: DateTime(2026, 10, 18), // Sunday
        startDate: DateTime(2026, 1, 4),
        startWeek: 0,
        markedInEnabled: false,
        markedInStatus: '4 Day',
        bankHolidayForDate: (_) => null,
      ),
      'W',
    );
    expect(
      rosterShiftForDate(
        date: DateTime(2026, 10, 20), // Tuesday
        startDate: DateTime(2026, 1, 4),
        startWeek: 0,
        markedInEnabled: false,
        markedInStatus: '4 Day',
        bankHolidayForDate: (_) => null,
      ),
      'R',
    );
  });

  test('Nights follows the 4-week cycle from this week rest days', () {
    final week1Sunday = DateTime(2024, 4, 7);
    expect(
      rosterShiftForDate(
        date: DateTime(2024, 4, 12),
        startDate: DateTime(2026, 1, 4),
        startWeek: 0,
        markedInEnabled: false,
        markedInStatus: 'Nights',
        bankHolidayForDate: (_) => BankHoliday(
          name: 'Ignored',
          date: DateTime(2024, 4, 12),
        ),
        nightsAnchorSunday: week1Sunday,
        nightsWeekIndex: 0,
      ),
      'R',
    );
    expect(
      rosterShiftForDate(
        date: DateTime(2024, 4, 17),
        startDate: DateTime(2026, 1, 4),
        startWeek: 0,
        markedInEnabled: false,
        markedInStatus: 'Nights',
        bankHolidayForDate: (_) => null,
        nightsAnchorSunday: week1Sunday,
        nightsWeekIndex: 0,
      ),
      'R',
    );
    expect(
      rosterShiftForDate(
        date: DateTime(2024, 4, 8),
        startDate: DateTime(2026, 1, 4),
        startWeek: 0,
        markedInEnabled: false,
        markedInStatus: 'Nights',
        bankHolidayForDate: (_) => BankHoliday(
          name: 'Work night',
          date: DateTime(2024, 4, 8),
        ),
        nightsAnchorSunday: week1Sunday,
        nightsWeekIndex: 0,
      ),
      'W',
    );
  });

  test('isRosteredRestDay excludes swapped work', () {
    expect(
      isRosteredRestDay(shift: 'R', isSwappedWork: true),
      isFalse,
    );
    expect(
      isRosteredRestDay(shift: 'R', isSwappedWork: false),
      isTrue,
    );
  });
}
