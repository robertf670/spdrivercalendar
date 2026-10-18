import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

/// Builds the calendar event title for a Work For Others shift.
String buildWorkForOthersTitle({
  required String selectedZone,
  required String selectedShiftNumber,
}) {
  if (Zone2Duties.isZone(selectedZone)) {
    return Zone2Duties.canonical(
      selectedShiftNumber.contains('/')
          ? selectedShiftNumber
          : '${Zone2Duties.dutyPrefix}$selectedShiftNumber',
    );
  }
  var title = selectedShiftNumber;
  if (selectedZone != 'Uni/Euro' && !title.startsWith('PZ')) {
    final zoneNum = Zone2Duties.fileZoneNumber(selectedZone);
    title = 'PZ$zoneNum/$title';
  }
  return title;
}
