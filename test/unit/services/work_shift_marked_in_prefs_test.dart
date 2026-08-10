import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/work_shift_marked_in_prefs.dart';

void main() {
  test('loads M-F marked-in prefs', () async {
    final loader = WorkShiftMarkedInPrefsLoader(
      readBool: (key, {defaultValue = false}) async =>
          key == AppConstants.markedInEnabledKey,
      readString: (key) async {
        if (key == AppConstants.markedInStatusKey) return 'M-F';
        if (key == AppConstants.markedInZoneKey) return 'Zone 3';
        return null;
      },
    );

    final prefs = await loader.load();
    expect(prefs.isMFMarkedIn, isTrue);
    expect(prefs.isShiftMarkedIn, isFalse);
    expect(prefs.markedInZone, 'Zone 3');
  });

  test('loads Shift marked-in prefs', () async {
    final loader = WorkShiftMarkedInPrefsLoader(
      readBool: (key, {defaultValue = false}) async =>
          key == AppConstants.markedInEnabledKey,
      readString: (key) async {
        if (key == AppConstants.markedInStatusKey) return 'Shift';
        if (key == AppConstants.markedInZoneKey) return 'Zone 1';
        return null;
      },
    );

    final prefs = await loader.load();
    expect(prefs.isMFMarkedIn, isFalse);
    expect(prefs.isShiftMarkedIn, isTrue);
    expect(prefs.markedInZone, 'Zone 1');
  });
}
