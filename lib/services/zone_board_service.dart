import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone_board_mapper.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

/// Loads Zone 1/3/4 and Jamestown duty boards from bundled JSON and maps
/// them to [UniversalBoard] for the shared board dialog.
class ZoneBoardService {
  ZoneBoardService._();

  static final Map<String, Map<String, dynamic>> _cachedByAsset = {};

  /// Zone 4 uses Zone4_Boards_20260823.json from this date (all day types).
  static final DateTime zone4NewBoardsFrom = ZoneBoardMapper.zone4NewBoardsFrom;

  static Future<UniversalBoard?> getBoardForDuty({
    required String dutyTitle,
    required DateTime date,
    String? dayKey,
  }) async {
    final dutyCode = ZoneBoardMapper.normalizeDutyCode(dutyTitle);
    if (dutyCode == null) return null;

    final resolvedDayKey = dayKey ??
        ZoneBoardMapper.dayKeyForDate(
          date,
          isSaturdayService: RosterService.isSaturdayService(date),
          isBankHoliday:
              ShiftService.getBankHoliday(date, ShiftService.bankHolidays) !=
                  null,
        );

    final assetPath = ZoneBoardMapper.assetPathForDuty(dutyCode, date: date);
    if (assetPath == null) return null;

    final zoneData = await _loadAsset(assetPath);
    final dutyData = zoneData[dutyCode];
    if (dutyData is! Map) return null;

    final dutyMap = Map<String, dynamic>.from(dutyData);

    // Jamestown boards are stored as ready UniversalBoard sections.
    if (dutyMap.containsKey('sections')) {
      return UniversalBoard.fromJson({
        'shift': dutyCode,
        ...dutyMap,
      });
    }

    final dayData = dutyMap[resolvedDayKey];
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

  /// Duty codes in a zone board file that have a board for [dayKey].
  static Future<List<String>> listDutyCodes({
    required String zoneNumber,
    required String dayKey,
    required DateTime date,
  }) async {
    final assetPath = ZoneBoardMapper.assetPathForDuty(
      'PZ$zoneNumber/01',
      date: date,
    );
    if (assetPath == null) return const [];

    final zoneData = await _loadAsset(assetPath);
    final codes = <String>[];
    for (final entry in zoneData.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      if (value.containsKey(dayKey)) {
        codes.add(entry.key);
      }
    }
    return codes;
  }

  /// Test helper to clear in-memory cache.
  static void clearCache() {
    _cachedByAsset.clear();
  }
}
