import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/marked_in_status.dart';
import 'package:spdrivercalendar/features/calendar/utils/nights_roster.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';

/// Roster-only shift letter (no rest-day swap overrides).
String rosterShiftForDate({
  required DateTime date,
  required DateTime? startDate,
  required int startWeek,
  required bool markedInEnabled,
  required String markedInStatus,
  required BankHoliday? Function(DateTime date) bankHolidayForDate,
  DateTime? nightsAnchorSunday,
  int nightsWeekIndex = 0,
}) {
  if (markedInStatus == MarkedInStatus.nights) {
    if (nightsAnchorSunday == null) return '';
    return NightsRoster.shiftForDate(
      date: date,
      anchorSunday: nightsAnchorSunday,
      anchorWeekIndex: nightsWeekIndex,
    );
  }

  if (MarkedInStatus.isFixedWorkPattern(markedInStatus)) {
    if (bankHolidayForDate(date) != null) return 'R';
    return MarkedInStatus.isWorkDay(markedInStatus, date) ? 'W' : 'R';
  }

  if (startDate == null) return '';

  if (markedInEnabled && markedInStatus == MarkedInStatus.shift) {
    return RosterService.getShiftForDate(date, startDate, startWeek);
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
