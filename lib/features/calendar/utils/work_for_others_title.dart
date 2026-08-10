/// Builds the calendar event title for a Work For Others shift.
String buildWorkForOthersTitle({
  required String selectedZone,
  required String selectedShiftNumber,
}) {
  var title = selectedShiftNumber;
  if (selectedZone != 'Uni/Euro' && !title.startsWith('PZ')) {
    final zoneNum = selectedZone.replaceAll('Zone ', '');
    title = 'PZ$zoneNum/$title';
  }
  return title;
}
