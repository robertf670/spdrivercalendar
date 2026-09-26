import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/assigned_duty_board_lookup.dart';
import 'package:spdrivercalendar/features/calendar/utils/zone_board_mapper.dart';
import 'package:spdrivercalendar/models/event.dart';

/// One rateable duty on one calendar day (occurrence).
class DutyRatingTarget {
  const DutyRatingTarget({
    required this.dutyCode,
    required this.dayType,
    required this.era,
    required this.date,
  });

  final String dutyCode;
  final String dayType;
  final String era;
  final String date;

  String get summaryId => '$dutyCode|$dayType|$era';

  String get encodedSummaryId => summaryId.replaceAll('/', '_');

  String voteDocId(String userId) => '${userId}_${encodedSummaryId}_$date';

  String get zone {
    if (dutyCode.startsWith('PZ1/')) return '1';
    if (dutyCode.startsWith('PZ2/')) return '2';
    if (dutyCode.startsWith('PZ3/')) return '3';
    if (dutyCode.startsWith('PZ4/')) return '4';
    if (dutyCode.startsWith('811/')) return 'jamestown';
    if (dutyCode.startsWith('DZ1/')) return 'dbz1';
    if (RegExp(r'^\d{2,3}/').hasMatch(dutyCode)) return 'uni';
    return 'other';
  }
}

/// Duty identity, eligibility, sign-off, and era for ratings.
class DutyRatingKey {
  DutyRatingKey._();

  static final DateTime zone4LegacyUntil = DateTime(2025, 10, 19);
  static final DateTime zone4NewBillFrom = DateTime(2026, 8, 23);

  static const excludedTitles = {
    'Union',
    'Mentor',
    'CPC',
    'Training',
  };

  static String normalizeDutyCode(String raw) {
    var code = AssignedDutyBoardLookup.lookupCode(raw);
    final donnybrookHalf = RegExp(r'^(DZ1/\d+)[AB]$').firstMatch(code);
    if (donnybrookHalf != null) {
      return donnybrookHalf.group(1)!;
    }
    return code;
  }

  static bool isRateableCode(String raw) {
    final code = normalizeDutyCode(raw);
    if (code.isEmpty) return false;
    if (code.toLowerCase().contains('workout')) return false;
    if (excludedTitles.contains(code)) return false;
    if (code.startsWith('SP')) return false;
    if (code.startsWith('BusCheck') || code.startsWith('BC')) return false;
    if (code.startsWith('PZ')) return true;
    if (code.startsWith('811/')) return true;
    if (code.startsWith('DZ1/')) return true;
    if (code == '22B/01') return true;
    if (RegExp(r'^\d{2,3}/\d+').hasMatch(code)) return true;
    return false;
  }

  static String eraFor(String dutyCode, DateTime date) {
    final code = normalizeDutyCode(dutyCode);
    if (!code.startsWith('PZ4/')) return 'current';
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(zone4LegacyUntil)) return 'legacy';
    if (day.isBefore(zone4NewBillFrom)) return '2324';
    return '2324_20260823';
  }

  static String dayTypeForDate(
    DateTime date, {
    required bool isSaturdayService,
    required bool isBankHoliday,
  }) {
    return ZoneBoardMapper.dayKeyForDate(
      date,
      isSaturdayService: isSaturdayService,
      isBankHoliday: isBankHoliday,
    );
  }

  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime signOffAt({
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime endDate,
    required TimeOfDay endTime,
  }) {
    final start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );
    var end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }
    return end;
  }

  static bool isAfterSignOff({
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime endDate,
    required TimeOfDay endTime,
    required DateTime now,
  }) {
    return now.isAfter(
      signOffAt(
        startDate: startDate,
        startTime: startTime,
        endDate: endDate,
        endTime: endTime,
      ),
    );
  }

  static bool eventIsRateable(Event event) {
    if (event.isHoliday) return false;
    if (event.sickDayType != null) return false;
    if (event.bankHolidayRedundant) return false;
    if (!event.isWorkShift && !event.isWorkForOthers) return false;
    return rateableCodesForEvent(event).isNotEmpty;
  }

  static List<String> rateableCodesForEvent(Event event) {
    if (event.isHoliday ||
        event.sickDayType != null ||
        event.bankHolidayRedundant) {
      return const [];
    }
    if (!event.isWorkShift && !event.isWorkForOthers) {
      return const [];
    }

    final assigned = event.getCurrentDutyCodes();
    final isSpareOr22b =
        event.title.startsWith('SP') || event.title == '22B/01';
    if (isSpareOr22b) {
      return assigned.isEmpty ? const [] : _uniqueRateable(assigned);
    }
    return _uniqueRateable([event.title]);
  }

  static List<DutyRatingTarget> targetsForCalendarEvent(Event event) {
    return targetsForEvent(
      event,
      isSaturdayService: RosterService.isSaturdayService(event.startDate),
      isBankHoliday: ShiftService.getBankHoliday(
            event.startDate,
            ShiftService.bankHolidays,
          ) !=
          null,
    );
  }

  static bool eventIsAfterSignOff(Event event, {DateTime? now}) {
    return isAfterSignOff(
      startDate: event.startDate,
      startTime: event.startTime,
      endDate: event.endDate,
      endTime: event.endTime,
      now: now ?? DateTime.now(),
    );
  }

  static String dayTypeLabel(String dayType) {
    switch (dayType) {
      case 'MON-FRI':
        return 'Mon–Fri';
      case 'SAT':
        return 'Sat';
      case 'SUN':
        return 'Sun';
      default:
        return dayType;
    }
  }

  static String eraLabel(String era) {
    switch (era) {
      case 'legacy':
        return 'before Oct 2025';
      case '2324':
        return '23/24';
      case '2324_20260823':
        return 'from 23 Aug 2026';
      default:
        return '';
    }
  }

  static List<DutyRatingTarget> targetsForEvent(
    Event event, {
    required bool isSaturdayService,
    required bool isBankHoliday,
  }) {
    final dayType = dayTypeForDate(
      event.startDate,
      isSaturdayService: isSaturdayService,
      isBankHoliday: isBankHoliday,
    );
    final date = formatDate(event.startDate);
    return [
      for (final code in rateableCodesForEvent(event))
        DutyRatingTarget(
          dutyCode: normalizeDutyCode(code),
          dayType: dayType,
          era: eraFor(code, event.startDate),
          date: date,
        ),
    ];
  }

  static bool canShowRateAction({
    required bool settingsEnabled,
    required bool isRateable,
    required bool afterSignOff,
  }) {
    return settingsEnabled && isRateable && afterSignOff;
  }

  static List<String> _uniqueRateable(Iterable<String> rawCodes) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in rawCodes) {
      if (!isRateableCode(raw)) continue;
      final code = normalizeDutyCode(raw);
      if (seen.add(code)) result.add(code);
    }
    return result;
  }
}
