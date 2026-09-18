import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/models/event.dart';

class SelfCertifiedSickDaysService {
  // Limits: 4 per bonus year (Nov–Oct), 2 per half
  static const int yearlyLimit = 4;
  static const int halfYearLimit = 2;

  static const String halfNovApr = 'novApr';
  static const String halfMayOct = 'mayOct';

  /// Sick-bonus halves: November–April and May–October, inclusive.
  static String getHalfYear(DateTime date) {
    final month = date.month;
    if (month >= 11 || month <= 4) return halfNovApr;
    return halfMayOct;
  }

  /// Bonus year ends on 31 October. November and December belong to the next year.
  static int bonusYearFor(DateTime date) {
    return date.month >= 11 ? date.year + 1 : date.year;
  }

  static String halfYearName(String halfYear) {
    return halfYear == halfMayOct ? 'May–October' : 'November–April';
  }

  static String halfYearShortName(String halfYear) {
    return halfYear == halfMayOct ? 'May–Oct' : 'Nov–Apr';
  }

  static const String bonusPeriodExplanation =
      'November–April and May–October are the sick bonus periods. You can still add this day.';

  static String limitWarningMessage({
    required String halfYearName,
    required bool halfYearReached,
    required bool yearReached,
  }) {
    if (halfYearReached && yearReached) {
      return 'You have already used 2 self-certified days in $halfYearName and 4 for the bonus year.';
    }
    if (halfYearReached) {
      return 'You have already used 2 self-certified days in $halfYearName.';
    }
    return 'You have already used 4 self-certified days for the bonus year.';
  }

  static ({DateTime start, DateTime end}) rangeForHalf(
    int bonusYear,
    String halfYear,
  ) {
    if (halfYear == halfMayOct) {
      return (
        start: DateTime(bonusYear, 5, 1),
        end: DateTime(bonusYear, 10, 31),
      );
    }
    return (
      start: DateTime(bonusYear - 1, 11, 1),
      end: DateTime(bonusYear, 4, 30),
    );
  }

  static ({DateTime start, DateTime end}) rangeForBonusYear(int bonusYear) {
    return (
      start: DateTime(bonusYear - 1, 11, 1),
      end: DateTime(bonusYear, 10, 31),
    );
  }

  static bool isInRange(DateTime date, DateTime start, DateTime end) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// Get all self-certified sick days for a bonus year (Nov–Oct).
  static Future<List<Event>> getSelfCertifiedDaysForYear(int year) async {
    final range = rangeForBonusYear(year);
    return _selfCertifiedDaysInRange(range.start, range.end);
  }

  /// Get self-certified sick days for a specific half of a bonus year.
  static Future<List<Event>> getSelfCertifiedDaysForHalfYear(
    int year,
    String halfYear,
  ) async {
    final range = rangeForHalf(year, halfYear);
    return _selfCertifiedDaysInRange(range.start, range.end);
  }

  static Future<List<Event>> _selfCertifiedDaysInRange(
    DateTime start,
    DateTime end,
  ) async {
    final allEvents = await EventService.getAllEvents();
    return allEvents.where((event) {
      return event.sickDayType == 'self-certified' &&
          isInRange(event.startDate, start, end);
    }).toList();
  }

  /// Get count of self-certified days for a specific half-year
  static Future<int> getCountForHalfYear(int year, String halfYear) async {
    final days = await getSelfCertifiedDaysForHalfYear(year, halfYear);
    return days.length;
  }

  /// Get count of self-certified days for the entire bonus year
  static Future<int> getCountForYear(int year) async {
    final days = await getSelfCertifiedDaysForYear(year);
    return days.length;
  }

  /// Check if adding a self-certified day would exceed the half-year limit
  /// Returns: true if allowed, false if would exceed limit
  static Future<bool> canAddSelfCertifiedDay(DateTime date) async {
    final year = bonusYearFor(date);
    final halfYear = getHalfYear(date);
    final currentCount = await getCountForHalfYear(year, halfYear);

    return currentCount < halfYearLimit;
  }

  /// Check if adding a self-certified day would exceed the yearly limit
  /// Returns: true if allowed, false if would exceed limit
  static Future<bool> canAddSelfCertifiedDayYearly(DateTime date) async {
    final year = bonusYearFor(date);
    final currentCount = await getCountForYear(year);

    return currentCount < yearlyLimit;
  }

  /// Get remaining self-certified days for a specific half-year
  static Future<int> getRemainingForHalfYear(int year, String halfYear) async {
    final currentCount = await getCountForHalfYear(year, halfYear);
    return (halfYearLimit - currentCount).clamp(0, halfYearLimit);
  }

  /// Get remaining self-certified days for the entire bonus year
  static Future<int> getRemainingForYear(int year) async {
    final currentCount = await getCountForYear(year);
    return (yearlyLimit - currentCount).clamp(0, yearlyLimit);
  }

  /// Get statistics for self-certified sick days
  /// [year] is the bonus year ending 31 October.
  static Future<Map<String, dynamic>> getStatistics(int year) async {
    final firstHalfCount = await getCountForHalfYear(year, halfNovApr);
    final secondHalfCount = await getCountForHalfYear(year, halfMayOct);
    final totalCount = await getCountForYear(year);
    final firstHalfRemaining = await getRemainingForHalfYear(year, halfNovApr);
    final secondHalfRemaining = await getRemainingForHalfYear(year, halfMayOct);
    final totalRemaining = await getRemainingForYear(year);

    return {
      'firstHalf': {
        'used': firstHalfCount,
        'remaining': firstHalfRemaining,
        'limit': halfYearLimit,
      },
      'secondHalf': {
        'used': secondHalfCount,
        'remaining': secondHalfRemaining,
        'limit': halfYearLimit,
      },
      'year': {
        'used': totalCount,
        'remaining': totalRemaining,
        'limit': yearlyLimit,
      },
    };
  }
}
