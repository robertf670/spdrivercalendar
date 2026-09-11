import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';

class BillsLoadResult {
  const BillsLoadResult({
    required this.duties,
    this.isComingSoon = false,
    this.error,
  });

  final List<BillDuty> duties;
  final bool isComingSoon;
  final String? error;
}

/// Loads and parses zone / Uni-Euro bill CSVs for the Bills screen.
class BillsCsvService {
  BillsCsvService._();

  static Future<BillsLoadResult> load({
    required String zone,
    required String dayType,
    DateTime? eraDate,
  }) async {
    if (zone == 'Zone 2') {
      return const BillsLoadResult(duties: [], isComingSoon: true);
    }

    try {
      final lines = await _loadLines(
        zone: zone,
        dayType: dayType,
        eraDate: eraDate ?? DateTime.now(),
      );
      if (lines.isEmpty) {
        return const BillsLoadResult(
          duties: [],
          error: 'CSV file is empty',
        );
      }

      return BillsLoadResult(duties: parseLines(lines));
    } catch (e) {
      return BillsLoadResult(
        duties: const [],
        error: 'Error loading data: $e',
      );
    }
  }

  static List<BillDuty> parseCsv(String csv) => parseLines(csv.split('\n'));

  static List<BillDuty> parseLines(List<String> lines) {
    if (lines.isEmpty) return const [];
    final headers = _parseCsvLine(lines.first)
        .map((header) => header.trim().toLowerCase())
        .toList();
    if (headers.isEmpty) return const [];

    final duties = <BillDuty>[];
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final cells = _parseCsvLine(lines[i]);
      final duty = _fromRow(headers, cells);
      if (duty != null) duties.add(duty);
    }
    return duties;
  }

  /// Merges UNI_7DAYs and UNI_M-F. Headers from the 7-day file;
  /// first occurrence of each shift wins.
  static List<String> mergeUniEuroCsvLines(String csv7Days, String csvMF) {
    final lines7Days = csv7Days.split('\n');
    final linesMF = csvMF.split('\n');
    if (lines7Days.isEmpty) return linesMF;
    if (linesMF.isEmpty) return lines7Days;

    final result = <String>[lines7Days[0]];
    final seenShifts = <String>{};

    void addRows(List<String> fileLines) {
      for (var i = 1; i < fileLines.length; i++) {
        if (fileLines[i].trim().isEmpty) continue;
        final parts = _parseCsvLine(fileLines[i]);
        if (parts.isEmpty) continue;
        if (!seenShifts.add(parts[0])) continue;
        result.add(fileLines[i]);
      }
    }

    addRows(lines7Days);
    addRows(linesMF);
    return result;
  }

  static Future<List<String>> _loadLines({
    required String zone,
    required String dayType,
    required DateTime eraDate,
  }) async {
    if (zone == 'Uni/Euro') {
      final csv7Days = await rootBundle.loadString('assets/UNI_7DAYs.csv');
      if (dayType == 'M-F') {
        final csvMF = await rootBundle.loadString('assets/UNI_M-F.csv');
        return mergeUniEuroCsvLines(csv7Days, csvMF);
      }
      return csv7Days.split('\n');
    }

    final zoneNumber = zone.replaceAll('Zone ', '');
    final filename = RosterService.getBrowseShiftFilename(
      zoneNumber,
      dayType,
      eraDate,
    );
    final csvData = await rootBundle.loadString('assets/$filename');
    return csvData.split('\n');
  }

  static BillDuty? _fromRow(List<String> headers, List<String> cells) {
    String col(String name) {
      final index = headers.indexOf(name);
      if (index < 0 || index >= cells.length) return '';
      return cells[index].trim();
    }

    final shift = col('shift');
    if (shift.isEmpty || shift.toLowerCase() == 'nan') return null;

    final routes = col('routes');
    return BillDuty(
      shift: shift,
      dutyNumber: col('duty'),
      report: col('report'),
      depart: col('depart'),
      location: col('location'),
      startBreak: col('startbreak'),
      startBreakLocation: col('startbreaklocation'),
      breakReport: col('breakreport'),
      finishBreak: col('finishbreak'),
      finishBreakLocation: col('finishbreaklocation'),
      finish: col('finish'),
      finishLocation: col('finishlocation'),
      signOff: col('signoff'),
      spread: col('spread'),
      work: col('work'),
      relief: col('relief'),
      routes: routes.isEmpty ? null : routes,
    );
  }

  static List<String> _parseCsvLine(String line) {
    return line.split(',').map((cell) => cell.trim()).toList();
  }
}
