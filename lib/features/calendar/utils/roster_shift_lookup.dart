import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';

/// Roster-only shift letter (no rest-day swap overrides).
String rosterShiftForDate({
  required DateTime date,
  required DateTime? startDate,
  required int startWeek,
  required bool markedInEnabled,
  required String markedInStatus,
  required BankHoliday? Function(DateTime date) bankHolidayForDate,
}) {
  if (startDate == null) return '';

  if (markedInEnabled) {
    if (markedInStatus == 'M-F') {
      if (bankHolidayForDate(date) != null) return 'R';
      final weekday = date.weekday;
      if (weekday >= 1 && weekday <= 5) return 'W';
      return 'R';
    }
    if (markedInStatus == 'Shift') {
      return RosterService.getShiftForDate(date, startDate, startWeek);
    }
  }
  return RosterService.getShiftForDate(date, startDate, startWeek);
}

/// Whether rest-day badge/rate rules apply for [shiftResult].
bool isRosteredRestDay({
  required String shift,
  required bool isSwappedWork,
}) {
  if (shift != 'R') return false;
  if (isSwappedWork) return false;
  return true;
}
