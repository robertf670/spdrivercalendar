import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';

/// Lookup helpers for holiday booking dialogs.
class HolidayLookupService {
  /// Whether a holiday of [type] already covers [date].
  static Future<bool> hasHolidayForDate(DateTime date, String type) async {
    final holidays = await HolidayService.getHolidays();
    return holidays.any((h) => h.type == type && h.containsDate(date));
  }

  /// Counts holidays of [type] whose start year is in
  /// `[startYear, startYear + 4]`.
  static Future<Map<int, int>> getHolidayCountsForYears(
    int startYear,
    String type,
  ) async {
    final holidays = await HolidayService.getHolidays();
    final counts = <int, int>{};

    for (var i = 0; i < 5; i++) {
      final year = startYear + i;
      counts[year] = holidays
          .where((h) => h.type == type && h.startDate.year == year)
          .length;
    }

    return counts;
  }
}
