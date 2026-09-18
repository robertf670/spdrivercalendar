import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/services/self_certified_sick_days_service.dart';

void main() {
  group('SelfCertifiedSickDaysService halves', () {
    test('November to April is the first half', () {
      expect(
        SelfCertifiedSickDaysService.getHalfYear(DateTime(2025, 11, 1)),
        SelfCertifiedSickDaysService.halfNovApr,
      );
      expect(
        SelfCertifiedSickDaysService.getHalfYear(DateTime(2026, 4, 30)),
        SelfCertifiedSickDaysService.halfNovApr,
      );
      expect(
        SelfCertifiedSickDaysService.getHalfYear(DateTime(2026, 1, 15)),
        SelfCertifiedSickDaysService.halfNovApr,
      );
    });

    test('May to October is the second half', () {
      expect(
        SelfCertifiedSickDaysService.getHalfYear(DateTime(2026, 5, 1)),
        SelfCertifiedSickDaysService.halfMayOct,
      );
      expect(
        SelfCertifiedSickDaysService.getHalfYear(DateTime(2026, 10, 31)),
        SelfCertifiedSickDaysService.halfMayOct,
      );
    });
  });

  group('SelfCertifiedSickDaysService bonus year', () {
    test('ends on 31 October, with Nov–Dec in the next year', () {
      expect(
        SelfCertifiedSickDaysService.bonusYearFor(DateTime(2025, 11, 1)),
        2026,
      );
      expect(
        SelfCertifiedSickDaysService.bonusYearFor(DateTime(2026, 4, 30)),
        2026,
      );
      expect(
        SelfCertifiedSickDaysService.bonusYearFor(DateTime(2026, 10, 31)),
        2026,
      );
      expect(
        SelfCertifiedSickDaysService.bonusYearFor(DateTime(2026, 11, 1)),
        2027,
      );
    });

    test('Nov–Apr range crosses the calendar year', () {
      final range = SelfCertifiedSickDaysService.rangeForHalf(
        2026,
        SelfCertifiedSickDaysService.halfNovApr,
      );
      expect(range.start, DateTime(2025, 11, 1));
      expect(range.end, DateTime(2026, 4, 30));
    });

    test('May–Oct range stays in the bonus year', () {
      final range = SelfCertifiedSickDaysService.rangeForHalf(
        2026,
        SelfCertifiedSickDaysService.halfMayOct,
      );
      expect(range.start, DateTime(2026, 5, 1));
      expect(range.end, DateTime(2026, 10, 31));
    });

    test('bonus year is November through October inclusive', () {
      final range = SelfCertifiedSickDaysService.rangeForBonusYear(2026);
      expect(range.start, DateTime(2025, 11, 1));
      expect(range.end, DateTime(2026, 10, 31));
      expect(
        SelfCertifiedSickDaysService.isInRange(
          DateTime(2025, 11, 1),
          range.start,
          range.end,
        ),
        isTrue,
      );
      expect(
        SelfCertifiedSickDaysService.isInRange(
          DateTime(2026, 10, 31),
          range.start,
          range.end,
        ),
        isTrue,
      );
      expect(
        SelfCertifiedSickDaysService.isInRange(
          DateTime(2026, 11, 1),
          range.start,
          range.end,
        ),
        isFalse,
      );
    });
  });

  group('SelfCertifiedSickDaysService limit copy', () {
    test('avoids "the May–October" wording', () {
      expect(
        SelfCertifiedSickDaysService.limitWarningMessage(
          halfYearName: 'May–October',
          halfYearReached: true,
          yearReached: false,
        ),
        'You have already used 2 self-certified days in May–October.',
      );
      expect(
        SelfCertifiedSickDaysService.limitWarningMessage(
          halfYearName: 'May–October',
          halfYearReached: true,
          yearReached: true,
        ),
        'You have already used 2 self-certified days in May–October and 4 for the bonus year.',
      );
      expect(
        SelfCertifiedSickDaysService.limitWarningMessage(
          halfYearName: 'November–April',
          halfYearReached: false,
          yearReached: true,
        ),
        'You have already used 4 self-certified days for the bonus year.',
      );
    });
  });
}
