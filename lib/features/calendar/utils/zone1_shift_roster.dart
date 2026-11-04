/// Pin a Zone 1 Shift week from a duty on a weekday, optionally using rest days.
class Zone1ShiftRoster {
  Zone1ShiftRoster._();

  static const sourceTag = 'zone1Roster';
  static const cycleLengthWeeks = 85;
  static const fillBlockWeeks = 85;
  static const assetPath = 'assets/zone1_shift_86week_roster.json';

  static bool codesMatch(String a, String b) {
    return _canonical(a) == _canonical(b);
  }

  /// `PZ1/01` and `PZ1/1` are the same duty.
  static String _canonical(String raw) {
    final code = raw.trim().toUpperCase();
    final match = RegExp(r'^PZ1/0*(\d+[A-Z]?)$').firstMatch(code);
    if (match == null) return code;
    return 'PZ1/${match.group(1)}';
  }

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
      if (dayIndex < days.length && codesMatch(days[dayIndex], dutyCode)) {
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
