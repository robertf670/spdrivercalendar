import 'package:spdrivercalendar/models/universal_board.dart';

/// Maps Zone 1/3/4 board JSON (from shift lookup) into [UniversalBoard]
/// so the existing Uni/Euro board dialog can render it.
class ZoneBoardMapper {
  ZoneBoardMapper._();

  /// Day-type key used in Zone*_Boards.json: MON-FRI / SAT / SUN.
  static String dayKeyForDate(
    DateTime date, {
    required bool isSaturdayService,
    required bool isBankHoliday,
  }) {
    if (isSaturdayService || date.weekday == DateTime.saturday) {
      return 'SAT';
    }
    if (isBankHoliday || date.weekday == DateTime.sunday) {
      return 'SUN';
    }
    return 'MON-FRI';
  }

  /// Normalizes event titles like `PZ1/01A (OT)` → `PZ1/01`.
  static String? normalizeDutyCode(String title) {
    var code = title.trim();
    if (code.isEmpty) return null;

    code = code.replaceAll(RegExp(r'\s*\(OT\)\s*$'), '');

    // Strip OT half suffix A/B, but keep X duties (e.g. PZ1/10X).
    final halfMatch = RegExp(r'^(PZ[134]/\d+X?)[AB]$').firstMatch(code);
    if (halfMatch != null) {
      code = halfMatch.group(1)!;
    }

    if (!RegExp(r'^PZ[134]/\S+$').hasMatch(code)) {
      return null;
    }
    return code;
  }

  /// Asset path for a normalized duty code, or null if unsupported.
  static String? assetPathForDuty(String dutyCode) {
    if (dutyCode.startsWith('PZ1/')) {
      return 'assets/Zone1_Boards.json';
    }
    if (dutyCode.startsWith('PZ3/')) {
      return 'assets/Zone3_Boards.json';
    }
    if (dutyCode.startsWith('PZ4/')) {
      return 'assets/Zone4_Boards.json';
    }
    return null;
  }

  static UniversalBoard? fromDayData(
    String shift,
    Map<String, dynamic> dayData,
  ) {
    final boardRows = dayData['board'];
    if (boardRows is! List || boardRows.isEmpty) {
      return null;
    }

    final duty = dayData['duty']?.toString();
    final signoff = _nonEmpty(dayData['signoff']?.toString());

    final sections = <BoardSection>[];
    var entries = <BoardEntry>[];
    var sectionType = 'firstHalf';

    void flushSection() {
      if (entries.isEmpty) return;
      sections.add(
        BoardSection(type: sectionType, entries: List<BoardEntry>.from(entries)),
      );
      entries = <BoardEntry>[];
    }

    for (final rawRow in boardRows) {
      if (rawRow is! List) continue;
      final cells = rawRow.map((e) => e?.toString() ?? '').toList();
      while (cells.length < 6) {
        cells.add('');
      }

      final route = cells[0].trim();
      final f1 = cells[1].trim();
      final place = cells[3].trim();
      final arr = cells[4].trim();
      final dep = cells[5].trim();

      if (route == '---') {
        flushSection();
        sectionType = 'secondHalf';
        continue;
      }

      final isFinish = route.isEmpty && f1 == 'Finish';
      final isDutyHdr = route.isEmpty && f1 == 'Duty' && place.length > 4;
      final isLongNote =
          route.isEmpty && arr.isEmpty && dep.isEmpty && place.length > 18;

      if (isFinish) {
        entries.add(
          BoardEntry(
            action: 'Finish',
            time: signoff,
          ),
        );
        continue;
      }

      if (isDutyHdr || isLongNote) {
        final reportEntry = _reportFromNote(place);
        if (reportEntry != null) {
          entries.add(reportEntry);
        } else if (place.isNotEmpty) {
          entries.add(BoardEntry(action: place));
        }
        continue;
      }

      if (route.isEmpty && place.isEmpty && arr.isEmpty && dep.isEmpty) {
        continue;
      }

      final placeLower = place.toLowerCase();
      if (placeLower.contains('departs garage')) {
        entries.add(
          BoardEntry(
            action: 'Depart Garage',
            time: _firstTime(dep, arr),
            location: 'Garage',
            // SPL is not a passenger route — don't show "Route SPL".
            route: _displayRoute(route),
          ),
        );
        continue;
      }

      final hasArr = arr.isNotEmpty;
      final hasDep = dep.isNotEmpty;

      if (route.isNotEmpty && hasDep && !hasArr) {
        entries.add(_routeEntry(
          route: route,
          time: dep,
          location: place.isNotEmpty ? place : null,
        ));
        continue;
      }

      if (hasArr && !hasDep) {
        entries.add(
          BoardEntry(
            action: 'Arrive',
            time: arr,
            location: place.isNotEmpty ? place : null,
            route: _displayRoute(route),
          ),
        );
        continue;
      }

      if (hasArr && hasDep) {
        // Rare: show depart as route time when a route is present.
        if (route.isNotEmpty) {
          entries.add(_routeEntry(
            route: route,
            time: dep,
            location: place.isNotEmpty ? place : null,
            notes: 'Arrive $arr',
          ));
        } else {
          entries.add(
            BoardEntry(
              action: place.isNotEmpty ? place : 'Arrive',
              time: arr,
              notes: 'Depart $dep',
            ),
          );
        }
        continue;
      }

      if (place.isNotEmpty) {
        entries.add(
          BoardEntry(
            action: place,
            time: _firstTime(dep, arr),
            route: _displayRoute(route),
          ),
        );
      }
    }

    flushSection();
    if (sections.isEmpty) {
      return null;
    }

    // Many short duties put only "Finish" after the Part 2 divider.
    // Fold that into the previous section so the dialog isn't a lone
    // "Second Half" with a single Finish row.
    _mergeTrailingFinishOnlySection(sections);

    return UniversalBoard(
      shift: shift,
      duty: duty,
      sections: sections,
    );
  }

  static void _mergeTrailingFinishOnlySection(List<BoardSection> sections) {
    if (sections.length < 2) return;
    final last = sections.last;
    if (last.type != 'secondHalf') return;
    final onlyFinish = last.entries.isNotEmpty &&
        last.entries.every((e) => e.action == 'Finish');
    if (!onlyFinish) return;

    final previous = sections[sections.length - 2];
    sections[sections.length - 2] = BoardSection(
      type: previous.type,
      entries: [...previous.entries, ...last.entries],
    );
    sections.removeLast();
  }

  static BoardEntry? _reportFromNote(String place) {
    final atMatch = RegExp(
      r'Reports?\s+at\s+(\d{2}:\d{2})',
      caseSensitive: false,
    ).firstMatch(place);
    if (atMatch != null) {
      return BoardEntry(action: 'Report', time: atMatch.group(1));
    }

    final bareMatch = RegExp(
      r'Reports?\s+(\d{2}:\d{2})',
      caseSensitive: false,
    ).firstMatch(place);
    if (bareMatch != null) {
      String? location;
      final after = place.substring(bareMatch.end).trim();
      if (after.isNotEmpty) {
        location = after;
      }
      return BoardEntry(
        action: 'Report',
        time: bareMatch.group(1),
        location: location,
      );
    }
    return null;
  }

  static String? _firstTime(String a, String b) {
    if (a.isNotEmpty) return a;
    if (b.isNotEmpty) return b;
    return null;
  }

  static String? _nonEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  static bool _isSpl(String route) => route.toUpperCase() == 'SPL';

  /// Passenger route badge value, or null for SPL (shown as action text instead).
  static String? _displayRoute(String route) {
    if (route.isEmpty || _isSpl(route)) return null;
    return route;
  }

  /// SPL is a special working, not a route number — show "SPL" not "Route SPL".
  static BoardEntry _routeEntry({
    required String route,
    String? time,
    String? location,
    String? notes,
  }) {
    if (_isSpl(route)) {
      return BoardEntry(
        action: 'SPL',
        time: time,
        location: location,
        notes: notes,
      );
    }
    return BoardEntry(
      action: 'Route',
      time: time,
      location: location,
      route: route,
      notes: notes,
    );
  }
}
