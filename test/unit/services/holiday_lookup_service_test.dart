import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_lookup_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:spdrivercalendar/models/holiday.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clear();
  });

  test('hasHolidayForDate detects covering holidays by type', () async {
    await HolidayService.addHoliday(
      Holiday(
        id: 'winter_1',
        startDate: DateTime(2026, 12, 20),
        endDate: DateTime(2026, 12, 27),
        type: 'winter',
      ),
    );

    expect(
      await HolidayLookupService.hasHolidayForDate(
        DateTime(2026, 12, 25),
        'winter',
      ),
      isTrue,
    );
    expect(
      await HolidayLookupService.hasHolidayForDate(
        DateTime(2026, 12, 25),
        'summer',
      ),
      isFalse,
    );
    expect(
      await HolidayLookupService.hasHolidayForDate(
        DateTime(2026, 12, 19),
        'winter',
      ),
      isFalse,
    );
  });

  test('getHolidayCountsForYears counts by start year and type', () async {
    await HolidayService.addHoliday(
      Holiday(
        id: 'w_2026',
        startDate: DateTime(2026, 12, 20),
        endDate: DateTime(2026, 12, 27),
        type: 'winter',
      ),
    );
    await HolidayService.addHoliday(
      Holiday(
        id: 'w_2027',
        startDate: DateTime(2027, 12, 19),
        endDate: DateTime(2027, 12, 26),
        type: 'winter',
      ),
    );
    await HolidayService.addHoliday(
      Holiday(
        id: 's_2026',
        startDate: DateTime(2026, 7, 5),
        endDate: DateTime(2026, 7, 12),
        type: 'summer',
      ),
    );

    final counts =
        await HolidayLookupService.getHolidayCountsForYears(2026, 'winter');

    expect(counts[2026], 1);
    expect(counts[2027], 1);
    expect(counts[2028], 0);
    expect(counts[2029], 0);
    expect(counts[2030], 0);
  });
}
