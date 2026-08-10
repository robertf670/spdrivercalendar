import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/navigation/calendar_feature_navigation.dart';
import 'package:spdrivercalendar/features/calendar/utils/calendar_month_navigation.dart';

void main() {
  test('firstDayOfMonth normalizes to day 1', () {
    expect(firstDayOfMonth(DateTime(2026, 8, 19)), DateTime(2026, 8, 1));
  });

  test('clamps 31 January to 28 February in non-leap year', () {
    expect(
      navigateCalendarMonth(DateTime(2026, 1, 31), 1),
      DateTime(2026, 2, 28),
    );
  });

  test('clamps 31 January to 29 February in leap year', () {
    expect(
      navigateCalendarMonth(DateTime(2024, 1, 31), 1),
      DateTime(2024, 2, 29),
    );
  });

  test('rolls year forward from December', () {
    expect(
      navigateCalendarMonth(DateTime(2026, 12, 15), 1),
      DateTime(2027, 1, 15),
    );
  });

  test('rolls year backward from January', () {
    expect(
      navigateCalendarMonth(DateTime(2026, 1, 15), -1),
      DateTime(2025, 12, 15),
    );
  });
}
