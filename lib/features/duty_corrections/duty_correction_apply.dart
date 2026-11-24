import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/duty_corrections/duty_correction.dart';

/// Applies a stored correction on top of a bundled bill row or board day.
class DutyCorrectionApply {
  DutyCorrectionApply._();

  static const _billColumns = <String, int>{
    'report': 2,
    'depart': 3,
    'location': 4,
    'startBreak': 5,
    'startBreakLocation': 6,
    'breakReport': 7,
    'finishBreak': 8,
    'finishBreakLocation': 9,
    'finish': 10,
    'finishLocation': 11,
    'signOff': 12,
  };

  static Map<String, dynamic> boardDay(
    Map<String, dynamic> day,
    DutyCorrection? correction,
  ) {
    if (correction == null || correction.isEmpty) return day;
    final next = Map<String, dynamic>.from(day);
    if (correction.report != null) next['report'] = correction.report;
    if (correction.depart != null) next['depart'] = correction.depart;
    if (correction.signoff != null) next['signoff'] = correction.signoff;

    final board = day['board'];
    if (board is! List) return next;

    final rows = <List<dynamic>>[];
    for (final raw in board) {
      if (raw is List) {
        final row = raw.map((cell) => cell?.toString() ?? '').toList();
        if (row.length > 3) {
          row[3] = _rewriteDutyNote(
            row[3],
            report: correction.report,
            depart: correction.depart,
          );
        }
        rows.add(row);
      } else {
        rows.add(<dynamic>[]);
      }
    }
    for (final patch in correction.boardRows) {
      if (patch.index < 0 || patch.index >= rows.length) continue;
      final row = rows[patch.index];
      while (row.length < 6) {
        row.add('');
      }
      row[0] = patch.route;
      row[3] = patch.place;
      row[4] = patch.arrive;
      row[5] = patch.depart;
    }
    next['board'] = rows;
    return next;
  }

  static String _rewriteDutyNote(
    String place, {
    String? report,
    String? depart,
  }) {
    var next = place;
    if (report != null && report.isNotEmpty) {
      next = next.replaceFirstMapped(
        RegExp(r'(Reports?\s+at\s+)\d{1,2}:\d{2}', caseSensitive: false),
        (match) => '${match.group(1)}$report',
      );
    }
    if (depart != null && depart.isNotEmpty) {
      next = next.replaceFirstMapped(
        RegExp(r'(Takes\s+up\s+at\s+)\d{1,2}:\d{2}', caseSensitive: false),
        (match) => '${match.group(1)}$depart',
      );
    }
    return next;
  }

  static List<String> csvParts(
    List<String> parts,
    DutyCorrection? correction,
  ) {
    final bill = correction?.bill;
    if (bill == null || bill.isEmpty) return parts;
    final next = List<String>.from(parts);
    void setColumn(String key, String? value) {
      if (value == null) return;
      final index = _billColumns[key];
      if (index == null) return;
      while (next.length <= index) {
        next.add('');
      }
      next[index] = value;
    }

    setColumn('report', bill.report);
    setColumn('depart', bill.depart);
    setColumn('location', bill.location);
    setColumn('startBreak', bill.startBreak);
    setColumn('startBreakLocation', bill.startBreakLocation);
    setColumn('breakReport', bill.breakReport);
    setColumn('finishBreak', bill.finishBreak);
    setColumn('finishBreakLocation', bill.finishBreakLocation);
    setColumn('finish', bill.finish);
    setColumn('finishLocation', bill.finishLocation);
    setColumn('signOff', bill.signOff);
    return next;
  }

  static BillDuty billDuty(BillDuty duty, DutyCorrection? correction) {
    final bill = correction?.bill;
    if (bill == null || bill.isEmpty) return duty;
    return BillDuty(
      shift: duty.shift,
      dutyNumber: duty.dutyNumber,
      report: bill.report ?? duty.report,
      depart: bill.depart ?? duty.depart,
      location: bill.location ?? duty.location,
      startBreak: bill.startBreak ?? duty.startBreak,
      startBreakLocation: bill.startBreakLocation ?? duty.startBreakLocation,
      breakReport: bill.breakReport ?? duty.breakReport,
      finishBreak: bill.finishBreak ?? duty.finishBreak,
      finishBreakLocation: bill.finishBreakLocation ?? duty.finishBreakLocation,
      finish: bill.finish ?? duty.finish,
      finishLocation: bill.finishLocation ?? duty.finishLocation,
      signOff: bill.signOff ?? duty.signOff,
      spread: duty.spread,
      work: duty.work,
      relief: duty.relief,
      routes: duty.routes,
    );
  }
}
