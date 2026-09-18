import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/statistics/utils/spread_pay.dart';

void main() {
  group('SpreadPay.isSpreadWeekday', () {
    test('is Monday to Friday only', () {
      expect(SpreadPay.isSpreadWeekday(DateTime.monday), isTrue);
      expect(SpreadPay.isSpreadWeekday(DateTime.friday), isTrue);
      expect(SpreadPay.isSpreadWeekday(DateTime.saturday), isFalse);
      expect(SpreadPay.isSpreadWeekday(DateTime.sunday), isFalse);
    });
  });

  group('SpreadPay.overThreshold', () {
    test('returns time over 10 hours', () {
      expect(
        SpreadPay.overThreshold(const Duration(hours: 11, minutes: 20)),
        const Duration(hours: 1, minutes: 20),
      );
    });

    test('returns zero at or under 10 hours', () {
      expect(SpreadPay.overThreshold(const Duration(hours: 10)), Duration.zero);
      expect(
        SpreadPay.overThreshold(const Duration(hours: 9, minutes: 45)),
        Duration.zero,
      );
      expect(SpreadPay.overThreshold(null), Duration.zero);
    });
  });

  group('SpreadPay.hasNoSpreadPay', () {
    test('excludes spare, 22B, Union and Mentor', () {
      expect(SpreadPay.hasNoSpreadPay('SP0400'), isTrue);
      expect(SpreadPay.hasNoSpreadPay('22B/01'), isTrue);
      expect(SpreadPay.hasNoSpreadPay('Union'), isTrue);
      expect(SpreadPay.hasNoSpreadPay('Mentor'), isTrue);
    });

    test('includes zone and Uni duties', () {
      expect(SpreadPay.hasNoSpreadPay('PZ1/09'), isFalse);
      expect(SpreadPay.hasNoSpreadPay('807/18'), isFalse);
    });
  });

  group('SpreadPay.parseCsvDuration', () {
    test('parses HH:MM and HH:MM:SS', () {
      expect(
        SpreadPay.parseCsvDuration('11:20:00'),
        const Duration(hours: 11, minutes: 20),
      );
      expect(
        SpreadPay.parseCsvDuration('08:05'),
        const Duration(hours: 8, minutes: 5),
      );
    });

    test('returns null for empty or nan values', () {
      expect(SpreadPay.parseCsvDuration(null), isNull);
      expect(SpreadPay.parseCsvDuration(''), isNull);
      expect(SpreadPay.parseCsvDuration('nan'), isNull);
    });
  });

  group('SpreadPay.uniSpreadFiles', () {
    test('uses 7-day file first on weekends', () {
      expect(
        SpreadPay.uniSpreadFiles('SAT'),
        ['UNI_7DAYs.csv', 'UNI_M-F.csv'],
      );
      expect(
        SpreadPay.uniSpreadFiles('SUN'),
        ['UNI_7DAYs.csv', 'UNI_M-F.csv'],
      );
    });

    test('uses M-F file first on weekdays', () {
      expect(
        SpreadPay.uniSpreadFiles('M-F'),
        ['UNI_M-F.csv', 'UNI_7DAYs.csv'],
      );
    });
  });
}
