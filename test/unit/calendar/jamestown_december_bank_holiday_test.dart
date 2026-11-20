import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/jamestown_december_bank_holiday.dart';
import 'package:spdrivercalendar/services/jamestown_december_bank_holiday_gate.dart';

void main() {
  tearDown(JamestownDecemberBankHolidayGate.resetForTest);

  test('28 December 2026 is the only date', () {
    expect(
      JamestownDecemberBankHoliday.isDate(DateTime(2026, 12, 28)),
      isTrue,
    );
    expect(
      JamestownDecemberBankHoliday.isDate(DateTime(2025, 12, 28)),
      isFalse,
    );
    expect(
      JamestownDecemberBankHoliday.isDate(DateTime(2027, 12, 28)),
      isFalse,
    );
    expect(
      JamestownDecemberBankHoliday.isDate(DateTime(2026, 12, 27)),
      isFalse,
    );
  });

  test('only the current Jamestown setting qualifies', () {
    expect(
      JamestownDecemberBankHoliday.qualifies(
        devMenuEnabled: false,
        markedInJamestown: false,
      ),
      isFalse,
    );
    expect(
      JamestownDecemberBankHoliday.qualifies(
        devMenuEnabled: true,
        markedInJamestown: false,
      ),
      isTrue,
    );
    expect(
      JamestownDecemberBankHoliday.qualifies(
        devMenuEnabled: false,
        markedInJamestown: true,
      ),
      isTrue,
    );
  });

  test('the extra bank holiday is hidden unless Jamestown applies', () {
    final date = DateTime(2026, 12, 28);
    expect(ShiftService.getBankHoliday(date, const []), isNull);

    JamestownDecemberBankHolidayGate.devMenuEnabled = true;
    final holiday = ShiftService.getBankHoliday(date, const []);
    expect(holiday, isNotNull);
    expect(holiday!.name, 'Bank Holiday');
    expect(holiday.matchesDate(date), isTrue);
    expect(
      ShiftService.getBankHoliday(DateTime(2025, 12, 28), const []),
      isNull,
    );
  });
}
