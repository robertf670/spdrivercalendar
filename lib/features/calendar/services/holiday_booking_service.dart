import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/services/days_in_lieu_service.dart';

typedef HolidayAdder = Future<void> Function(Holiday holiday);
typedef DayInLieuAddedHook = Future<void> Function();

/// Creates holiday records for the Add Holidays flows.
class HolidayBookingService {
  HolidayBookingService({
    HolidayAdder? addHoliday,
    DayInLieuAddedHook? onDayInLieuAdded,
    DateTime Function()? now,
  })  : _addHoliday = addHoliday ?? HolidayService.addHoliday,
        _onDayInLieuAdded =
            onDayInLieuAdded ?? DaysInLieuService.onDayInLieuAdded,
        _now = now ?? DateTime.now;

  final HolidayAdder _addHoliday;
  final DayInLieuAddedHook _onDayInLieuAdded;
  final DateTime Function() _now;

  Future<void> addWinterHoliday(DateTime startSunday) {
    final holiday = Holiday(
      id: _now().millisecondsSinceEpoch.toString(),
      startDate: startSunday,
      endDate: startSunday.add(const Duration(days: 6)),
      type: 'winter',
    );
    return _addHoliday(holiday);
  }

  Future<void> addSummerHoliday({
    required DateTime startSunday,
    required int durationWeeks,
  }) {
    final daysToAdd = durationWeeks == 1 ? 6 : 13;
    final holiday = Holiday(
      id: _now().millisecondsSinceEpoch.toString(),
      startDate: startSunday,
      endDate: startSunday.add(Duration(days: daysToAdd)),
      type: 'summer',
    );
    return _addHoliday(holiday);
  }

  /// Adds one holiday per date. Continues after individual failures.
  Future<int> addSingleDayHolidays({
    required List<DateTime> sortedDates,
    required String type,
    required String idPrefix,
    bool notifyDayInLieu = false,
  }) async {
    var successCount = 0;
    for (final date in sortedDates) {
      try {
        final holiday = Holiday(
          id: '${idPrefix}_${date.millisecondsSinceEpoch}',
          startDate: date,
          endDate: date,
          type: type,
        );
        await _addHoliday(holiday);
        if (notifyDayInLieu) {
          await _onDayInLieuAdded();
        }
        successCount++;
      } catch (_) {
        // Continue with other dates even if one fails
      }
    }
    return successCount;
  }
}
