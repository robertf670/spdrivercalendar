import 'package:spdrivercalendar/core/services/cache_service.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/holiday.dart';

/// Cache keys and loaders for calendar holiday data.
class CalendarHolidayCache {
  static const bankHolidaysKey = 'bank_holidays';
  static const holidaysListKey = 'holidays_list_cache';
  static const holidaysStorageKey = 'holidays';

  CalendarHolidayCache({
    CacheService? cacheService,
    Future<List<BankHoliday>> Function()? loadBankHolidays,
    Future<List<Holiday>> Function()? loadHolidays,
    void Function(String key)? clearStorageCacheForKey,
  })  : _cacheService = cacheService ?? CacheService(),
        _loadBankHolidays = loadBankHolidays ?? RosterService.loadBankHolidays,
        _loadHolidays = loadHolidays ?? HolidayService.getHolidays,
        _clearStorageCacheForKey =
            clearStorageCacheForKey ?? StorageService.clearCacheForKey;

  final CacheService _cacheService;
  final Future<List<BankHoliday>> Function() _loadBankHolidays;
  final Future<List<Holiday>> Function() _loadHolidays;
  final void Function(String key) _clearStorageCacheForKey;

  Future<List<BankHoliday>> loadBankHolidays() async {
    final cached = _cacheService.get<List<BankHoliday>>(bankHolidaysKey);
    if (cached != null) return cached;

    final holidays = await _loadBankHolidays();
    _cacheService.set(
      bankHolidaysKey,
      holidays,
      expiration: const Duration(hours: 24),
    );
    return holidays;
  }

  Future<List<Holiday>> loadHolidays() async {
    final cached = _cacheService.get<List<Holiday>>(holidaysListKey);
    if (cached != null) return cached;

    final holidays = await _loadHolidays();
    _cacheService.set(
      holidaysListKey,
      holidays,
      expiration: const Duration(hours: 24),
    );
    return holidays;
  }

  /// Bypasses caches and returns fresh holiday rows.
  Future<List<Holiday>> reloadHolidays() async {
    _cacheService.remove(holidaysListKey);
    _clearStorageCacheForKey(holidaysStorageKey);
    return _loadHolidays();
  }
}
