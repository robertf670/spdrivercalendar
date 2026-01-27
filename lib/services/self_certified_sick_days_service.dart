import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/models/event.dart';

class SelfCertifiedSickDaysService {
  // Limits: 4 per year total, 2 per half-year
  static const int yearlyLimit = 4;
  static const int halfYearLimit = 2;

  /// Get the half-year period for a given date
  /// Returns: 'first' for Jan-Jun, 'second' for Jul-Dec
  static String getHalfYear(DateTime date) {
    return date.month <= 6 ? 'first' : 'second';
  }

  /// Get all self-certified sick days for a given year
  static Future<List<Event>> getSelfCertifiedDaysForYear(int year) async {
    final allEvents = await EventService.getAllEvents();
    final selfCertifiedDays = <Event>[];
    
    for (final event in allEvents) {
      if (event.sickDayType == 'self-certified' && event.startDate.year == year) {
        selfCertifiedDays.add(event);
      }
    }
    
    return selfCertifiedDays;
  }

  /// Get self-certified sick days for a specific half-year
  static Future<List<Event>> getSelfCertifiedDaysForHalfYear(int year, String halfYear) async {
    final allDays = await getSelfCertifiedDaysForYear(year);
    return allDays.where((event) {
      final eventHalfYear = getHalfYear(event.startDate);
      return eventHalfYear == halfYear;
    }).toList();
  }

  /// Get count of self-certified days for a specific half-year
  static Future<int> getCountForHalfYear(int year, String halfYear) async {
    final days = await getSelfCertifiedDaysForHalfYear(year, halfYear);
    return days.length;
  }

  /// Get count of self-certified days for the entire year
  static Future<int> getCountForYear(int year) async {
    final days = await getSelfCertifiedDaysForYear(year);
    return days.length;
  }

  /// Check if adding a self-certified day would exceed the half-year limit
  /// Returns: true if allowed, false if would exceed limit
  static Future<bool> canAddSelfCertifiedDay(DateTime date) async {
    final year = date.year;
    final halfYear = getHalfYear(date);
    final currentCount = await getCountForHalfYear(year, halfYear);
    
    return currentCount < halfYearLimit;
  }

  /// Check if adding a self-certified day would exceed the yearly limit
  /// Returns: true if allowed, false if would exceed limit
  static Future<bool> canAddSelfCertifiedDayYearly(DateTime date) async {
    final year = date.year;
    final currentCount = await getCountForYear(year);
    
    return currentCount < yearlyLimit;
  }

  /// Get remaining self-certified days for a specific half-year
  static Future<int> getRemainingForHalfYear(int year, String halfYear) async {
    final currentCount = await getCountForHalfYear(year, halfYear);
    return (halfYearLimit - currentCount).clamp(0, halfYearLimit);
  }

  /// Get remaining self-certified days for the entire year
  static Future<int> getRemainingForYear(int year) async {
    final currentCount = await getCountForYear(year);
    return (yearlyLimit - currentCount).clamp(0, yearlyLimit);
  }

  /// Get statistics for self-certified sick days
  /// Returns a map with counts for first half, second half, and total for the year
  static Future<Map<String, dynamic>> getStatistics(int year) async {
    final firstHalfCount = await getCountForHalfYear(year, 'first');
    final secondHalfCount = await getCountForHalfYear(year, 'second');
    final totalCount = await getCountForYear(year);
    final firstHalfRemaining = await getRemainingForHalfYear(year, 'first');
    final secondHalfRemaining = await getRemainingForHalfYear(year, 'second');
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
