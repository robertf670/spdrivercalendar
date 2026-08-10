/// Pure display helpers for sick-day status values used by the calendar.
class SickDayDisplay {
  SickDayDisplay._();

  static String typeLabel(String type) {
    switch (type) {
      case 'normal':
        return 'Normal Sick Day';
      case 'self-certified':
        return 'Self-Certified Sick Day';
      case 'force-majeure':
        return 'Force Majeure';
      default:
        return type;
    }
  }

  /// Returns `S`, `SC`, `FM`, or an empty string for unknown/null values.
  static String displayCode(String? sickDayType) {
    if (sickDayType == null) return '';
    switch (sickDayType) {
      case 'normal':
        return 'S';
      case 'self-certified':
        return 'SC';
      case 'force-majeure':
        return 'FM';
      default:
        return '';
    }
  }
}
