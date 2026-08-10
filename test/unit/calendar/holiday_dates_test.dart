import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_dates.dart';

void main() {
  test('returns all Sundays for a non-leap year', () {
    final sundays = getSundaysForYear(2026);
    expect(sundays.first, DateTime(2026, 1, 4));
    expect(sundays.last, DateTime(2026, 12, 27));
    expect(sundays.every((d) => d.weekday == DateTime.sunday), isTrue);
    expect(sundays.length, 52);
  });

  test('includes a Sunday on Jan 1 when the year starts on Sunday', () {
    final sundays = getSundaysForYear(2023);
    expect(sundays.first, DateTime(2023, 1, 1));
  });
}
