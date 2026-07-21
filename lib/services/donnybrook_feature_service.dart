import 'package:flutter/services.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';

class DonnybrookFeatureService {
  static const String menuLabel = 'Donnybrook 1';
  static const String zoneLabel = 'DB Z1';
  static const String shiftPrefix = 'DZ1/';

  static const String weekdayCsvAsset = 'assets/DB_Z1_M-F.csv';
  static const String saturdayCsvAsset = 'assets/DB_Z1_SAT.csv';
  static const String sundayCsvAsset = 'assets/DB_Z1_SUN.csv';

  static Future<bool> isEnabled() {
    return StorageService.getBool(AppConstants.donnybrook1EnabledKey);
  }

  static Future<void> setEnabled(bool enabled) async {
    await StorageService.saveBool(
      AppConstants.donnybrook1EnabledKey,
      enabled,
    );
    if (enabled) {
      await StorageService.saveBool(AppConstants.jamestownEnabledKey, false);
    }
  }

  static String resolveDutyCsvAsset(DateTime date) {
    final dayOfWeek = RosterService.getDayOfWeek(date);
    final isBankHoliday =
        ShiftService.bankHolidays.any((holiday) => holiday.matchesDate(date));

    if (RosterService.isSaturdayService(date) ||
        dayOfWeek == 'Saturday') {
      return saturdayCsvAsset;
    }
    if (isBankHoliday || dayOfWeek == 'Sunday') {
      return sundayCsvAsset;
    }
    return weekdayCsvAsset;
  }

  static Future<List<String>> loadShiftCodesForDate(DateTime date) async {
    final lines = await _loadCsvLines(resolveDutyCsvAsset(date));
    final codes = <String>[];
    final seen = <String>{};

    for (var index = 1; index < lines.length; index++) {
      final line = lines[index].trim().replaceAll('\r', '');
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.isEmpty) continue;
      final shiftCode = parts[0].trim();
      if (shiftCode.isNotEmpty &&
          shiftCode != 'shift' &&
          seen.add(shiftCode)) {
        codes.add(shiftCode);
      }
    }

    return codes;
  }

  static Future<List<String>?> findShiftCsvParts(
    String shiftCode,
    DateTime date,
  ) async {
    try {
      final lines = await _loadCsvLines(resolveDutyCsvAsset(date));
      for (var index = 1; index < lines.length; index++) {
        final line = lines[index].trim().replaceAll('\r', '');
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 16 && parts[0].trim() == shiftCode) {
          return parts;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<List<String>> _loadCsvLines(String assetPath) async {
    final csv = await rootBundle.loadString(assetPath);
    return csv.split('\n');
  }
}
