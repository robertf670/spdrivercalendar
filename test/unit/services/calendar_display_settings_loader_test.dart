import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/calendar_display_settings_loader.dart';

void main() {
  test('marked-in requires both flag and non-empty status', () async {
    final prefs = <String, Object?>{
      AppConstants.markedInEnabledKey: true,
      AppConstants.markedInStatusKey: '',
      AppConstants.showDutyCodesOnCalendarKey: false,
      AppConstants.animatedSelectedDayKey: false,
      AppConstants.highlightWorkoutDaysKey: true,
    };

    final loader = CalendarDisplaySettingsLoader(
      readBool: (key, {defaultValue = false}) async =>
          (prefs[key] as bool?) ?? defaultValue,
      readString: (key) async => prefs[key] as String?,
    );

    final settings = await loader.load();
    expect(settings.markedInEnabled, isFalse);
    expect(settings.markedInStatus, 'Spare');
    expect(settings.showDutyCodesOnCalendar, isFalse);
    expect(settings.highlightWorkoutDays, isTrue);
  });

  test('enabled marked-in keeps status', () async {
    final loader = CalendarDisplaySettingsLoader(
      readBool: (key, {defaultValue = false}) async {
        if (key == AppConstants.markedInEnabledKey) return true;
        return defaultValue;
      },
      readString: (key) async =>
          key == AppConstants.markedInStatusKey ? 'M-F' : null,
    );

    final settings = await loader.load();
    expect(settings.markedInEnabled, isTrue);
    expect(settings.markedInStatus, 'M-F');
  });
}
