/// Zone 2 (Route 13) duty availability.
class Zone2Duties {
  Zone2Duties._();

  static const zoneLabel = 'Zone 2';

  /// First calendar day drivers can add Zone 2 shifts.
  static final DateTime addShiftsFrom = DateTime(2026, 10, 10);

  static const availableFromMessage = 'Available from 10 Oct 2026';

  static bool canAddShiftsOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final from = DateTime(
      addShiftsFrom.year,
      addShiftsFrom.month,
      addShiftsFrom.day,
    );
    return !day.isBefore(from);
  }
}
