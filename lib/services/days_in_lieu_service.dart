import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';

class DaysInLieuService {
  /// Get the current balance of days in lieu
  static Future<int> getBalance() async {
    return await StorageService.getInt(AppConstants.daysInLieuBalanceKey, defaultValue: 0);
  }

  /// Set the balance of days in lieu
  static Future<void> setBalance(int balance) async {
    if (balance < 0) {
      balance = 0;
    }
    await StorageService.saveInt(AppConstants.daysInLieuBalanceKey, balance);
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

  /// Get the number of days in lieu that have been used (count of day_in_lieu holidays)
  static Future<int> getUsedDays() async {
    final holidays = await HolidayService.getHolidays();
    return holidays.where((h) => h.type == 'day_in_lieu').length;
  }

  /// Get the remaining days in lieu (balance - used)
  static Future<int> getRemainingDays() async {
    final balance = await getBalance();
    final used = await getUsedDays();
    return (balance - used).clamp(0, double.infinity).toInt();
  }

  /// Check if user has set their initial balance
  static Future<bool> hasSetInitialBalance() async {
    return await StorageService.getBool(AppConstants.hasSetDaysInLieuKey, defaultValue: false);
  }

  /// Mark that user has set their initial balance
  static Future<void> markAsSet() async {
    await StorageService.saveBool(AppConstants.hasSetDaysInLieuKey, true);
  }

  /// Called when a day in lieu is added
  /// Note: Balance represents the total available days and should NOT decrease when used.
  /// The "used" count increases automatically by counting holidays, and remaining = balance - used.
  static Future<void> onDayInLieuAdded() async {
    // No action needed - balance stays the same (it represents total available days)
    // Used count increases automatically by counting day_in_lieu holidays
    // Remaining is calculated as balance - used
  }
}
