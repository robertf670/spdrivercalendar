import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/marked_in_status.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone1_shift_roster.dart';
import 'package:spdrivercalendar/models/event.dart';

/// Zone 1 Shift 85-week roster fill.
class Zone1RosterFeatureService {
  Zone1RosterFeatureService._();

  static const menuLabel = 'Zone 1 Roster';

  static bool showsForMarkedIn({
    required String status,
    required String zone,
  }) {
    return status == MarkedInStatus.shift && zone == 'Zone 1';
  }

  static Future<bool> isEnabled() async {
    return StorageService.getBool(AppConstants.zone1RosterEnabledKey);
  }

  static Future<void> setEnabled(bool enabled) async {
    await StorageService.saveBool(AppConstants.zone1RosterEnabledKey, enabled);
    if (enabled) {
      await StorageService.saveBool(AppConstants.zone2RosterEnabledKey, false);
      await StorageService.saveBool(AppConstants.zone4RosterEnabledKey, false);
    }
  }

  static bool isFillEvent(Event event) =>
      event.rosterFillSource == Zone1ShiftRoster.sourceTag;

  static List<Event> filledEvents(Iterable<Event> events) =>
      events.where(isFillEvent).toList();
}
