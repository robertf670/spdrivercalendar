import 'package:spdrivercalendar/services/annual_leave_service.dart';
import 'package:spdrivercalendar/services/days_in_lieu_service.dart';

/// Loads annual-leave and days-in-lieu balances for the Add Holidays dialog.
class HolidayBalanceLoader {
  Future<Map<String, int>> loadBalances() async {
    final annualLeaveStoredBalance =
        await AnnualLeaveService.getEffectiveBalance();
    final annualLeaveRemainingFutureOnly =
        await AnnualLeaveService.getRemainingDaysFutureBookingsOnly();
    final annualLeaveFutureBooked =
        await AnnualLeaveService.getFutureBookedAnnualLeaveDays();
    final daysInLieuBalance = await DaysInLieuService.getBalance();
    final daysInLieuRemaining = await DaysInLieuService.getRemainingDays();
    final daysInLieuUsed = await DaysInLieuService.getUsedDays();

    return {
      'annualLeaveToday': annualLeaveStoredBalance,
      'annualLeaveRemaining': annualLeaveRemainingFutureOnly,
      'annualLeaveBooked': annualLeaveFutureBooked,
      'daysInLieuToday': daysInLieuBalance,
      'daysInLieuRemaining': daysInLieuRemaining,
      'daysInLieuBooked': daysInLieuUsed,
    };
  }
}
