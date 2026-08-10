import 'package:spdrivercalendar/services/annual_leave_service.dart';
import 'package:spdrivercalendar/services/days_in_lieu_service.dart';

/// Which first-run leave-balance dialogs still need to be shown.
class LeaveBalanceSetupStatus {
  const LeaveBalanceSetupStatus({
    required this.needsDaysInLieu,
    required this.needsAnnualLeave,
  });

  final bool needsDaysInLieu;
  final bool needsAnnualLeave;

  bool get needsAny => needsDaysInLieu || needsAnnualLeave;
}

typedef LeaveBalanceFlagReader = Future<bool> Function();

/// Checks whether days-in-lieu / annual-leave initial balances are set.
class LeaveBalanceSetup {
  LeaveBalanceSetup({
    LeaveBalanceFlagReader? hasSetDaysInLieu,
    LeaveBalanceFlagReader? hasSetAnnualLeave,
  })  : _hasSetDaysInLieu =
            hasSetDaysInLieu ?? DaysInLieuService.hasSetInitialBalance,
        _hasSetAnnualLeave =
            hasSetAnnualLeave ?? AnnualLeaveService.hasSetInitialBalance;

  final LeaveBalanceFlagReader _hasSetDaysInLieu;
  final LeaveBalanceFlagReader _hasSetAnnualLeave;

  Future<LeaveBalanceSetupStatus> check() async {
    final hasDil = await _hasSetDaysInLieu();
    final hasAl = await _hasSetAnnualLeave();
    return LeaveBalanceSetupStatus(
      needsDaysInLieu: !hasDil,
      needsAnnualLeave: !hasAl,
    );
  }
}
