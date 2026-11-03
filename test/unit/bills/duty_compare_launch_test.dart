import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/utils/duty_compare_launch.dart';

BillDuty _duty(String shift) {
  return BillDuty(
    shift: shift,
    dutyNumber: shift,
    report: '5:37',
    depart: '5:37',
    location: 'GAR',
    startBreak: '',
    startBreakLocation: '',
    breakReport: '',
    finishBreak: '',
    finishBreakLocation: '',
    finish: '13:02',
    finishLocation: 'GAR',
    signOff: '13:02',
    spread: '7:25',
    work: '6:31',
    relief: '',
  );
}

void main() {
  test('bill zones come from the duty code', () {
    expect(DutyCompareLaunch.zoneFor('PZ4/18'), 'Zone 4');
    expect(DutyCompareLaunch.zoneFor('PZ4/18A'), 'Zone 4');
    expect(DutyCompareLaunch.zoneFor('4/07'), 'Zone 4');
    expect(DutyCompareLaunch.zoneFor('13/05'), 'Route 13');
    expect(DutyCompareLaunch.zoneFor('PZ2/05'), 'Route 13');
    expect(DutyCompareLaunch.zoneFor('UNI:307/01'), 'Uni/Euro');
    expect(DutyCompareLaunch.canCompare('SP0800'), isFalse);
    expect(DutyCompareLaunch.canCompare('22B/01'), isFalse);
  });

  test('a half duty matches the bill duty', () {
    final match = DutyCompareLaunch.findDuty(
      [_duty('PZ4/18'), _duty('PZ4/05')],
      'PZ4/18A',
    );
    expect(match?.shift, 'PZ4/18');
  });

  test('Saturday service uses the Saturday bill', () {
    expect(DutyCompareLaunch.dayTypeFor(DateTime(2026, 11, 2)), 'M-F');
    expect(DutyCompareLaunch.dayTypeFor(DateTime(2026, 11, 7)), 'Sat');
    expect(DutyCompareLaunch.dayTypeFor(DateTime(2026, 12, 24)), 'Sat');
    expect(DutyCompareLaunch.dayTypeFor(DateTime(2026, 11, 8)), 'Sun');
  });
}
