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
