/// Returns every Sunday in [year], inclusive of year boundaries.
List<DateTime> getSundaysForYear(int year) {
  final firstDayOfYear = DateTime(year, 1, 1);
  final lastDayOfYear = DateTime(year, 12, 31);

  var firstSunday = firstDayOfYear;
  while (firstSunday.weekday != DateTime.sunday) {
    firstSunday = firstSunday.add(const Duration(days: 1));
  }

  final sundays = <DateTime>[];
  var currentSunday = firstSunday;
  while (!currentSunday.isAfter(lastDayOfYear)) {
    sundays.add(currentSunday);
    currentSunday = currentSunday.add(const Duration(days: 7));
  }
  return sundays;
}
