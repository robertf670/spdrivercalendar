import 'package:flutter/services.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';

/// Secret Jamestown 30hr duties — unlock via settings password.
class JamestownFeatureService {
  static const String password = '2113';
  static const String zoneLabel = 'Jamestown';
  static const String duties30HrCsvAsset = 'assets/jamestown_30hr.csv';
  static const String dutiesMainCsvAsset = 'assets/JAMESTOWN_DUTIES.csv';

  static const List<String> csvSearchOrder = [
    duties30HrCsvAsset,
    dutiesMainCsvAsset,
  ];

  static Future<bool> isEnabled() async {
    return StorageService.getBool(AppConstants.jamestownEnabledKey);
  }

  static Future<void> setEnabled(bool enabled) async {
    await StorageService.saveBool(AppConstants.jamestownEnabledKey, enabled);
  }

  static Future<bool> isPasswordRemembered() async {
    return StorageService.getBool(AppConstants.jamestownUnlockedKey);
  }

  static bool isValidPassword(String input) => input == password;

  /// Saves unlock state on success so the user is not prompted again.
  static Future<bool> unlockWithPassword(String input) async {
    if (!isValidPassword(input)) return false;
    await StorageService.saveBool(AppConstants.jamestownUnlockedKey, true);
    return true;
  }

  /// Shift codes from the secret 30hr roster (811/36 … 811/40).
  static Future<List<String>> load30HrShiftCodes() async {
    return _loadShiftCodesFromAsset(duties30HrCsvAsset);
  }

  /// CSV row parts for an 811/xx shift; 30hr file wins over the main roster.
  static Future<List<String>?> findShiftCsvParts(String shiftCode) async {
    for (final asset in csvSearchOrder) {
      final parts = await _findShiftPartsInAsset(asset, shiftCode);
      if (parts != null) return parts;
    }
    return null;
  }

  static Future<List<String>> _loadShiftCodesFromAsset(String assetPath) async {
    final codes = <String>[];
    final seen = <String>{};
    try {
      final lines = await _loadCsvLines(assetPath);
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim().replaceAll('\r', '');
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.isEmpty) continue;
        final shift = parts[0].trim();
        if (shift.isNotEmpty && shift != 'shift' && seen.add(shift)) {
          codes.add(shift);
        }
      }
    } catch (_) {}
    return codes;
  }

  static Future<List<String>?> _findShiftPartsInAsset(
    String assetPath,
    String shiftCode,
  ) async {
    try {
      final lines = await _loadCsvLines(assetPath);
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim().replaceAll('\r', '');
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length >= 17 && parts[0].trim() == shiftCode) {
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
