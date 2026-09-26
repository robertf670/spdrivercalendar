import 'package:spdrivercalendar/features/bus_reports/bus_report.dart';

enum BusReportDateFilter { days7, days30, all, range }

class BusReportListQuery {
  BusReportListQuery._();

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static DateTime? parseDate(String date) => DateTime.tryParse(date);

  static String displayDate(String date) {
    final parsed = parseDate(date);
    if (parsed == null) return date;
    return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
  }

  static String displayRange(DateTime start, DateTime end) {
    final sameYear = start.year == end.year;
    final left =
        '${start.day} ${_months[start.month - 1]}${sameYear ? '' : ' ${start.year}'}';
    return '$left – ${end.day} ${_months[end.month - 1]} ${end.year}';
  }

  static bool inWindow(
    String date,
    BusReportDateFilter filter, {
    DateTime? now,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    if (filter == BusReportDateFilter.all) return true;
    final parsed = parseDate(date);
    if (parsed == null) return false;
    final duty = DateTime(parsed.year, parsed.month, parsed.day);

    if (filter == BusReportDateFilter.range) {
      if (rangeStart == null || rangeEnd == null) return true;
      final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
      return !duty.isBefore(start) && !duty.isAfter(end);
    }

    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);
    final days = filter == BusReportDateFilter.days7 ? 7 : 30;
    final start = today.subtract(Duration(days: days));
    return !duty.isBefore(start);
  }

  static List<BusReport> apply({
    required List<BusReport> reports,
    required String search,
    required BusReportDateFilter filter,
    DateTime? now,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    final query = search.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    final next = reports.where((report) {
      if (query.isNotEmpty && !report.busNumber.contains(query)) {
        return false;
      }
      return inWindow(
        report.date,
        filter,
        now: now,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
    }).toList();

    next.sort((a, b) {
      final date = b.date.compareTo(a.date);
      if (date != 0) return date;
      final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return next;
  }
}
