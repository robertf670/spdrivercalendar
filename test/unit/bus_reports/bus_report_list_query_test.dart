import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_list_query.dart';

void main() {
  final now = DateTime(2026, 9, 26);

  BusReport report({
    required String bus,
    required String date,
    DateTime? updatedAt,
  }) {
    return BusReport(
      id: '${bus}_$date',
      userId: 'user-1',
      busNumber: bus,
      date: date,
      slot: BusReportSlot.full,
      category: BusReportCategory.heater,
      updatedAt: updatedAt,
    );
  }

  test('orders newest date first and shows a readable date', () {
    final rows = BusReportListQuery.apply(
      reports: [
        report(bus: 'SG1', date: '2026-09-20'),
        report(bus: 'PA150', date: '2026-09-26'),
        report(bus: 'SG2', date: '2026-09-24'),
      ],
      search: '',
      filter: BusReportDateFilter.all,
      now: now,
    );

    expect(rows.map((row) => row.busNumber), ['PA150', 'SG2', 'SG1']);
    expect(BusReportListQuery.displayDate('2026-09-26'), '26 Sep 2026');
  });

  test('7 day filter keeps today through 7 days ago', () {
    final rows = BusReportListQuery.apply(
      reports: [
        report(bus: 'IN', date: '2026-09-19'),
        report(bus: 'OUT', date: '2026-09-18'),
        report(bus: 'TODAY', date: '2026-09-26'),
      ],
      search: '',
      filter: BusReportDateFilter.days7,
      now: now,
    );

    expect(rows.map((row) => row.busNumber), ['TODAY', 'IN']);
  });

  test('custom range keeps a whole month like August', () {
    final rows = BusReportListQuery.apply(
      reports: [
        report(bus: 'JUL', date: '2026-07-31'),
        report(bus: 'AUG1', date: '2026-08-01'),
        report(bus: 'AUG31', date: '2026-08-31'),
        report(bus: 'SEP', date: '2026-09-01'),
      ],
      search: '',
      filter: BusReportDateFilter.range,
      rangeStart: DateTime(2026, 8, 1),
      rangeEnd: DateTime(2026, 8, 31),
      now: now,
    );

    expect(rows.map((row) => row.busNumber), ['AUG31', 'AUG1']);
    expect(
      BusReportListQuery.displayRange(
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 31),
      ),
      '1 Aug – 31 Aug 2026',
    );
  });

  test('search still filters by bus number', () {
    final rows = BusReportListQuery.apply(
      reports: [
        report(bus: 'PA150', date: '2026-09-26'),
        report(bus: 'SG33', date: '2026-09-26'),
      ],
      search: 'pa 150',
      filter: BusReportDateFilter.all,
      now: now,
    );

    expect(rows.map((row) => row.busNumber), ['PA150']);
  });
}
