import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

/// Bills zones shown in the Bills & Boards picker.
const billsZones = ['Zone 1', 'Route 13', 'Zone 3', 'Zone 4', 'Uni/Euro'];

/// Zone the Bills screen should open on.
///
/// Shift / M-F marked-in uses that zone when it is on the Bills picker.
/// Spare, Jamestown, and anything else fall back to Zone 1.
String billsDefaultZone(String markedInZone) {
  final zone = Zone2Duties.normalizeZoneLabel(markedInZone);
  if (billsZones.contains(zone)) return zone;
  return 'Zone 1';
}
