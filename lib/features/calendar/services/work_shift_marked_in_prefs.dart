import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';

/// Marked-in preferences needed by the Add Work Shift dialog.
class WorkShiftMarkedInPrefs {
  const WorkShiftMarkedInPrefs({
    required this.isMFMarkedIn,
    required this.isShiftMarkedIn,
    required this.markedInZone,
  });

  final bool isMFMarkedIn;
  final bool isShiftMarkedIn;
  final String markedInZone;

  static const empty = WorkShiftMarkedInPrefs(
    isMFMarkedIn: false,
    isShiftMarkedIn: false,
    markedInZone: '',
  );
}

/// Loads marked-in flags used when opening Add Work Shift.
class WorkShiftMarkedInPrefsLoader {
  WorkShiftMarkedInPrefsLoader({
    Future<bool> Function(String key, {bool defaultValue})? readBool,
    Future<String?> Function(String key)? readString,
  })  : _readBool = readBool ?? StorageService.getBool,
        _readString = readString ?? StorageService.getString;

  final Future<bool> Function(String key, {bool defaultValue}) _readBool;
  final Future<String?> Function(String key) _readString;

  Future<WorkShiftMarkedInPrefs> load() async {
    try {
      final markedInEnabled =
          await _readBool(AppConstants.markedInEnabledKey);
      final markedInStatus =
          await _readString(AppConstants.markedInStatusKey) ?? '';
      final isMFMarkedIn = markedInEnabled && markedInStatus == 'M-F';

      var isShiftMarkedIn = false;
      var markedInZone = '';
      if (markedInEnabled &&
          (markedInStatus == 'Shift' || markedInStatus == 'M-F')) {
        markedInZone =
            await _readString(AppConstants.markedInZoneKey) ?? 'Zone 1';
        if (markedInStatus == 'Shift') {
          isShiftMarkedIn = true;
        }
      }

      return WorkShiftMarkedInPrefs(
        isMFMarkedIn: isMFMarkedIn,
        isShiftMarkedIn: isShiftMarkedIn,
        markedInZone: markedInZone,
      );
    } catch (_) {
      return WorkShiftMarkedInPrefs.empty;
    }
  }
}
