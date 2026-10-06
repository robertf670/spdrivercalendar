/// 12-week nights roster is this 4-week work/rest cycle, three times.
/// Weeks start on Sunday. R = rest, W = work.
class NightsRoster {
  NightsRoster._();

  static const weekCount = 4;

  static const weeks = [
    'RWWWWRW', // Sunday, Friday
    'WWWRRWW', // Wednesday, Thursday
    'WWRWWWR', // Tuesday, Saturday
    'RRWWWWW', // Sunday, Monday
  ];

  static const _dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static DateTime sundayOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday % 7));
  }

  static String dateKey(DateTime date) {
    final sunday = sundayOf(date);
    final month = sunday.month.toString().padLeft(2, '0');
    final day = sunday.day.toString().padLeft(2, '0');
    return '${sunday.year}-$month-$day';
  }

  static int weekIndexForDate({
    required DateTime date,
    required DateTime anchorSunday,
    required int anchorWeekIndex,
  }) {
    final sunday = sundayOf(date);
    final anchor = sundayOf(anchorSunday);
    final weeksSince = sunday.difference(anchor).inDays ~/ 7;
    return ((anchorWeekIndex + weeksSince) % weekCount + weekCount) % weekCount;
  }

  static String shiftForDate({
    required DateTime date,
    required DateTime anchorSunday,
    required int anchorWeekIndex,
  }) {
    final week = weeks[weekIndexForDate(
      date: date,
      anchorSunday: anchorSunday,
      anchorWeekIndex: anchorWeekIndex,
    )];
    return week[date.weekday % 7];
  }

  static bool isWorkDay({
    required DateTime date,
    required DateTime anchorSunday,
    required int anchorWeekIndex,
  }) {
    return shiftForDate(
          date: date,
          anchorSunday: anchorSunday,
          anchorWeekIndex: anchorWeekIndex,
        ) ==
        'W';
  }

  static String restDaysLabel(int weekIndex) {
    final week = weeks[weekIndex % weekCount];
    final days = <String>[];
    for (var i = 0; i < week.length; i++) {
      if (week[i] == 'R') days.add(_dayNames[i]);
    }
    return days.join(', ');
  }
}

class NightsRosterAnchor {
  const NightsRosterAnchor({
    required this.sunday,
    required this.weekIndex,
  });

  final DateTime sunday;
  final int weekIndex;

  static NightsRosterAnchor? tryParse({
    String? sunday,
    int weekIndex = 0,
  }) {
    final parsed = DateTime.tryParse(sunday ?? '');
    if (parsed == null) return null;
    if (weekIndex < 0 || weekIndex >= NightsRoster.weekCount) return null;
    return NightsRosterAnchor(
      sunday: NightsRoster.sundayOf(parsed),
      weekIndex: weekIndex,
    );
  }
}
