/// Safely shifts [currentDate] by [monthOffset] months.
///
/// Clamps the day to the last valid day of the target month so navigating from
/// a 31-day month into a shorter month does not overflow into the following one.
DateTime navigateCalendarMonth(DateTime currentDate, int monthOffset) {
  var targetYear = currentDate.year;
  var targetMonth = currentDate.month + monthOffset;

  if (targetMonth > 12) {
    targetMonth = 1;
    targetYear++;
  } else if (targetMonth < 1) {
    targetMonth = 12;
    targetYear--;
  }

  final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
  final targetDay = currentDate.day > lastDayOfTargetMonth
      ? lastDayOfTargetMonth
      : currentDate.day;

  return DateTime(targetYear, targetMonth, targetDay);
}
