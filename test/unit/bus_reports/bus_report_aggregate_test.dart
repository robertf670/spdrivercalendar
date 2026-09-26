import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_aggregate.dart';

void main() {
  final now = DateTime(2026, 9, 26, 12);

  BusReportSummaryData empty() {
    return const BusReportSummaryData(busNumber: 'SG123');
  }

  group('BusReportSummaryData.applyReport', () {
    test('adds, edits note without changing count, and decrements on remove', () {
      final added = empty().applyReport(
        newCategory: 'Seat',
        reportedAt: now,
      );
      expect(added.reportCount, 1);
      expect(added.categoryCounts['Seat'], 1);

      final editedSame = added.applyReport(
        oldCategory: 'Seat',
        newCategory: 'Seat',
        reportedAt: now,
      );
      expect(editedSame.reportCount, 1);
      expect(editedSame.categoryCounts['Seat'], 1);

      final removed = editedSame.removeReport('Seat');
      expect(removed.reportCount, 0);
      expect(removed.categoryCounts, isEmpty);
      expect(removed.lastReportedAt, isNull);
    });

    test('two users on the same bus increment the count', () {
      final first = empty().applyReport(newCategory: 'Seat', reportedAt: now);
      final second = first.applyReport(
        newCategory: 'Heater',
        reportedAt: now,
      );
      expect(second.reportCount, 2);
      expect(second.topCategories, ['Heater', 'Seat']);
    });
  });

  group('assign warning', () {
    test('recent report warns and removing the last one clears it', () {
      final recent = empty().applyReport(
        newCategory: 'Seat',
        reportedAt: now.subtract(const Duration(days: 6)),
      );
      expect(recent.shouldWarnOnAssign(now: now), isTrue);

      final old = empty().applyReport(
        newCategory: 'Seat',
        reportedAt: now.subtract(const Duration(days: 8)),
      );
      expect(old.shouldWarnOnAssign(now: now), isFalse);

      final cleared = recent.removeReport('Seat');
      expect(cleared.shouldWarnOnAssign(now: now), isFalse);
    });
  });
}
