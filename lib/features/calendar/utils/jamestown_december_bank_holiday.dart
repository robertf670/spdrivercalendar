import 'package:spdrivercalendar/models/bank_holiday.dart';

/// 28 December 2026 only. An internal Jamestown payment bank holiday.
class JamestownDecemberBankHoliday {
  JamestownDecemberBankHoliday._();

  static final DateTime date = DateTime(2026, 12, 28);
  static const name = 'Bank Holiday';

  static bool isDate(DateTime value) =>
      value.year == date.year &&
      value.month == date.month &&
      value.day == date.day;

  /// Current setting only. A 311 or 811 already on the calendar does not count:
  /// drivers work rest days there, and people leave Jamestown.
  static bool qualifies({
    required bool devMenuEnabled,
    required bool markedInJamestown,
  }) =>
      devMenuEnabled || markedInJamestown;

  static BankHoliday holiday() => BankHoliday(name: name, date: date);
}
