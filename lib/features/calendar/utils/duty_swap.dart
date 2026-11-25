import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';
import 'package:spdrivercalendar/features/calendar/utils/jamestown_road.dart';
import 'package:spdrivercalendar/features/calendar/utils/marked_in_status.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

/// Zone label for the Add Work Shift picker, or null when this title is not a duty.
String? dutySwapZoneLabel(String title, {bool jamestown30hr = false}) {
  var code = title.trim();
  if (code.startsWith('Shift:')) {
    code = code.substring(6).trim();
  }
  code = code.replaceAll(RegExp(r'\s*\(OT\)\s*$'), '');
  if (code.toUpperCase().startsWith('UNI:')) {
    code = code.substring(4).trim();
  }
  if (JamestownRoad.isShiftCode(code)) {
    if (jamestown30hr && code.startsWith('811/')) {
      return JamestownFeatureService.zoneLabel;
    }
    return JamestownRoad.zoneLabel;
  }
  if (Zone2Duties.isRoute13Code(code)) return Zone2Duties.zoneLabel;
  if (Zone2Duties.isUniEuroCode(code)) return 'Uni/Euro';
  final zone = RegExp(r'^(?:PZ)?([134])/').firstMatch(code);
  if (zone != null) return 'Zone ${zone.group(1)}';
  return null;
}

/// Week checkbox for a repeated duty.
///
/// Jamestown in the dev menu counts on its own. Otherwise it is Jamestown,
/// Monday–Friday, or Shift. Spare, 4 day, and nights stay off.
bool showDutySwapWeekCheckbox({
  required bool markedInEnabled,
  required String status,
  required bool jamestownDevMenu,
}) {
  if (jamestownDevMenu) return true;
  return markedInEnabled && MarkedInStatus.showsWeekDutySwap(status);
}

/// Monday to Friday of the week that contains [date].
/// Saturday and Sunday keep their own duties.
List<DateTime> dutySwapWeekDays(DateTime date) {
  final sunday = RosterService.getSundayOfWeek(date);
  return [
    for (var offset = 1; offset <= 5; offset++)
      DateTime(sunday.year, sunday.month, sunday.day + offset),
  ];
}

/// Replaces the duty times and clears saved places so the new bill can load.
/// Notes, buses, and a late break stay on the day.
Event eventWithSwappedDuty({
  required Event event,
  required String title,
  required TimeOfDay startTime,
  required TimeOfDay endTime,
  required bool isNextDay,
  TimeOfDay? breakStartTime,
  TimeOfDay? breakEndTime,
  Duration? workTime,
  List<String>? routes,
}) {
  final day = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
  );
  final updated = event.detachedCopy();
  updated.title = title;
  updated.startDate = day;
  updated.startTime = startTime;
  updated.endTime = endTime;
  updated.endDate = isNextDay
      ? DateTime(day.year, day.month, day.day + 1)
      : day;
  updated.breakStartTime = breakStartTime;
  updated.breakEndTime = breakEndTime;
  updated.workTime = workTime;
  updated.routes = routes == null ? null : List<String>.from(routes);
  updated.startLocation = null;
  updated.finishLocation = null;
  updated.startBreakLocation = null;
  updated.finishBreakLocation = null;
  updated.dutyStartTime = null;
  return updated;
}
