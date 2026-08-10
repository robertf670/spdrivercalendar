import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';

/// Loads available duty codes for the Add Overtime Duty picker.
///
/// Zone duties exclude workout rows (break column `workout` / `nan`).
class OvertimeDutyShiftLoader {
  OvertimeDutyShiftLoader({AssetBundle? bundle})
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

    if (selectedZone == 'Spare') {
      return _spareTimeOptions();
    }
    if (selectedZone == 'Uni/Euro') {
      return _loadUniEuroShifts(dayOfWeek);
    }
    if (selectedZone == 'Bus Check') {
      return _loadBusCheckShifts(dayOfWeek);
    }

    final shifts = await _loadZoneShiftsExcludingWorkouts(
      zoneNumber: zoneNumber,
      dayOfWeekForFilename: dayOfWeekForFilename,
      shiftDate: shiftDate,
    );

    // Preserve prior side-effect used by the calendar OT dialog.
    if (selectedZone == 'Zone 1') {
      await RosterService.loadZone1MFRoster();
    }

    return shifts;
  }

  List<String> _spareTimeOptions() {
    final shiftNumbers = <String>[];
    for (var hour = 4; hour <= 16; hour++) {
      for (var minute = 0; minute < 60; minute += 15) {
        if (hour == 16 && minute > 0) continue;
        final hourStr = hour.toString().padLeft(2, '0');
        final minuteStr = minute.toString().padLeft(2, '0');
        shiftNumbers.add('$hourStr:$minuteStr');
      }
    }
    return shiftNumbers;
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

  Future<List<String>> _loadBusCheckShifts(String dayOfWeek) async {
    try {
      final csv = await _bundle.loadString('assets/buscheck.csv');
      final lines = csv.split('\n');
      final shiftNumbers = <String>[];
      final seenShifts = <String>{};

      final String currentDayType;
      if (dayOfWeek == 'Saturday') {
        currentDayType = 'SAT';
      } else if (dayOfWeek == 'Sunday') {
        currentDayType = 'SUN';
      } else {
        currentDayType = 'MF';
      }

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim().replaceAll('\r', '');
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 2) continue;
        final shiftName = parts[0].trim();
        final shiftDayType = parts[1].trim();
        if (shiftDayType == currentDayType &&
            shiftName.isNotEmpty &&
            seenShifts.add(shiftName)) {
          shiftNumbers.add(shiftName);
        }
      }
      return shiftNumbers;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _loadZoneShiftsExcludingWorkouts({
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
      final lines = csv.split('\n');
      final shiftNumbers = <String>[];
      final seenShifts = <String>{};

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.isEmpty || parts[0].trim().isEmpty) continue;

        final shift = parts[0].trim();
        if (parts.length >= 6) {
          final startBreak = parts[5].trim().toLowerCase();
          if (startBreak == 'workout' || startBreak == 'nan') {
            continue;
          }
        }

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
