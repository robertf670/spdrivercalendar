import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';

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

  /// Get the number of annual leave days that are booked in the future
  /// Only counts holidays (winter, summer, other) that start on or after today
  /// Past holidays are ignored as they were already accounted for when balance was set
  /// Counts all calendar days (including weekends) since work can occur any day of the week
  /// Since work is 5 days per week, calculates: (calendar days / 7) * 5
  static Future<int> getUsedDays() async {
    final holidays = await HolidayService.getHolidays();
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    int usedDays = 0;
    for (final holiday in holidays) {
      // Only count winter, summer, and other holiday types (not day_in_lieu or unpaid_leave)
      if (holiday.type == 'winter' || holiday.type == 'summer' || holiday.type == 'other') {
        final startDateNormalized = DateTime(
          holiday.startDate.year,
          holiday.startDate.month,
          holiday.startDate.day,
        );
        
        // Only count holidays that start today or in the future
        if (!startDateNormalized.isBefore(todayNormalized)) {
          // Calculate number of calendar days in this holiday period
          final endDateNormalized = DateTime(
            holiday.endDate.year,
            holiday.endDate.month,
            holiday.endDate.day,
          );
          
          // Count all calendar days (inclusive)
          final calendarDays = endDateNormalized.difference(startDateNormalized).inDays + 1;
          
          // Since work is 5 days per week, calculate working days: (calendar days / 7) * 5
          // Round to nearest integer to handle partial weeks
          final workingDays = ((calendarDays / 7) * 5).round();
          
          usedDays += workingDays;
        }
      }
    }
    
    return usedDays;
  }

  /// Get the remaining annual leave days (balance - used future holidays)
  static Future<int> getRemainingDays() async {
    final balance = await getBalance();
    final used = await getUsedDays();
    return (balance - used).clamp(0, double.infinity).toInt();
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
