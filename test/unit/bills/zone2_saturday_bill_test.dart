import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';

void main() {
  late List<BillDuty> duties;

  setUpAll(() {
    duties = BillsCsvService.parseCsv(
      File('assets/SAT_DUTIES_PZ2.csv').readAsStringSync(),
    );
  });

  test('Saturday Route 13 bill has 30 numbered duties and 4 bogeys', () {
    expect(duties, hasLength(34));
    expect(duties.first.shift, 'PZ2/01');
    expect(duties.last.shift, 'PZ2/4X');
    expect(duties.where((duty) => duty.shift.endsWith('X')), hasLength(4));
  });

  test('PZ2/01 is an early garage workout', () {
    final duty = duties.singleWhere((row) => row.shift == 'PZ2/01');
    expect(duty.isWorkout, isTrue);
    expect(duty.displayReport, '05:22');
    expect(duty.displayDepart, '05:30');
    expect(duty.displayFinish, '10:15');
    expect(duty.endLocation, 'Mountjoy Sq');
    expect(duty.displaySignOff, '10:31');
    expect(duty.displaySpread, '5h 09m');
  });

  test('PZ2/19 overnight garage finish and PZ2/4X bogey parse', () {
    final lateDuty = duties.singleWhere((row) => row.shift == 'PZ2/19');
    expect(lateDuty.displayReport, '14:41');
    expect(lateDuty.displayFinish, '00:05');
    expect(lateDuty.endLocation, 'Garage');
    expect(lateDuty.displaySpread, '9h 24m');
    expect(lateDuty.displayWork, '8h 34m');

    final bogey = duties.singleWhere((row) => row.shift == 'PZ2/4X');
    expect(bogey.dutyNumber, '007254');
    expect(bogey.displayReport, '10:11');
    expect(bogey.displayStartBreak, '13:47');
    expect(bogey.displaySignOff, '18:01');
    expect(bogey.displaySpread, '7h 50m');
  });
}
