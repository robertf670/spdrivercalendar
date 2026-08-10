import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_schedule_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';

void main() {
  setUp(RosterScheduleService.resetForTesting);

  group('RosterService shift patterns', () {
    test('wraps the week number through the five-week cycle', () {
      expect(
        RosterService.getShiftPattern(7, '1'),
        RosterService.getShiftPattern(2, '1'),
      );
    });

    test('returns the shift on the roster anchor date', () {
      final startDate = DateTime.utc(2025, 1, 5);

      expect(
        RosterService.getShiftForDate(startDate, startDate, 0),
        'L',
      );
    });

    test('advances to the next roster week after seven days', () {
      final startDate = DateTime.utc(2025, 1, 5);

      expect(
        RosterService.getShiftForDate(
          DateTime.utc(2025, 1, 12),
          startDate,
          0,
        ),
        'R',
      );
    });

    test('calculates the previous roster week before the anchor', () {
      final startDate = DateTime.utc(2025, 1, 5);

      expect(
        RosterService.getShiftForDate(
          DateTime.utc(2024, 12, 29),
          startDate,
          0,
        ),
        'R',
      );
    });

    test('keeps the cycle correct across a year boundary', () {
      final startDate = DateTime.utc(2024, 12, 29);

      expect(
        RosterService.getShiftForDate(
          DateTime.utc(2025, 1, 5),
          startDate,
          0,
        ),
        'R',
      );
    });
  });

  group('RosterService rest days and service dates', () {
    test('returns the rest-day labels for a valid week', () {
      expect(
        RosterService.getRestDaysForWeek(0),
        'Tuesday, Saturday',
      );
    });

    test('returns Invalid for an out-of-range week', () {
      expect(RosterService.getRestDaysForWeek(-1), 'Invalid');
      expect(RosterService.getRestDaysForWeek(99), 'Invalid');
    });

    test('uses Saturday service on configured weekday dates only', () {
      expect(RosterService.isSaturdayService(DateTime(2025, 12, 24)), isTrue);
      expect(RosterService.isSaturdayService(DateTime(2023, 12, 24)), isFalse);
      expect(RosterService.getDayOfWeek(DateTime(2025, 12, 24)), 'Saturday');
    });
  });

  group('RosterService shift filenames', () {
    test('switches Zone 4 to route 23/24 files on the changeover date', () {
      expect(
        RosterService.getShiftFilename(
          '4',
          'Monday',
          DateTime(2025, 10, 18),
        ),
        'M-F_DUTIES_PZ4.csv',
      );
      expect(
        RosterService.getShiftFilename(
          '4',
          'Monday',
          DateTime(2025, 10, 19),
        ),
        'M-F_ROUTE2324.csv',
      );
    });

    test('switches Zone 4 to Aug 2026 bill files from 23 Aug 2026', () {
      expect(
        RosterService.getShiftFilename(
          '4',
          'SUN',
          DateTime(2026, 8, 22),
        ),
        'SUN_ROUTE2324.csv',
      );
      expect(
        RosterService.getShiftFilename(
          '4',
          'SUN',
          DateTime(2026, 8, 23),
        ),
        'SUN_ROUTE2324_20260823.csv',
      );
      expect(
        RosterService.getShiftFilename(
          '4',
          'M-F',
          DateTime(2026, 8, 24),
        ),
        'M-F_ROUTE2324_20260823.csv',
      );
      expect(
        RosterService.getShiftFilename(
          '4',
          'SAT',
          DateTime(2026, 8, 29),
        ),
        'SAT_ROUTE2324_20260823.csv',
      );
    });
  });
}
