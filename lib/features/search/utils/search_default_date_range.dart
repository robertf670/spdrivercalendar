/// Default Search date range: first Sunday of [openedOn]'s month through
/// the last day of that month.
({DateTime start, DateTime end}) searchDefaultDateRange(DateTime openedOn) {
  final firstOfMonth = DateTime(openedOn.year, openedOn.month, 1);
  var firstSunday = firstOfMonth;
  while (firstSunday.weekday != DateTime.sunday) {
    firstSunday = firstSunday.add(const Duration(days: 1));
  }
  final lastOfMonth = DateTime(openedOn.year, openedOn.month + 1, 0);
  return (start: firstSunday, end: lastOfMonth);
}
