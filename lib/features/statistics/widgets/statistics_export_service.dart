import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

/// Service for exporting statistics data to various formats
class StatisticsExportService {
  /// Export statistics to CSV format
  static Future<String?> exportToCSV({
    required Map<String, Duration> workTimeStats,
    required Map<String, int> shiftTypeStats,
    required Map<String, dynamic> breakStats,
    String? filename,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/${filename ?? 'statistics_$timestamp'}.csv');

      final buffer = StringBuffer();
      
      // Write header
      buffer.writeln('Statistics Export - ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('');
      
      // Work Time Statistics
      buffer.writeln('Work Time Statistics');
      buffer.writeln('Period,Hours,Minutes');
      workTimeStats.forEach((key, duration) {
        buffer.writeln('$key,${duration.inHours},${duration.inMinutes.remainder(60)}');
      });
      buffer.writeln('');
      
      // Shift Type Statistics
      buffer.writeln('Shift Type Statistics');
      buffer.writeln('Type,Count');
      shiftTypeStats.forEach((key, value) {
        buffer.writeln('$key,$value');
      });
      buffer.writeln('');
      
      // Break Statistics
      buffer.writeln('Break Statistics');
      buffer.writeln('Period,Total,Full Break,Overtime');
      breakStats.forEach((key, value) {
        if (value is Map) {
          buffer.writeln('$key,${value['total'] ?? 0},${value['fullBreak'] ?? 0},${value['overtime'] ?? 0}');
        }
      });
      
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Export statistics to JSON format
  static Future<String?> exportToJSON({
    required Map<String, Duration> workTimeStats,
    required Map<String, int> shiftTypeStats,
    required Map<String, dynamic> breakStats,
    String? filename,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/${filename ?? 'statistics_$timestamp'}.json');

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

      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Share statistics as text summary
  static String generateTextSummary({
    required Map<String, Duration> workTimeStats,
    required Map<String, int> shiftTypeStats,
    required Map<String, dynamic> breakStats,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('Shift Statistics Summary');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
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

