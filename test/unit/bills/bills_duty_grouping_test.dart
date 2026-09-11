import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';
import 'package:spdrivercalendar/features/bills/services/bills_duty_grouping.dart';

BillDuty _duty(String shift) {
  return BillsCsvService.parseCsv(
    'shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief\n'
    '$shift,007001,04:08:00,04:16:00,GARAGE,nan,nan,nan,nan,nan,09:39:00,GARAGE,09:39:00,05:31:00,05:31:00,00:00:00',
  ).single;
}

void main() {
  test('short code is the part after the slash', () {
    expect(_duty('PZ1/01').shortCode, '01');
    expect(_duty('PZ1/1X').shortCode, '1X');
    expect(_duty('PZ1/100').shortCode, '100');
  });

  test('groups a Zone 1-style bill into jumpable ranges', () {
    final duties = [
      for (var i = 1; i <= 21; i++)
        _duty('PZ1/${i.toString().padLeft(2, '0')}'),
      _duty('PZ1/87'),
      _duty('PZ1/1X'),
      _duty('PZ1/21X'),
      _duty('PZ1/91'),
    ];

    final groups = BillsDutyGrouping.group(duties);
    expect(groups.map((group) => group.label).toList(), [
      '01–20',
      '21',
      '87',
      '1X',
      '21X',
      '91',
    ]);
  });

  test('keeps X duties out of the surrounding numeric ranges', () {
    final groups = BillsDutyGrouping.group([
      _duty('PZ1/87'),
      _duty('PZ1/1X'),
      _duty('PZ1/91'),
    ]);
    expect(groups.map((group) => group.label).toList(), ['87', '1X', '91']);
  });

  test('shared prefix is null when Uni codes mix', () {
    expect(
      BillsDutyGrouping.sharedPrefix([_duty('PZ1/01'), _duty('PZ1/02')]),
      'PZ1',
    );
    expect(
      BillsDutyGrouping.sharedPrefix([_duty('307/01'), _duty('807/06')]),
      isNull,
    );
  });
}
