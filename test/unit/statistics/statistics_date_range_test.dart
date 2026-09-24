import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/statistics/utils/statistics_date_range.dart';

void main() {
  group('StatisticsDateRange weeks', () {
    test('Thursday 24 Sep 2026 is Sunday 20 to Saturday 26', () {
      final week = StatisticsDateRange.thisWeek(DateTime(2026, 9, 24, 10));
      expect(week.start, DateTime(2026, 9, 20));
      expect(week.end, DateTime(2026, 9, 26));
    });

    test('includes Saturday when the event date is UTC', () {
      final week = StatisticsDateRange.thisWeek(DateTime(2026, 9, 24, 10));
      expect(
        StatisticsDateRange.isOnOrBetween(
          DateTime.utc(2026, 9, 26),
          week.start,
          week.end,
        ),
        isTrue,
      );
    });

    test('last week is the previous Sunday to Saturday', () {
      final week = StatisticsDateRange.lastWeek(DateTime(2026, 9, 24, 10));
      expect(week.start, DateTime(2026, 9, 13));
      expect(week.end, DateTime(2026, 9, 19));
    });
  });

  group('StatisticsDateRange months', () {
    test('this month does not include the 1st of next month', () {
      final month = StatisticsDateRange.thisMonth(DateTime(2026, 9, 24));
      expect(month.start, DateTime(2026, 9, 1));
      expect(month.endExclusive, DateTime(2026, 10, 1));
      expect(
        StatisticsDateRange.isInHalfOpen(
          DateTime(2026, 9, 30),
          month.start,
          month.endExclusive,
        ),
        isTrue,
      );
      expect(
        StatisticsDateRange.isInHalfOpen(
          DateTime(2026, 10, 1),
          month.start,
          month.endExclusive,
        ),
        isFalse,
      );
    });

    test('last month in January is December of the previous year', () {
      final month = StatisticsDateRange.lastMonth(DateTime(2026, 1, 15));
      expect(month.start, DateTime(2025, 12, 1));
      expect(month.endExclusive, DateTime(2026, 1, 1));
    });
  });
}
