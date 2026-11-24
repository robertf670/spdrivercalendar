import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

/// One changed running-board stop. Empty strings clear that cell.
class BoardRowPatch {
  const BoardRowPatch({
    required this.index,
    required this.route,
    required this.place,
    required this.arrive,
    required this.depart,
  });

  final int index;
  final String route;
  final String place;
  final String arrive;
  final String depart;

  Map<String, dynamic> toMap() => {
        'index': index,
        'route': route,
        'place': place,
        'arrive': arrive,
        'depart': depart,
      };

  static BoardRowPatch? fromMap(Map<String, dynamic> data) {
    final index = data['index'];
    if (index is! int || index < 0) return null;
    return BoardRowPatch(
      index: index,
      route: data['route']?.toString() ?? '',
      place: data['place']?.toString() ?? '',
      arrive: data['arrive']?.toString() ?? '',
      depart: data['depart']?.toString() ?? '',
    );
  }
}

/// Changed bill columns. Null means the bundled value stays.
class BillFieldPatch {
  const BillFieldPatch({
    this.report,
    this.depart,
    this.location,
    this.startBreak,
    this.startBreakLocation,
    this.breakReport,
    this.finishBreak,
    this.finishBreakLocation,
    this.finish,
    this.finishLocation,
    this.signOff,
  });

  final String? report;
  final String? depart;
  final String? location;
  final String? startBreak;
  final String? startBreakLocation;
  final String? breakReport;
  final String? finishBreak;
  final String? finishBreakLocation;
  final String? finish;
  final String? finishLocation;
  final String? signOff;

  static const empty = BillFieldPatch();

  bool get isEmpty =>
      report == null &&
      depart == null &&
      location == null &&
      startBreak == null &&
      startBreakLocation == null &&
      breakReport == null &&
      finishBreak == null &&
      finishBreakLocation == null &&
      finish == null &&
      finishLocation == null &&
      signOff == null;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    void put(String key, String? value) {
      if (value != null) map[key] = value;
    }

    put('report', report);
    put('depart', depart);
    put('location', location);
    put('startBreak', startBreak);
    put('startBreakLocation', startBreakLocation);
    put('breakReport', breakReport);
    put('finishBreak', finishBreak);
    put('finishBreakLocation', finishBreakLocation);
    put('finish', finish);
    put('finishLocation', finishLocation);
    put('signOff', signOff);
    return map;
  }

  factory BillFieldPatch.fromMap(Map<String, dynamic>? data) {
    if (data == null) return empty;
    String? read(String key) => data.containsKey(key) ? data[key]?.toString() ?? '' : null;
    return BillFieldPatch(
      report: read('report'),
      depart: read('depart'),
      location: read('location'),
      startBreak: read('startBreak'),
      startBreakLocation: read('startBreakLocation'),
      breakReport: read('breakReport'),
      finishBreak: read('finishBreak'),
      finishBreakLocation: read('finishBreakLocation'),
      finish: read('finish'),
      finishLocation: read('finishLocation'),
      signOff: read('signOff'),
    );
  }
}

/// A bill or board correction stored in Firebase. The bundled files stay
/// in the app and are used when no correction exists.
class DutyCorrection {
  const DutyCorrection({
    required this.duty,
    required this.dayKey,
    this.era,
    this.report,
    this.depart,
    this.signoff,
    this.boardRows = const [],
    this.bill = BillFieldPatch.empty,
  });

  static const zone4CurrentEra = '20260823';
  static const zone4PreviousEra = '20251019';
  static const zone4LegacyEra = 'legacy';

  final String duty;
  final String dayKey;

  /// Zone 4 file era. Empty for Zone 1, Zone 3, and Route 13.
  final String? era;
  final String? report;
  final String? depart;
  final String? signoff;
  final List<BoardRowPatch> boardRows;
  final BillFieldPatch bill;

  bool get isEmpty =>
      report == null &&
      depart == null &&
      signoff == null &&
      boardRows.isEmpty &&
      bill.isEmpty;

  static bool supports(String duty) {
    if (Zone2Duties.isRoute13Code(duty)) return true;
    return RegExp(r'^PZ[134]/').hasMatch(duty.trim());
  }

  static String canonicalDuty(String duty) {
    if (Zone2Duties.isRoute13Code(duty)) return Zone2Duties.canonical(duty);
    return duty.trim();
  }

  /// Which Zone 4 bill and board a date uses. Null for the other zones.
  static String? eraFor(String duty, DateTime date) {
    if (!canonicalDuty(duty).startsWith('PZ4/')) return null;
    final day = DateTime(date.year, date.month, date.day);
    if (!day.isBefore(DateTime(2026, 8, 23))) return zone4CurrentEra;
    if (!day.isBefore(DateTime(2025, 10, 19))) return zone4PreviousEra;
    return zone4LegacyEra;
  }

  static DateTime dateForEra(String? era) {
    switch (era) {
      case zone4PreviousEra:
        return DateTime(2026, 1, 12);
      case zone4LegacyEra:
        return DateTime(2025, 6, 2);
      default:
        return DateTime(2026, 8, 24);
    }
  }

  static String documentId(String duty, String dayKey, {String? era}) {
    final code = canonicalDuty(duty).replaceAll('/', '-');
    if (era == null || era.isEmpty) return '${code}_$dayKey';
    return '${code}_${dayKey}_$era';
  }

  Map<String, dynamic> toFirestore() => {
        'duty': canonicalDuty(duty),
        'dayKey': dayKey,
        if (era != null && era!.isNotEmpty) 'era': era,
        if (report != null) 'report': report,
        if (depart != null) 'depart': depart,
        if (signoff != null) 'signoff': signoff,
        'boardRows': boardRows.map((row) => row.toMap()).toList(),
        if (!bill.isEmpty) 'bill': bill.toMap(),
      };

  factory DutyCorrection.fromFirestore(Map<String, dynamic> data) {
    final rows = <BoardRowPatch>[];
    final rawRows = data['boardRows'];
    if (rawRows is List) {
      for (final raw in rawRows) {
        if (raw is! Map) continue;
        final patch = BoardRowPatch.fromMap(Map<String, dynamic>.from(raw));
        if (patch != null) rows.add(patch);
      }
    }
    final billRaw = data['bill'];
    return DutyCorrection(
      duty: data['duty']?.toString() ?? '',
      dayKey: data['dayKey']?.toString() ?? '',
      era: data['era']?.toString(),
      report: data.containsKey('report') ? data['report']?.toString() ?? '' : null,
      depart: data.containsKey('depart') ? data['depart']?.toString() ?? '' : null,
      signoff: data.containsKey('signoff') ? data['signoff']?.toString() ?? '' : null,
      boardRows: rows,
      bill: billRaw is Map
          ? BillFieldPatch.fromMap(Map<String, dynamic>.from(billRaw))
          : BillFieldPatch.empty,
    );
  }
}
