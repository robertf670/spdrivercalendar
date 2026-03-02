import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Web implementation: exports via Share instead of file system.
class StatisticsExportService {
  static Future<String?> exportToCSV({
    required Map<String, Duration> workTimeStats,
    required Map<String, int> shiftTypeStats,
    required Map<String, dynamic> breakStats,
    String? filename,
  }) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln(
          'Statistics Export - ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('');
      buffer.writeln('Work Time Statistics');
      buffer.writeln('Period,Hours,Minutes');
      workTimeStats.forEach((key, duration) {
        buffer.writeln(
            '$key,${duration.inHours},${duration.inMinutes.remainder(60)}');
      });
      buffer.writeln('');
      buffer.writeln('Shift Type Statistics');
      buffer.writeln('Type,Count');
      shiftTypeStats.forEach((key, value) {
        buffer.writeln('$key,$value');
      });
      buffer.writeln('');
      buffer.writeln('Break Statistics');
      buffer.writeln('Period,Total,Full Break,Overtime');
      breakStats.forEach((key, value) {
        if (value is Map) {
          buffer.writeln(
              '$key,${value['total'] ?? 0},${value['fullBreak'] ?? 0},${value['overtime'] ?? 0}');
        }
      });

      final csv = buffer.toString();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await Share.shareXFiles(
        [
          XFile.fromData(
            utf8.encode(csv),
            name: filename ?? 'statistics_$timestamp.csv',
            mimeType: 'text/csv',
          )
        ],
        subject: 'Statistics Export',
      );
      return 'shared';
    } catch (e) {
      return null;
    }
  }

  static Future<String?> exportToJSON({
    required Map<String, Duration> workTimeStats,
    required Map<String, int> shiftTypeStats,
    required Map<String, dynamic> breakStats,
    String? filename,
  }) async {
    try {
      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'workTimeStats': workTimeStats.map((k, v) => MapEntry(k, {
              'hours': v.inHours,
              'minutes': v.inMinutes.remainder(60),
              'totalMinutes': v.inMinutes,
            })),
        'shiftTypeStats': shiftTypeStats,
        'breakStats': breakStats,
      };

      final json = const JsonEncoder.withIndent('  ').convert(data);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await Share.shareXFiles(
        [
          XFile.fromData(
            utf8.encode(json),
            name: filename ?? 'statistics_$timestamp.json',
            mimeType: 'application/json',
          )
        ],
        subject: 'Statistics Export',
      );
      return 'shared';
    } catch (e) {
      return null;
    }
  }

  static String generateTextSummary({
    required Map<String, Duration> workTimeStats,
    required Map<String, int> shiftTypeStats,
    required Map<String, dynamic> breakStats,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Shift Statistics Summary');
    buffer.writeln(
        'Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('Work Time Statistics:');
    workTimeStats.forEach((key, duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      buffer.writeln('  $key: ${hours}h ${minutes}m');
    });
    buffer.writeln('');
    buffer.writeln('Shift Type Statistics:');
    shiftTypeStats.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    buffer.writeln('');
    buffer.writeln('Break Statistics:');
    breakStats.forEach((key, value) {
      if (value is Map) {
        buffer.writeln('  $key:');
        buffer.writeln('    Total: ${value['total'] ?? 0}');
        buffer.writeln('    Full Break: ${value['fullBreak'] ?? 0}');
        buffer.writeln('    Overtime: ${value['overtime'] ?? 0}');
      }
    });
    return buffer.toString();
  }
}
