/// Pin a Zone 4 Shift week from a duty on a weekday, optionally using rest days.
class Zone4ShiftRoster {
  Zone4ShiftRoster._();

  static const sourceTag = 'zone4Roster';
  static const assetPath = 'assets/zone4_shift_roster.json';

  /// First Sunday of this roster. Earlier dates keep the previous Zone 4 bill.
  static final DateTime startsOn = DateTime(2026, 8, 23);

  static bool codesMatch(String a, String b) {
    return _canonical(a) == _canonical(b);
  }

  /// `PZ4/05` and `PZ4/5` are the same duty.
  static String _canonical(String raw) {
    final code = raw.trim().toUpperCase();
    final match = RegExp(r'^PZ4/0*(\d+[A-Z]?)$').firstMatch(code);
    if (match == null) return code;
    return 'PZ4/${match.group(1)}';
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

  /// Unique week whose rest days match this week, when those rest days are known.
  ///
  /// A duty that falls on the right weekday but belongs to a different rest
  /// pattern is rejected. Without rest days, a duty that appears once is used.
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
      return null;
    }

    if (matches.length == 1) return matches.first;
    return null;
  }

  /// Week to write for [offset] weeks after the pinned week.
  ///
  /// An unfinished roster does not wrap back to week 1.
  static int? filledWeekIndex({
    required int pinnedWeek,
    required int offset,
    required int length,
    required bool complete,
  }) {
    if (length <= 0 || offset < 0) return null;
    final index = pinnedWeek + offset;
    if (complete) return index % length;
    if (index >= length) return null;
    return index;
  }
}
