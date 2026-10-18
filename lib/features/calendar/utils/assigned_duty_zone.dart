import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

/// Zone picker for spare / 22B assigned duties (Add Full Duty / halves).
class AssignedDutyZone {
  AssignedDutyZone._();

  static const options = [
    'Zone 1',
    Zone2Duties.zoneLabel,
    'Zone 3',
    'Zone 4',
    'Uni/Euro',
  ];

  static bool canLoadDuties({
    required String selectedZone,
    required DateTime date,
  }) {
    if (Zone2Duties.isZone(selectedZone)) {
      return Zone2Duties.canAddShiftsOn(date);
    }
    return true;
  }

  static String emptyDutiesMessage({
    required String selectedZone,
    required DateTime date,
  }) {
    if (Zone2Duties.isZone(selectedZone) &&
        !Zone2Duties.canAddShiftsOn(date)) {
      return Zone2Duties.availableFromMessage;
    }
    return 'No duties available for selected zone and date';
  }
}
