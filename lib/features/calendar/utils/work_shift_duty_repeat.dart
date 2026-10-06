import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

/// When the Add Work Shift dialog can offer “repeat this duty this week”.
class WorkShiftDutyRepeat {
  WorkShiftDutyRepeat._();

  static bool isRepeatableZone(
    String selectedZone, {
    required bool jamestownEnabled,
  }) {
    if (selectedZone == 'Zone 1' ||
        selectedZone == 'Zone 2' ||
        selectedZone == 'Zone 3' ||
        selectedZone == 'Zone 4' ||
        selectedZone == DonnybrookFeatureService.zoneLabel) {
      return true;
    }
    return selectedZone == JamestownFeatureService.zoneLabel &&
        jamestownEnabled;
  }

  static bool shouldShow({
    required String selectedZone,
    required DateTime shiftDate,
    required bool isMFMarkedIn,
    required bool isShiftMarkedIn,
    required bool isNightsRoster,
    required String markedInZone,
    required bool jamestownEnabled,
    bool Function(DateTime date)? isNightsWorkDay,
  }) {
    if (!isRepeatableZone(
      selectedZone,
      jamestownEnabled: jamestownEnabled,
    )) {
      return false;
    }

    final weekday = shiftDate.weekday;
    final isWeekend =
        weekday == DateTime.saturday || weekday == DateTime.sunday;
    if (isWeekend) return false;

    if (isNightsRoster) {
      return isNightsWorkDay?.call(shiftDate) ?? false;
    }

    if (!(isShiftMarkedIn || isMFMarkedIn)) return false;
    if (isShiftMarkedIn && selectedZone != markedInZone) return false;
    return true;
  }
}
