import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

/// Rewrites stored `PZ2/` duty codes to `13/` in local event JSON.
///
/// Calendar events live on each device, so this runs when that user opens
/// the updated app. Google Calendar copies are left until the event is
/// edited or synced again.
class Pz2ToRoute13Migrator {
  Pz2ToRoute13Migrator._();

  static const backupSuffix = '_backup';

  static Future<bool> migrate({
    required Future<String?> Function(String key) readString,
    required Future<void> Function(String key, String value) writeString,
    String eventsKey = AppConstants.eventsStorageKey,
  }) async {
    var changed = false;
    for (final key in [eventsKey, '$eventsKey$backupSuffix']) {
      final raw = await readString(key);
      if (raw == null || raw.isEmpty) continue;
      final next = Zone2Duties.rewriteStoredText(raw);
      if (next == raw) continue;
      await writeString(key, next);
      changed = true;
    }
    return changed;
  }
}
