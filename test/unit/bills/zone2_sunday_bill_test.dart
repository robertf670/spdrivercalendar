import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';

void main() {
  late List<BillDuty> duties;

  setUpAll(() {
    duties = BillsCsvService.parseCsv(
      File('assets/SUN_DUTIES_PZ2.csv').readAsStringSync(),
    );
  });

  test('Sunday Route 13 bill has 27 numbered duties and 6 bogeys', () {
    expect(duties, hasLength(33));
    expect(duties.first.shift, 'PZ2/01');
    expect(duties.last.shift, 'PZ2/6X');
    expect(duties.where((duty) => duty.shift.endsWith('X')), hasLength(6));
  });

  test('PZ2/01 is a garage workout to Mountjoy Square', () {
    final duty = duties.singleWhere((row) => row.shift == 'PZ2/01');
    expect(duty.isWorkout, isTrue);
    expect(duty.displayReport, '06:07');
    expect(duty.displayDepart, '06:15');
    expect(duty.takeUpLocation, 'Garage');
    expect(duty.displayFinish, '11:30');
    expect(duty.endLocation, 'Mountjoy Sq');
    expect(duty.displaySignOff, '11:46');
    expect(duty.displaySpread, '5h 39m');
    expect(duty.displayWork, '5h 39m');
  });

  test('PZ2/17 and PZ2/18 evening pair parse from the Sunday sheet', () {
    final duty17 = duties.singleWhere((row) => row.shift == 'PZ2/17');
    expect(duty17.displayReport, '14:56');
    expect(duty17.displayDepart, '15:15');
    expect(duty17.displayFinish, '00:17');
    expect(duty17.displaySpread, '9h 21m');
    expect(duty17.displayWork, '8h 29m');

    final duty18 = duties.singleWhere((row) => row.shift == 'PZ2/18');
    expect(duty18.displayReport, '15:26');
    expect(duty18.displayDepart, '15:45');
    expect(duty18.displayFinish, '00:32');
    expect(duty18.displaySpread, '9h 06m');
  });

  test('PZ2/22 overnight finish and PZ2/1X bogey parse', () {
    final lateDuty = duties.singleWhere((row) => row.shift == 'PZ2/22');
    expect(lateDuty.displayReport, '16:26');
    expect(lateDuty.displayFinish, '01:20');
    expect(lateDuty.endLocation, 'Garage');
    expect(lateDuty.displaySpread, '8h 54m');
    expect(lateDuty.hasMealBreak, isTrue);

    final bogey = duties.singleWhere((row) => row.shift == 'PZ2/1X');
    expect(bogey.dutyNumber, '007251');
    expect(bogey.takeUpLocation, 'Mountjoy Sq');
    expect(bogey.displayStartBreak, '13:45');
    expect(bogey.displaySignOff, '17:10');
    expect(bogey.displaySpread, '6h 59m');
  });

  test('PZ2/6X break is 14:03 to 14:55, not 14:30', () {
    final duty = duties.singleWhere((row) => row.shift == 'PZ2/6X');
    expect(duty.displayReport, '11:22');
    expect(duty.displayStartBreak, '14:03');
    expect(duty.displayBreakReport, '14:55');
    expect(duty.displayFinishBreak, '15:00');
    expect(duty.displayFinish, '18:15');
    expect(duty.displaySignOff, '18:31');
    expect(duty.displayWork, '6h 17m');
    expect(duty.displayRelief, '52m');
  });

  test('PZ2/16 takes up at Mountjoy Square, not the garage', () {
    final duty = duties.singleWhere((row) => row.shift == 'PZ2/16');
    expect(duty.takeUpLocation, 'Mountjoy Sq');
    expect(duty.displayDepart, '14:15');
    expect(duty.endLocation, 'Garage');
    expect(duty.displaySignOff, '22:05');
  });
}
