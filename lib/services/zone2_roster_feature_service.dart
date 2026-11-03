import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';
import 'package:spdrivercalendar/features/calendar/utils/marked_in_status.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone2_shift_roster.dart';
import 'package:spdrivercalendar/models/event.dart';

/// Route 13 35-week Shift roster fill.
class Zone2RosterFeatureService {
  Zone2RosterFeatureService._();

  static const menuLabel = 'Route 13 Roster';

  static bool showsForMarkedIn({
    required String status,
    required String zone,
  }) {
    return status == MarkedInStatus.shift && Zone2Duties.isZone(zone);
  }

  static Future<bool> isEnabled() async {
    return StorageService.getBool(AppConstants.zone2RosterEnabledKey);
  }

  static Future<void> setEnabled(bool enabled) async {
    await StorageService.saveBool(AppConstants.zone2RosterEnabledKey, enabled);
    if (enabled) {
      await StorageService.saveBool(AppConstants.zone4RosterEnabledKey, false);
    }
  }

  static bool isFillEvent(Event event) =>
      event.rosterFillSource == Zone2ShiftRoster.sourceTag;

  static List<Event> filledEvents(Iterable<Event> events) =>
      events.where(isFillEvent).toList();
}
