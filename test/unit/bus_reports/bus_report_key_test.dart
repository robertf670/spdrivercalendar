import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';

void main() {
  group('BusReportKey.normalizeBusNumber', () {
    test('keeps letters and digits and drops spaces or hyphens', () {
      expect(BusReportKey.normalizeBusNumber('sg 123'), 'SG123');
      expect(BusReportKey.normalizeBusNumber('SG123'), 'SG123');
      expect(BusReportKey.normalizeBusNumber(' SG-123 '), 'SG123');
    });

    test('rejects empty or junk', () {
      expect(BusReportKey.normalizeBusNumber(''), isNull);
      expect(BusReportKey.normalizeBusNumber('   '), isNull);
      expect(BusReportKey.normalizeBusNumber('12'), isNull);
      expect(BusReportKey.normalizeBusNumber('BUS'), isNull);
      expect(BusReportKey.normalizeBusNumber('!!!'), isNull);
    });
  });

  group('BusReportTarget', () {
    test('same bus first and second half are two reports', () {
      const first = BusReportTarget(
        busNumber: 'SG123',
        date: '2026-09-26',
        slot: BusReportSlot.first,
      );
      const second = BusReportTarget(
        busNumber: 'SG123',
        date: '2026-09-26',
        slot: BusReportSlot.second,
      );
      expect(first.summaryId, second.summaryId);
      expect(first.reportDocId('user-1'), 'user-1_SG123_2026-09-26_1');
      expect(second.reportDocId('user-1'), 'user-1_SG123_2026-09-26_2');
      expect(first.reportDocId('user-1'), isNot(second.reportDocId('user-1')));
    });

    test('duty suffix picks the half slot', () {
      expect(BusReportSlot.forDutyCode('PZ1/39A'), BusReportSlot.first);
      expect(BusReportSlot.forDutyCode('PZ1/39B'), BusReportSlot.second);
      expect(BusReportSlot.forDutyCode('PZ1/39'), BusReportSlot.full);
    });
  });

  group('BusReportKey.write gate', () {
    test('settings off hides Report', () {
      expect(
        BusReportKey.canShowWriteAction(settingsEnabled: false),
        isFalse,
      );
      expect(
        BusReportKey.canShowWriteAction(settingsEnabled: true),
        isTrue,
      );
    });

    test('requires a category or a note', () {
      expect(BusReportKey.canSave(category: null, note: ''), isFalse);
      expect(
        BusReportKey.canSave(category: BusReportCategory.seat, note: ''),
        isTrue,
      );
      expect(BusReportKey.canSave(category: null, note: 'Lopsided seat'), isTrue);
    });
  });

  group('BusReportKey.isRecent', () {
    test('warns inside 7 days and not after 8', () {
      final now = DateTime(2026, 9, 26, 12);
      expect(
        BusReportKey.isRecent(now.subtract(const Duration(days: 6)), now: now),
        isTrue,
      );
      expect(
        BusReportKey.isRecent(now.subtract(const Duration(days: 8)), now: now),
        isFalse,
      );
    });
  });
}
