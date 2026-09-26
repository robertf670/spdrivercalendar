import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';

class BusReportSummaryData {
  const BusReportSummaryData({
    required this.busNumber,
    this.reportCount = 0,
    this.categoryCounts = const {},
    this.lastReportedAt,
  });

  final String busNumber;
  final int reportCount;
  final Map<String, int> categoryCounts;
  final DateTime? lastReportedAt;

  List<String> get topCategories {
    final entries = categoryCounts.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        if (count != 0) return count;
        return a.key.compareTo(b.key);
      });
    return entries.map((entry) => entry.key).toList();
  }

  bool shouldWarnOnAssign({DateTime? now}) {
    return BusReportKey.isRecent(lastReportedAt, now: now);
  }

  BusReportSummaryData applyReport({
    String? oldCategory,
    required String newCategory,
    required DateTime reportedAt,
  }) {
    var count = reportCount;
    final next = Map<String, int>.from(categoryCounts);

    if (oldCategory == null) {
      count += 1;
      next[newCategory] = (next[newCategory] ?? 0) + 1;
    } else if (oldCategory != newCategory) {
      next[oldCategory] = (next[oldCategory] ?? 1) - 1;
      if ((next[oldCategory] ?? 0) <= 0) next.remove(oldCategory);
      next[newCategory] = (next[newCategory] ?? 0) + 1;
    }

    return BusReportSummaryData(
      busNumber: busNumber,
      reportCount: count,
      categoryCounts: next,
      lastReportedAt: reportedAt,
    );
  }

  BusReportSummaryData removeReport(String category, {DateTime? nextLastReportedAt}) {
    if (reportCount <= 0) return this;
    final next = Map<String, int>.from(categoryCounts);
    next[category] = (next[category] ?? 1) - 1;
    if ((next[category] ?? 0) <= 0) next.remove(category);
    final count = reportCount - 1;
    return BusReportSummaryData(
      busNumber: busNumber,
      reportCount: count,
      categoryCounts: next,
      lastReportedAt: count == 0 ? null : (nextLastReportedAt ?? lastReportedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'reportCount': reportCount,
      'categoryCounts': categoryCounts,
      'lastReportedAt': lastReportedAt?.toIso8601String(),
    };
  }

  factory BusReportSummaryData.fromMap(Map<String, dynamic> map) {
    final rawCounts = map['categoryCounts'];
    final counts = <String, int>{};
    if (rawCounts is Map) {
      rawCounts.forEach((key, value) {
        final count = _asInt(value);
        if (count > 0) counts[key.toString()] = count;
      });
    }
    return BusReportSummaryData(
      busNumber: map['busNumber'] as String? ?? '',
      reportCount: _asInt(map['reportCount']),
      categoryCounts: counts,
      lastReportedAt: _asDate(map['lastReportedAt']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
