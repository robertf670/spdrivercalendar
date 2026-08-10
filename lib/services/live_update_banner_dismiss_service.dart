import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/models/live_update.dart';

/// Per-device dismissals for the calendar live-updates banner.
///
/// Dismissed items stay available on the Live Updates details screen.
class LiveUpdateBannerDismissService {
  LiveUpdateBannerDismissService._();

  static const String _prefsKey = 'dismissed_live_update_banners';

  /// Current dismissed IDs. Listen to rebuild banner UI after dismiss.
  static final ValueNotifier<Set<String>> dismissedIds =
      ValueNotifier<Set<String>>(<String>{});

  static bool _loaded = false;
  static Future<void>? _loading;

  static Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      dismissedIds.value = (prefs.getStringList(_prefsKey) ?? []).toSet();
    } catch (_) {
      dismissedIds.value = <String>{};
    } finally {
      _loaded = true;
      _loading = null;
    }
  }

  static Future<void> dismiss(String updateId) async {
    await ensureLoaded();
    if (dismissedIds.value.contains(updateId)) return;
    final next = {...dismissedIds.value, updateId};
    dismissedIds.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, next.toList());
    } catch (_) {}
  }

  static List<LiveUpdate> filter(List<LiveUpdate> items) {
    final dismissed = dismissedIds.value;
    if (dismissed.isEmpty) return items;
    return items.where((item) => !dismissed.contains(item.id)).toList();
  }

  /// Items that should appear on the calendar banner.
  static List<LiveUpdate> visibleForBanner(List<LiveUpdate> items) {
    return filter(items).where((item) {
      if (item.isUpdate) return item.isActive;
      if (item.isPoll) return item.shouldShowPoll;
      return false;
    }).toList();
  }
}
