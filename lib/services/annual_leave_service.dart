import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:spdrivercalendar/models/holiday.dart';

class AnnualLeaveService {
  /// Get the current balance of annual leave days
  static Future<int> getBalance() async {
    return await StorageService.getInt(AppConstants.annualLeaveBalanceKey, defaultValue: 0);
  }

  /// Set the balance of annual leave days
  static Future<void> setBalance(int balance) async {
    if (balance < 0) {
      balance = 0;
    }
    await StorageService.saveInt(AppConstants.annualLeaveBalanceKey, balance);
  }

  /// Increment the balance by the specified amount (default 1)
  static Future<int> incrementBalance([int amount = 1]) async {
    final currentBalance = await getBalance();
    final newBalance = currentBalance + amount;
    await setBalance(newBalance);
    return newBalance;
  }

  /// Decrement the balance by the specified amount (default 1)
  static Future<int> decrementBalance([int amount = 1]) async {
    final currentBalance = await getBalance();
    final newBalance = (currentBalance - amount).clamp(0, double.infinity).toInt();
    await setBalance(newBalance);
    return newBalance;
  }

  /// Check if a date is a bank holiday
  static Future<bool> _isBankHoliday(DateTime date) async {
    try {
      final bankHolidaysData = await rootBundle.loadString('assets/bank_holidays.json');
      final bankHolidays = json.decode(bankHolidaysData);

      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final yearEntry = (bankHolidays['IrelandBankHolidays'] as List)
          .firstWhere((entry) => entry['year'] == date.year, orElse: () => null);

      if (yearEntry == null) return false;

      return (yearEntry['holidays'] as List).any((holiday) => holiday['date'] == dateStr);
    } catch (e) {
      return false;
    }
  }

  /// Check if user is on M-F schedule (through marked-in status)
  static Future<bool> _isOnMFSchedule() async {
    final markedInEnabled = await StorageService.getBool(AppConstants.markedInEnabledKey);
    if (markedInEnabled) {
      final markedInStatus = await StorageService.getString(AppConstants.markedInStatusKey) ?? '';
      return markedInStatus == 'M-F';
    }
    return false;
  }

  /// Working days in one winter/summer/other holiday period (full range).
  static Future<int> _workingDaysInAnnualLeaveHoliday(Holiday holiday, bool isMFSchedule) async {
    final startDateNormalized = DateTime(
      holiday.startDate.year,
      holiday.startDate.month,
      holiday.startDate.day,
    );
    final endDateNormalized = DateTime(
      holiday.endDate.year,
      holiday.endDate.month,
      holiday.endDate.day,
    );

    if (isMFSchedule) {
      int workingDays = 0;
      DateTime currentDate = startDateNormalized;
      while (!currentDate.isAfter(endDateNormalized)) {
        final weekday = currentDate.weekday;
        if (weekday >= 1 && weekday <= 5) {
          final isBankHolidayDate = await _isBankHoliday(currentDate);
          if (!isBankHolidayDate) {
            workingDays++;
          }
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }
      return workingDays;
    } else {
      final calendarDays = endDateNormalized.difference(startDateNormalized).inDays + 1;
      return ((calendarDays / 7) * 5).round();
    }
  }

  /// Total annual-leave working days across all winter/summer/other bookings (past, today, future).
  static Future<int> getTotalAnnualLeaveWorkingDays() async {
    final holidays = await HolidayService.getHolidays();
    final isMFSchedule = await _isOnMFSchedule();
    int total = 0;
    for (final holiday in holidays) {
      if (holiday.type == 'winter' || holiday.type == 'summer' || holiday.type == 'other') {
        total += await _workingDaysInAnnualLeaveHoliday(holiday, isMFSchedule);
      }
    }
    return total;
  }

  /// Working days on dates from [start] through [end] inclusive (same rules as future bookings).
  static Future<int> _workingDaysInRange(
    DateTime start,
    DateTime end,
    bool isMFSchedule,
  ) async {
    if (start.isAfter(end)) return 0;
    if (isMFSchedule) {
      int days = 0;
      DateTime currentDate = start;
      while (!currentDate.isAfter(end)) {
        final weekday = currentDate.weekday;
        if (weekday >= 1 && weekday <= 5) {
          final isBankHolidayDate = await _isBankHoliday(currentDate);
          if (!isBankHolidayDate) {
            days++;
          }
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }
      return days;
    } else {
      final calendarDays = end.difference(start).inDays + 1;
      return ((calendarDays / 7) * 5).round();
    }
  }

  /// Future annual-leave working days only (from **tomorrow** onward). Past and today are excluded,
  /// so this number drops as booked days pass — same notion as the "Booked" column in the UI.
  static Future<int> getFutureBookedAnnualLeaveDays() async {
    final holidays = await HolidayService.getHolidays();
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final tomorrow = todayNormalized.add(const Duration(days: 1));
    final isMFSchedule = await _isOnMFSchedule();
    int futureDays = 0;

    for (final holiday in holidays) {
      if (holiday.type != 'winter' && holiday.type != 'summer' && holiday.type != 'other') {
        continue;
      }
      final start = DateTime(holiday.startDate.year, holiday.startDate.month, holiday.startDate.day);
      final end = DateTime(holiday.endDate.year, holiday.endDate.month, holiday.endDate.day);

      final overlapStart = start.isAfter(tomorrow) ? start : tomorrow;
      final overlapEnd = end;
      if (overlapStart.isAfter(overlapEnd)) continue;

      futureDays += await _workingDaysInRange(overlapStart, overlapEnd, isMFSchedule);
    }
    return futureDays;
  }

  static String _formatLocalDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static DateTime _parseLocalDate(String s) {
    final parts = s.split('-');
    if (parts.length != 3) {
      final n = DateTime.now();
      return DateTime(n.year, n.month, n.day);
    }
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// True if [d] (date-only) counts as one annual-leave day using the same rules as [getFutureBookedAnnualLeaveDays].
  static Future<bool> _isDateAnnualLeaveConsumingDay(DateTime d) async {
    final holidays = await HolidayService.getHolidays();
    final isMFSchedule = await _isOnMFSchedule();
    final dn = DateTime(d.year, d.month, d.day);
    for (final holiday in holidays) {
      if (holiday.type != 'winter' && holiday.type != 'summer' && holiday.type != 'other') {
        continue;
      }
      final start = DateTime(holiday.startDate.year, holiday.startDate.month, holiday.startDate.day);
      final end = DateTime(holiday.endDate.year, holiday.endDate.month, holiday.endDate.day);
      if (dn.isBefore(start) || dn.isAfter(end)) continue;
      final w = await _workingDaysInRange(dn, dn, isMFSchedule);
      if (w > 0) return true;
    }
    return false;
  }

  /// Advances consumption for each calendar day from last processed through today (inclusive) that has
  /// passed since we last ran — **no** scan of all past years; only forward from the saved cursor.
  static Future<void> _syncAutoConsumedLeaveDaysPassing() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStr = await StorageService.getString(AppConstants.annualLeaveLastProcessedDateKey);
    if (lastStr == null || lastStr.isEmpty) {
      await StorageService.saveString(AppConstants.annualLeaveLastProcessedDateKey, _formatLocalDate(today));
      await StorageService.saveInt(AppConstants.annualLeaveAutoConsumedKey, 0);
      return;
    }
    var last = _parseLocalDate(lastStr);
    if (last.isAfter(today)) {
      last = today;
    }
    var auto = await StorageService.getInt(AppConstants.annualLeaveAutoConsumedKey, defaultValue: 0);
    var d = last.add(const Duration(days: 1));
    while (!d.isAfter(today)) {
      if (await _isDateAnnualLeaveConsumingDay(d)) {
        auto += 1;
      }
      d = d.add(const Duration(days: 1));
    }
    await StorageService.saveInt(AppConstants.annualLeaveAutoConsumedKey, auto);
    await StorageService.saveString(AppConstants.annualLeaveLastProcessedDateKey, _formatLocalDate(today));
  }

  /// Call when the user saves a new annual leave balance (e.g. first-run dialog). Does not run on +/- buttons.
  static Future<void> resetAnnualLeaveConsumptionTracking() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await StorageService.saveInt(AppConstants.annualLeaveAutoConsumedKey, 0);
    await StorageService.saveString(AppConstants.annualLeaveLastProcessedDateKey, _formatLocalDate(today));
  }

  /// "Today" column: stored balance minus one [auto] count for each annual-leave day that has passed while
  /// the app was used (see [_syncAutoConsumedLeaveDaysPassing]). Not a subtraction of all historical holidays.
  static Future<int> getEffectiveBalance() async {
    await _syncAutoConsumedLeaveDaysPassing();
    final stored = await getBalance();
    final auto = await StorageService.getInt(AppConstants.annualLeaveAutoConsumedKey, defaultValue: 0);
    return (stored - auto).clamp(0, double.infinity).toInt();
  }

  /// @deprecated Prefer [getFutureBookedAnnualLeaveDays]. Kept for any external callers expecting the old name.
  static Future<int> getUsedDays() async {
    return getFutureBookedAnnualLeaveDays();
  }

  /// Days left if you subtract all annual-leave working days (full bookings) from stored balance.
  /// Kept for callers that need a computed remainder; main UI uses [getRemainingDaysFutureBookingsOnly].
  static Future<int> getRemainingDays() async {
    final balance = await getBalance();
    final total = await getTotalAnnualLeaveWorkingDays();
    return (balance - total).clamp(0, double.infinity).toInt();
  }

  /// Remaining = [getEffectiveBalance] minus future booked (middle column).
  static Future<int> getRemainingDaysFutureBookingsOnly() async {
    final effective = await getEffectiveBalance();
    final future = await getFutureBookedAnnualLeaveDays();
    return (effective - future).clamp(0, double.infinity).toInt();
  }

  /// Check if user has set their initial balance
  static Future<bool> hasSetInitialBalance() async {
    return await StorageService.getBool(AppConstants.hasSetAnnualLeaveKey, defaultValue: false);
  }

  /// Mark that user has set their initial balance
  static Future<void> markAsSet() async {
    await StorageService.saveBool(AppConstants.hasSetAnnualLeaveKey, true);
  }
}
