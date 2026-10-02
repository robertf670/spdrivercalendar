/// Marked-in status labels and fixed work/rest patterns.
class MarkedInStatus {
  MarkedInStatus._();

  static const spare = 'Spare';
  static const shift = 'Shift';
  static const mf = 'M-F';
  static const fourDay = '4 Day';

  static const statusOptions = [spare, shift, mf, fourDay];

  static bool isFixedWorkPattern(String status) =>
      status == mf || status == fourDay;

  static bool needsZone(String status) =>
      status == shift || status == mf;

  /// Friday, Saturday, Sunday, Monday.
  static bool isFourDayWorkDay(DateTime date) {
    final weekday = date.weekday;
    return weekday == DateTime.friday ||
        weekday == DateTime.saturday ||
        weekday == DateTime.sunday ||
        weekday == DateTime.monday;
  }

  static bool isWorkDay(String status, DateTime date) {
    if (status == mf) {
      return date.weekday >= DateTime.monday &&
          date.weekday <= DateTime.friday;
    }
    if (status == fourDay) {
      return isFourDayWorkDay(date);
    }
    return false;
  }

  /// Repeat-this-week indexes: 0 = Sunday … 6 = Saturday.
  static List<int> repeatDayIndexes(String status) {
    if (status == fourDay) {
      return const [5, 6, 0, 1];
    }
    return const [1, 2, 3, 4, 5];
  }
}
