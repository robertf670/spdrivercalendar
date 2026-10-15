/// Bills zones shown in the Bills & Boards picker.
const billsZones = ['Zone 1', 'Zone 2', 'Zone 3', 'Zone 4', 'Uni/Euro'];

/// Zone the Bills screen should open on.
///
/// Shift / M-F marked-in uses that zone when it is on the Bills picker.
/// Spare, Jamestown, and anything else fall back to Zone 1.
String billsDefaultZone(String markedInZone) {
  if (billsZones.contains(markedInZone)) return markedInZone;
  return 'Zone 1';
}
