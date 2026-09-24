/// Calendar-day ranges for Statistics. Compare year/month/day only so UTC
/// event dates and local week bounds do not drop Saturday or include the
/// first day of the next month.
class StatisticsDateRange {
  const StatisticsDateRange._();

  static DateTime calendarDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool sameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Sunday–Saturday week containing [now].
  static ({DateTime start, DateTime end}) thisWeek(DateTime now) {
    final today = calendarDay(now);
    final start = today.subtract(Duration(days: now.weekday % 7));
    return (start: start, end: start.add(const Duration(days: 6)));
  }

  static ({DateTime start, DateTime end}) lastWeek(DateTime now) {
    final current = thisWeek(now);
    final end = current.start.subtract(const Duration(days: 1));
    return (start: end.subtract(const Duration(days: 6)), end: end);
  }

  /// First of this month through first of next month (exclusive).
  static ({DateTime start, DateTime endExclusive}) thisMonth(DateTime now) {
    final start = DateTime(now.year, now.month, 1);
    return (start: start, endExclusive: DateTime(now.year, now.month + 1, 1));
  }

  static ({DateTime start, DateTime endExclusive}) lastMonth(DateTime now) {
    final current = thisMonth(now);
    return (
      start: DateTime(current.start.year, current.start.month - 1, 1),
      endExclusive: current.start,
    );
  }

  static bool isOnOrBetween(
    DateTime date,
    DateTime start,
    DateTime endInclusive,
  ) {
    final day = calendarDay(date);
    final from = calendarDay(start);
    final to = calendarDay(endInclusive);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  static bool isInHalfOpen(
    DateTime date,
    DateTime start,
    DateTime endExclusive,
  ) {
    final day = calendarDay(date);
    final from = calendarDay(start);
    final until = calendarDay(endExclusive);
    return !day.isBefore(from) && day.isBefore(until);
  }
}
