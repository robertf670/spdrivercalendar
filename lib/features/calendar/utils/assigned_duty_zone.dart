import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

/// Zone picker for spare / 22B assigned duties (Add Full Duty / halves).
class AssignedDutyZone {
  AssignedDutyZone._();

  static const options = [
    'Zone 1',
    'Zone 2',
    'Zone 3',
    'Zone 4',
    'Uni/Euro',
  ];

  static bool canLoadDuties({
    required String selectedZone,
    required DateTime date,
  }) {
    if (selectedZone == Zone2Duties.zoneLabel) {
      return Zone2Duties.canAddShiftsOn(date);
    }
    return true;
  }

  static String emptyDutiesMessage({
    required String selectedZone,
    required DateTime date,
  }) {
    if (selectedZone == Zone2Duties.zoneLabel &&
        !Zone2Duties.canAddShiftsOn(date)) {
      return Zone2Duties.availableFromMessage;
    }
    return 'No duties available for selected zone and date';
  }
}
