/// Pin a Zone 2 Shift week from a duty on a weekday, optionally using rest days.
class Zone2ShiftRoster {
  Zone2ShiftRoster._();

  static const sourceTag = 'zone2Roster';
  static const cycleLengthWeeks = 35;
  static const fillBlockWeeks = 35;
  static const assetPath = 'assets/zone2_shift_35week_roster.json';

  /// dayIndex: 0=Sunday … 6=Saturday.
  static List<int> weekIndexesForDutyOnDay({
    required List<List<String>> weeks,
    required int dayIndex,
    required String dutyCode,
  }) {
    if (dayIndex < 0 || dayIndex > 6 || dutyCode.isEmpty || dutyCode == 'R') {
      return const [];
    }
    final matches = <int>[];
    for (var i = 0; i < weeks.length; i++) {
      final days = weeks[i];
      if (dayIndex < days.length && days[dayIndex] == dutyCode) {
        matches.add(i);
      }
    }
    return matches;
  }

  /// Unique week, or rest-day disambiguation. Null if none or still ambiguous.
  static int? pinWeekIndex({
    required List<List<String>> weeks,
    required int dayIndex,
    required String dutyCode,
    List<bool>? calendarWeekIsRest,
  }) {
    final matches = weekIndexesForDutyOnDay(
      weeks: weeks,
      dayIndex: dayIndex,
      dutyCode: dutyCode,
    );
    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first;

    if (calendarWeekIsRest != null && calendarWeekIsRest.length == 7) {
      final restFiltered = matches.where((weekIndex) {
        final days = weeks[weekIndex];
        for (var d = 0; d < 7; d++) {
          final rosterRest = d < days.length && days[d] == 'R';
          if (rosterRest != calendarWeekIsRest[d]) return false;
        }
        return true;
      }).toList();
      if (restFiltered.length == 1) return restFiltered.first;
    }
    return null;
  }
}
