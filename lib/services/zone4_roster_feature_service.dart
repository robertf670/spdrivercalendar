import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/marked_in_status.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone4_shift_roster.dart';
import 'package:spdrivercalendar/models/event.dart';

/// Zone 4 Shift roster fill.
class Zone4RosterFeatureService {
  Zone4RosterFeatureService._();

  static const menuLabel = 'Zone 4 Roster';

  static bool showsForMarkedIn({
    required String status,
    required String zone,
  }) {
    return status == MarkedInStatus.shift && zone == 'Zone 4';
  }

  static Future<bool> isEnabled() async {
    return StorageService.getBool(AppConstants.zone4RosterEnabledKey);
  }

  static Future<void> setEnabled(bool enabled) async {
    await StorageService.saveBool(AppConstants.zone4RosterEnabledKey, enabled);
    if (enabled) {
      await StorageService.saveBool(AppConstants.zone2RosterEnabledKey, false);
    }
  }

  static bool isFillEvent(Event event) =>
      event.rosterFillSource == Zone4ShiftRoster.sourceTag;

  static List<Event> filledEvents(List<Event> events) =>
      events.where(isFillEvent).toList();
}
