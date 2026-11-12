import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_day_exclusion.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/services/annual_leave_service.dart';
import 'package:spdrivercalendar/services/days_in_lieu_service.dart';

typedef HolidayListLoader = Future<List<Holiday>> Function();
typedef HolidayRemover = Future<void> Function(String id);
typedef HolidayAdder = Future<void> Function(Holiday holiday);
typedef AnnualLeaveDayCheck = Future<bool> Function(DateTime date);
typedef DayInLieuIncrement = Future<int> Function([int amount]);

/// Takes one date out of any holiday that covers it.
///
/// A winter, summer, or other day that counted as annual leave is kept as one day in lieu.
class HolidayDayExclusionService {
  HolidayDayExclusionService({
    HolidayListLoader? loadHolidays,
    HolidayRemover? removeHoliday,
    HolidayAdder? addHoliday,
    AnnualLeaveDayCheck? consumesAnnualLeave,
    DayInLieuIncrement? incrementDaysInLieu,
    DateTime Function()? now,
  })  : _loadHolidays = loadHolidays ?? HolidayService.getHolidays,
        _removeHoliday = removeHoliday ?? HolidayService.removeHoliday,
        _addHoliday = addHoliday ?? HolidayService.addHoliday,
        _consumesAnnualLeave =
            consumesAnnualLeave ?? AnnualLeaveService.consumesAnnualLeaveOn,
        _incrementDaysInLieu =
            incrementDaysInLieu ?? DaysInLieuService.incrementBalance,
        _now = now ?? DateTime.now;

  final HolidayListLoader _loadHolidays;
  final HolidayRemover _removeHoliday;
  final HolidayAdder _addHoliday;
  final AnnualLeaveDayCheck _consumesAnnualLeave;
  final DayInLieuIncrement _incrementDaysInLieu;
  final DateTime Function() _now;

  /// Returns true when a holiday day was removed.
  Future<bool> excludeDay(DateTime day) async {
    final holidays = await _loadHolidays();
    final covering = holidays.where((holiday) => holiday.containsDate(day)).toList();
    if (covering.isEmpty) return false;

    final creditDayInLieu = await _consumesAnnualLeave(day);
    final stamp = _now().millisecondsSinceEpoch.toString();
    for (final holiday in covering) {
      final pieces = holidayExcludingDay(holiday, day, idStamp: stamp);
      await _removeHoliday(holiday.id);
      for (final piece in pieces) {
        await _addHoliday(piece);
      }
    }
    if (creditDayInLieu) {
      await _incrementDaysInLieu();
    }
    return true;
  }
}
