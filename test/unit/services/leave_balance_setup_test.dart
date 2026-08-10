import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/leave_balance_setup.dart';

void main() {
  test('reports both dialogs when neither balance is set', () async {
    final setup = LeaveBalanceSetup(
      hasSetDaysInLieu: () async => false,
      hasSetAnnualLeave: () async => false,
    );

    final status = await setup.check();
    expect(status.needsDaysInLieu, isTrue);
    expect(status.needsAnnualLeave, isTrue);
    expect(status.needsAny, isTrue);
  });

  test('reports none when both balances are set', () async {
    final setup = LeaveBalanceSetup(
      hasSetDaysInLieu: () async => true,
      hasSetAnnualLeave: () async => true,
    );

    final status = await setup.check();
    expect(status.needsAny, isFalse);
  });
}
