import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';

/// Loads available duty codes for the Work For Others picker.
class WorkForOthersShiftLoader {
  WorkForOthersShiftLoader({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const List<String> zoneOptions = [
    'Zone 1',
    'Zone 2',
    'Zone 3',
    'Zone 4',
    'Uni/Euro',
  ];

  Future<List<String>> loadShiftNumbers({
    required String selectedZone,
    required DateTime shiftDate,
  }) async {
    final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
    final zoneNumber = selectedZone.replaceAll('Zone ', '');

    final String dayOfWeekForFilename;
    if (dayOfWeek == 'Saturday') {
      dayOfWeekForFilename = 'SAT';
    } else if (dayOfWeek == 'Sunday') {
      dayOfWeekForFilename = 'SUN';
    } else {
      dayOfWeekForFilename = 'M-F';
    }

    if (selectedZone == 'Uni/Euro') {
      return _loadUniEuroShifts(dayOfWeek);
    }

    return _loadZoneShifts(
      zoneNumber: zoneNumber,
      dayOfWeekForFilename: dayOfWeekForFilename,
      shiftDate: shiftDate,
    );
  }

  Future<List<String>> _loadUniEuroShifts(String dayOfWeek) async {
    final combinedShifts = <String>[];

    try {
      final csv = await _bundle.loadString('assets/UNI_7DAYs.csv');
      combinedShifts.addAll(_dutyCodesFromCsv(csv));
    } catch (_) {
      // Preserve silent CSV failure behaviour from the calendar screen.
    }

    if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {
      try {
        final csv = await _bundle.loadString('assets/UNI_M-F.csv');
        combinedShifts.addAll(_dutyCodesFromCsv(csv));
      } catch (_) {
        // Preserve silent CSV failure behaviour from the calendar screen.
      }
    }

    final uniqueShifts = <String>[];
    final seenShifts = <String>{};
    for (final shift in combinedShifts) {
      if (seenShifts.add(shift)) {
        uniqueShifts.add(shift);
      }
    }
    return uniqueShifts;
  }

  Future<List<String>> _loadZoneShifts({
    required String zoneNumber,
    required String dayOfWeekForFilename,
    required DateTime shiftDate,
  }) async {
    final filename = RosterService.getShiftFilename(
      zoneNumber,
      dayOfWeekForFilename,
      shiftDate,
    );

    try {
      final csv = await _bundle.loadString('assets/$filename');
      final shiftNumbers = <String>[];
      final seenShifts = <String>{};
      final lines = csv.split('\n');

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.isEmpty || parts[0].trim().isEmpty) continue;

        final shift = parts[0].trim();
        if (shift != 'shift' && seenShifts.add(shift)) {
          shiftNumbers.add(shift);
        }
      }
      return shiftNumbers;
    } catch (_) {
      return [];
    }
  }

  List<String> _dutyCodesFromCsv(String csv) {
    final codes = <String>[];
    final lines = csv.split('\n');
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final parts = lines[i].split(',');
      if (parts.isNotEmpty) {
        codes.add(parts[0]);
      }
    }
    return codes;
  }
}
