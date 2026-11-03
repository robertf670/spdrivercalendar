import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';

/// One duty drawn on a shared day clock. Times are minutes from midnight,
/// and a finish after midnight is past 24:00.
class DutyDaySpan {
  const DutyDaySpan({
    required this.start,
    required this.end,
    this.breakStart,
    this.breakEnd,
  });

  final int start;
  final int end;
  final int? breakStart;
  final int? breakEnd;

  bool get hasBreak =>
      breakStart != null && breakEnd != null && breakEnd! > breakStart!;
}

class DutyCompareLine {
  const DutyCompareLine({
    required this.label,
    required this.yours,
    required this.theirs,
    this.deltaMinutes,
  });

  final String label;
  final String yours;
  final String theirs;

  /// Theirs minus yours, in minutes. Null when the two values cannot be
  /// subtracted.
  final int? deltaMinutes;

  bool get isSame =>
      yours.isNotEmpty &&
      yours == theirs &&
      (deltaMinutes == null || deltaMinutes == 0);
}

class DutyCompare {
  const DutyCompare({
    required this.yours,
    required this.theirs,
    required this.headline,
    required this.lines,
    this.yoursSpan,
    this.theirsSpan,
    this.axisStart,
    this.axisEnd,
  });

  final BillDuty yours;
  final BillDuty theirs;
  final String headline;
  final List<DutyCompareLine> lines;
  final DutyDaySpan? yoursSpan;
  final DutyDaySpan? theirsSpan;
  final int? axisStart;
  final int? axisEnd;

  bool get hasClock =>
      yoursSpan != null &&
      theirsSpan != null &&
      axisStart != null &&
      axisEnd != null &&
      axisEnd! > axisStart!;

  static DutyCompare of(BillDuty yours, BillDuty theirs) {
    final yoursSpan = spanFor(yours);
    final theirsSpan = spanFor(theirs);
    final axis = _axis(yoursSpan, theirsSpan);
    return DutyCompare(
      yours: yours,
      theirs: theirs,
      headline: _headline(yours, theirs),
      lines: _lines(yours, theirs),
      yoursSpan: yoursSpan,
      theirsSpan: theirsSpan,
      axisStart: axis?.$1,
      axisEnd: axis?.$2,
    );
  }

  static int? clockMinutes(String raw) {
    final shown = BillDuty.displayTime(raw);
    if (shown.isEmpty || shown == 'W/O') return null;
    final parts = shown.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static int? durationMinutes(String raw) {
    if (BillDuty.isBlank(raw)) return null;
    final parts = raw.trim().split(':');
    if (parts.length < 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    if (hours < 0 || minutes < 0 || minutes > 59) return null;
    return hours * 60 + minutes;
  }

  static String formatClock(int minutes) {
    final wrapped = minutes % 1440;
    final hour = wrapped ~/ 60;
    final minute = wrapped % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static String formatDelta(int minutes) {
    if (minutes == 0) return 'Same';
    final sign = minutes > 0 ? '+' : '−';
    final abs = minutes.abs();
    final shown = BillDuty.displayDuration(
      '${abs ~/ 60}:${(abs % 60).toString().padLeft(2, '0')}',
    );
    return '$sign$shown';
  }

  static DutyDaySpan? spanFor(BillDuty duty) {
    final start = clockMinutes(duty.report) ?? clockMinutes(duty.depart);
    final finish = clockMinutes(duty.signOff) ?? clockMinutes(duty.finish);
    if (start == null || finish == null) return null;
    final end = finish < start ? finish + 1440 : finish;
    if (end <= start) return null;

    int? breakStart;
    int? breakEnd;
    if (duty.hasMealBreak) {
      final rawStart = clockMinutes(duty.startBreak);
      final rawEnd = clockMinutes(duty.finishBreak);
      if (rawStart != null && rawEnd != null) {
        var from = rawStart < start ? rawStart + 1440 : rawStart;
        var to = rawEnd < from ? rawEnd + 1440 : rawEnd;
        if (from < start) from += 1440;
        if (to <= from) to += 1440;
        if (from >= start && to <= end && to > from) {
          breakStart = from;
          breakEnd = to;
        }
      }
    }

    return DutyDaySpan(
      start: start,
      end: end,
      breakStart: breakStart,
      breakEnd: breakEnd,
    );
  }

  static (int, int)? _axis(DutyDaySpan? yours, DutyDaySpan? theirs) {
    final spans = [yours, theirs].whereType<DutyDaySpan>().toList();
    if (spans.isEmpty) return null;
    var start = spans.map((span) => span.start).reduce((a, b) => a < b ? a : b);
    var end = spans.map((span) => span.end).reduce((a, b) => a > b ? a : b);
    start -= 20;
    end += 20;
    if (end <= start) end = start + 60;
    return (start, end);
  }

  static String _headline(BillDuty yours, BillDuty theirs) {
    if (yours.shift == theirs.shift) return 'Same duty.';

    final work = _subtract(durationMinutes(theirs.work), durationMinutes(yours.work));
    final mixedNight = _crossesMidnight(yours) != _crossesMidnight(theirs);
    final finish = mixedNight
        ? null
        : _subtract(_endMinutes(theirs), _endMinutes(yours));
    final report = _subtract(clockMinutes(theirs.report), clockMinutes(yours.report));
    final clauses = <String>[];

    if (work != null && work != 0) {
      final who = work > 0 ? theirs.shift : yours.shift;
      clauses.add('$who has ${formatDelta(work.abs()).replaceFirst('+', '')} more work');
    }
    if (mixedNight) {
      final night = _crossesMidnight(theirs) ? theirs : yours;
      final day = _crossesMidnight(theirs) ? yours : theirs;
      final dayEnd = day.displaySignOff.isNotEmpty ? day.displaySignOff : day.displayFinish;
      clauses.add(
        '${night.shift} signs off the next morning, and ${day.shift} finishes at $dayEnd',
      );
    } else if (finish != null && finish != 0) {
      final who = finish > 0 ? theirs.shift : yours.shift;
      clauses.add(
        '$who finishes ${formatDelta(finish.abs()).replaceFirst('+', '')} later',
      );
    }

    if (clauses.isEmpty && report != null && report != 0) {
      final who = report > 0 ? theirs.shift : yours.shift;
      clauses.add(
        '$who reports ${formatDelta(report.abs()).replaceFirst('+', '')} later',
      );
    }

    if (clauses.isEmpty) {
      return 'Same work time and the same finish.';
    }
    if (clauses.length == 1) {
      final text = clauses.single;
      return '${text[0].toUpperCase()}${text.substring(1)}.';
    }
    final first = clauses[0];
    final second = clauses[1];
    final joined = '${first[0].toUpperCase()}${first.substring(1)}, and $second.';
    return joined;
  }

  static int? _subtract(int? theirs, int? yours) {
    if (theirs == null || yours == null) return null;
    return theirs - yours;
  }

  static bool _crossesMidnight(BillDuty duty) {
    final start = clockMinutes(duty.report) ?? clockMinutes(duty.depart);
    final end = clockMinutes(duty.signOff) ?? clockMinutes(duty.finish);
    return start != null && end != null && end < start;
  }

  static bool _sameNight(BillDuty yours, BillDuty theirs) =>
      _crossesMidnight(yours) == _crossesMidnight(theirs);

  static int? _endMinutes(BillDuty duty) {
    return _namedEnd(duty, duty.signOff) ?? _namedEnd(duty, duty.finish);
  }

  static int? _namedEnd(BillDuty duty, String raw) {
    final start = clockMinutes(duty.report) ?? clockMinutes(duty.depart);
    final end = clockMinutes(raw);
    if (end == null) return null;
    if (start != null && end < start) return end + 1440;
    return end;
  }

  static List<DutyCompareLine> _lines(BillDuty yours, BillDuty theirs) {
    return [
      _clockLine('Report', yours.report, theirs.report, yours.displayReport, theirs.displayReport),
      _clockLine(
        'Take up',
        yours.depart,
        theirs.depart,
        _withPlace(yours.displayDepart, yours.takeUpLocation),
        _withPlace(theirs.displayDepart, theirs.takeUpLocation),
      ),
      DutyCompareLine(
        label: 'Break',
        yours: _breakLabel(yours),
        theirs: _breakLabel(theirs),
        deltaMinutes: _subtract(_breakMinutes(theirs), _breakMinutes(yours)),
      ),
      DutyCompareLine(
        label: 'Finish',
        yours: _withPlace(yours.displayFinish, yours.endLocation),
        theirs: _withPlace(theirs.displayFinish, theirs.endLocation),
        deltaMinutes: _sameNight(yours, theirs)
            ? _subtract(
                _namedEnd(theirs, theirs.finish),
                _namedEnd(yours, yours.finish),
              )
            : null,
      ),
      if (yours.hasDistinctSignOff || theirs.hasDistinctSignOff)
        DutyCompareLine(
          label: 'Sign off',
          yours: yours.displaySignOff,
          theirs: theirs.displaySignOff,
          deltaMinutes: _sameNight(yours, theirs)
              ? _subtract(
                  _namedEnd(theirs, theirs.signOff),
                  _namedEnd(yours, yours.signOff),
                )
              : null,
        ),
      _durationLine('Work', yours.work, theirs.work, yours.displayWork, theirs.displayWork),
      _durationLine('Spread', yours.spread, theirs.spread, yours.displaySpread, theirs.displaySpread),
      _durationLine('Relief', yours.relief, theirs.relief, yours.displayRelief, theirs.displayRelief),
      if (yours.routesLabel.isNotEmpty || theirs.routesLabel.isNotEmpty)
        DutyCompareLine(
          label: 'Routes',
          yours: yours.routesLabel,
          theirs: theirs.routesLabel,
        ),
    ].where((line) => line.yours.isNotEmpty || line.theirs.isNotEmpty).toList();
  }

  static DutyCompareLine _clockLine(
    String label,
    String yoursRaw,
    String theirsRaw,
    String yoursShown,
    String theirsShown,
  ) {
    return DutyCompareLine(
      label: label,
      yours: yoursShown,
      theirs: theirsShown,
      deltaMinutes: _subtract(clockMinutes(theirsRaw), clockMinutes(yoursRaw)),
    );
  }

  static DutyCompareLine _durationLine(
    String label,
    String yoursRaw,
    String theirsRaw,
    String yoursShown,
    String theirsShown,
  ) {
    return DutyCompareLine(
      label: label,
      yours: yoursShown,
      theirs: theirsShown,
      deltaMinutes: _subtract(durationMinutes(theirsRaw), durationMinutes(yoursRaw)),
    );
  }

  static String _withPlace(String time, String place) {
    if (time.isEmpty) return place;
    if (place.isEmpty) return time;
    return '$time $place';
  }

  static String _breakLabel(BillDuty duty) {
    if (duty.isWorkout) return 'Workout';
    if (!duty.hasMealBreak) return '';
    final start = duty.displayStartBreak;
    final end = duty.displayFinishBreak;
    final times = [
      if (start.isNotEmpty) start,
      if (end.isNotEmpty) end,
    ].join('–');
    final startPlace = duty.breakStartLocation;
    final endPlace = duty.breakEndLocation;
    final place = startPlace.isEmpty
        ? endPlace
        : (endPlace.isEmpty || endPlace == startPlace)
            ? startPlace
            : '$startPlace → $endPlace';
    if (times.isEmpty) return place;
    if (place.isEmpty) return times;
    return '$times $place';
  }

  static int? _breakMinutes(BillDuty duty) {
    if (!duty.hasMealBreak) return duty.isWorkout ? 0 : null;
    final start = clockMinutes(duty.startBreak);
    final end = clockMinutes(duty.finishBreak);
    if (start == null || end == null) return null;
    final length = end < start ? end + 1440 - start : end - start;
    return length;
  }
}
