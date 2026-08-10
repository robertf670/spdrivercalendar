import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/services/cache_service.dart';
import 'package:spdrivercalendar/features/calendar/services/calendar_holiday_cache.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/holiday.dart';

void main() {
  late CacheService cache;

  setUp(() {
    cache = CacheService();
    cache.clear();
  });

  test('caches bank holidays after first load', () async {
    var loads = 0;
    final service = CalendarHolidayCache(
      cacheService: cache,
      loadBankHolidays: () async {
        loads++;
        return [
          BankHoliday(date: DateTime(2026, 1, 1), name: 'NYD'),
        ];
      },
    );

    final first = await service.loadBankHolidays();
    final second = await service.loadBankHolidays();

    expect(loads, 1);
    expect(first, same(second));
    expect(first.single.name, 'NYD');
  });

  test('reloadHolidays clears caches and fetches fresh data', () async {
    var loads = 0;
    final cleared = <String>[];
    final service = CalendarHolidayCache(
      cacheService: cache,
      loadHolidays: () async {
        loads++;
        return [
          Holiday(
            id: 'h$loads',
            startDate: DateTime(2026, 8, 4),
            endDate: DateTime(2026, 8, 4),
            type: 'other',
          ),
        ];
      },
      clearStorageCacheForKey: cleared.add,
    );

    await service.loadHolidays();
    final reloaded = await service.reloadHolidays();

    expect(loads, 2);
    expect(cleared, contains(CalendarHolidayCache.holidaysStorageKey));
    expect(reloaded.single.id, 'h2');
  });
}
