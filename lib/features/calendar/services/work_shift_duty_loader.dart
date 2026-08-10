import 'package:flutter/services.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

/// Loads available duty codes for the Add Work Shift picker.
///
/// Unlike overtime loading, zone duties include workout rows.
class WorkShiftDutyLoader {
  WorkShiftDutyLoader({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<List<String>> loadShiftNumbers({
    required String selectedZone,
    required DateTime shiftDate,
    required bool donnybrook1Enabled,
  }) async {
    if (selectedZone == '22B/01' ||
        selectedZone == 'Union' ||
        selectedZone == 'Mentor') {
      return const [];
    }

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

    List<String> shiftNumbers;
    if (selectedZone == 'Spare') {
      shiftNumbers = _spareTimeOptions();
    } else if (selectedZone == 'Uni/Euro') {
      shiftNumbers = await _loadUniEuroShifts(dayOfWeek);
    } else if (selectedZone == 'Bus Check') {
      shiftNumbers = await _loadBusCheckShifts(dayOfWeek);
    } else if (selectedZone == DonnybrookFeatureService.zoneLabel) {
      shiftNumbers =
          await DonnybrookFeatureService.loadShiftCodesForDate(shiftDate);
    } else if (selectedZone == JamestownFeatureService.zoneLabel) {
      if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
        shiftNumbers = [];
      } else {
        shiftNumbers = await JamestownFeatureService.load30HrShiftCodes();
      }
    } else if (selectedZone == 'Jamestown Road') {
      shiftNumbers = await _loadJamestownRoadShifts(dayOfWeek);
    } else if (selectedZone == 'Training') {
      shiftNumbers = await _loadTrainingShifts(
        dayOfWeek: dayOfWeek,
        donnybrook1Enabled: donnybrook1Enabled,
      );
    } else {
      shiftNumbers = await _loadZoneShiftsIncludingWorkouts(
        zoneNumber: zoneNumber,
        dayOfWeekForFilename: dayOfWeekForFilename,
        shiftDate: shiftDate,
      );
    }

    // Preserve prior roster preload side-effects used by auto-fill checkboxes.
    if (selectedZone == 'Zone 1') {
      await RosterService.loadZone1MFRoster();
      await RosterService.loadZone1ShiftRoster();
    }
    if (selectedZone == 'Zone 3') {
      await RosterService.loadZone3ShiftRoster();
    }

    return shiftNumbers;
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

  Future<List<String>> _loadJamestownRoadShifts(String dayOfWeek) async {
    if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
      return [];
    }
    try {
      final csv = await _bundle.loadString('assets/JAMESTOWN_DUTIES.csv');
      final lines = csv.split('\n');
      final shiftNumbers = <String>[];
      final seenShifts = <String>{};
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim().replaceAll('\r', '');
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

  Future<List<String>> _loadTrainingShifts({
    required String dayOfWeek,
    required bool donnybrook1Enabled,
  }) async {
    final shiftNumbers = <String>[];
    final seenShifts = <String>{};
    try {
      final csv = await _bundle.loadString('assets/training_duties.csv');
      final lines = csv.split('\n');
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim().replaceAll('\r', '');
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.isEmpty) continue;
        final shift = parts[0].trim();
        if (donnybrook1Enabled && shift != 'CPC') {
          continue;
        }
        if (shift.contains('EA Type Training')) {
          continue;
        }
        if (shift == 'Route 13 Training' && dayOfWeek == 'Sunday') {
          continue;
        }
        if (shift.isNotEmpty && seenShifts.add(shift)) {
          shiftNumbers.add(shift);
        }
      }
    } catch (_) {
      // Preserve silent CSV failure behaviour from the calendar screen.
    }
    if (!shiftNumbers.contains(TrainingConstants.customTrainingShiftOption)) {
      shiftNumbers.add(TrainingConstants.customTrainingShiftOption);
    }
    return shiftNumbers;
  }

  Future<List<String>> _loadZoneShiftsIncludingWorkouts({
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
