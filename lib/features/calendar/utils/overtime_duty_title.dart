/// Builds the calendar event title for an overtime duty.
String buildOvertimeDutyTitle({
  required String selectedShiftNumber,
  required String overtimeHalfType,
}) {
  final isEATypeTraining = selectedShiftNumber.contains('EA Type Training');
  if (isEATypeTraining) {
    return '$selectedShiftNumber (OT)';
  }
  return '$selectedShiftNumber$overtimeHalfType (OT)';
}
