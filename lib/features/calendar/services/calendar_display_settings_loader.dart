import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';

/// Snapshot of calendar display / marked-in preferences.
class CalendarDisplaySettings {
  const CalendarDisplaySettings({
    required this.markedInEnabled,
    required this.markedInStatus,
    required this.showDutyCodesOnCalendar,
    required this.animatedSelectedDay,
    required this.highlightWorkoutDays,
  });

  final bool markedInEnabled;
  final String markedInStatus;
  final bool showDutyCodesOnCalendar;
  final bool animatedSelectedDay;
  final bool highlightWorkoutDays;
}

typedef BoolSettingReader = Future<bool> Function(
  String key, {
  bool defaultValue,
});
typedef StringSettingReader = Future<String?> Function(String key);

/// Loads marked-in and display toggles used by the calendar screen.
class CalendarDisplaySettingsLoader {
  CalendarDisplaySettingsLoader({
    BoolSettingReader? readBool,
    StringSettingReader? readString,
  })  : _readBool = readBool ?? StorageService.getBool,
        _readString = readString ?? StorageService.getString;

  final BoolSettingReader _readBool;
  final StringSettingReader _readString;

  Future<CalendarDisplaySettings> load() async {
    final markedInEnabledFlag =
        await _readBool(AppConstants.markedInEnabledKey);
    final markedInStatus =
        await _readString(AppConstants.markedInStatusKey) ?? '';

    final markedInEnabled =
        markedInEnabledFlag && markedInStatus.isNotEmpty;
    final normalizedStatus =
        markedInStatus.isEmpty ? 'Spare' : markedInStatus;

    return CalendarDisplaySettings(
      markedInEnabled: markedInEnabled,
      markedInStatus: normalizedStatus,
      showDutyCodesOnCalendar: await _readBool(
        AppConstants.showDutyCodesOnCalendarKey,
        defaultValue: true,
      ),
      animatedSelectedDay: await _readBool(
        AppConstants.animatedSelectedDayKey,
        defaultValue: true,
      ),
      highlightWorkoutDays: await _readBool(
        AppConstants.highlightWorkoutDaysKey,
        defaultValue: false,
      ),
    );
  }
}
