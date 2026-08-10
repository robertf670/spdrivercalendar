import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone_board_mapper.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

/// Loads Zone 1/3/4 duty boards from bundled JSON and maps them to
/// [UniversalBoard] for the shared board dialog.
class ZoneBoardService {
  ZoneBoardService._();

  static final Map<String, Map<String, dynamic>> _cachedByAsset = {};

  /// Zone 4 View Board is unavailable from the Aug 2026 bill changeover —
  /// new board sheets are not ready yet. Earlier dates still use Zone4_Boards.json.
  static final DateTime zone4BoardsDisabledFrom = DateTime(2026, 8, 23);

  static Future<UniversalBoard?> getBoardForDuty({
    required String dutyTitle,
    required DateTime date,
  }) async {
    final dutyCode = ZoneBoardMapper.normalizeDutyCode(dutyTitle);
    if (dutyCode == null) return null;

    if (dutyCode.startsWith('PZ4/') &&
        !date.isBefore(zone4BoardsDisabledFrom)) {
      return null;
    }

    final assetPath = ZoneBoardMapper.assetPathForDuty(dutyCode);
    if (assetPath == null) return null;

    final zoneData = await _loadAsset(assetPath);
    final dutyData = zoneData[dutyCode];
    if (dutyData is! Map) return null;

    final dayKey = ZoneBoardMapper.dayKeyForDate(
      date,
      isSaturdayService: RosterService.isSaturdayService(date),
      isBankHoliday:
          ShiftService.getBankHoliday(date, ShiftService.bankHolidays) != null,
    );

    final dayData = dutyData[dayKey];
    if (dayData is! Map) return null;

    return ZoneBoardMapper.fromDayData(
      dutyCode,
      Map<String, dynamic>.from(dayData),
    );
  }

  static Future<Map<String, dynamic>> _loadAsset(String assetPath) async {
    final cached = _cachedByAsset[assetPath];
    if (cached != null) return cached;

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final decoded = json.decode(jsonString);
      if (decoded is! Map) {
        _cachedByAsset[assetPath] = {};
        return _cachedByAsset[assetPath]!;
      }
      final map = Map<String, dynamic>.from(decoded);
      _cachedByAsset[assetPath] = map;
      return map;
    } catch (_) {
      _cachedByAsset[assetPath] = {};
      return _cachedByAsset[assetPath]!;
    }
  }

  /// Test helper to clear in-memory cache.
  static void clearCache() {
    _cachedByAsset.clear();
  }
}
