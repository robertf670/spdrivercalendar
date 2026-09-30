import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/services/bills_csv_service.dart';

void main() {
  late List<BillDuty> duties;

  setUpAll(() {
    duties = BillsCsvService.parseCsv(
      File('assets/M-F_DUTIES_PZ2.csv').readAsStringSync(),
    );
  });

  test('Monday-Friday Route 13 bill has 34 numbered duties and 9 bogeys', () {
    expect(duties, hasLength(43));
    expect(duties.first.shift, 'PZ2/01');
    expect(duties.last.shift, 'PZ2/9X');
    expect(duties.where((duty) => duty.shift.endsWith('X')), hasLength(9));
  });

  test('PZ2/01 reports at 05:02 with an 08:05 Mountjoy break', () {
    final duty = duties.singleWhere((row) => row.shift == 'PZ2/01');
    expect(duty.isWorkout, isFalse);
    expect(duty.displayReport, '05:02');
    expect(duty.displayDepart, '05:10');
    expect(duty.displayStartBreak, '08:05');
    expect(duty.displayBreakReport, '08:55');
    expect(duty.displayFinish, '12:30');
    expect(duty.displaySignOff, '12:46');
    expect(duty.displaySpread, '7h 44m');
    expect(duty.displayWork, '6h 54m');
    expect(duty.displayRelief, '50m');
  });

  test('PZ2/24 overnight finish and PZ2/5X long relief parse', () {
    final lateDuty = duties.singleWhere((row) => row.shift == 'PZ2/24');
    expect(lateDuty.displayReport, '14:59');
    expect(lateDuty.displayFinish, '00:40');
    expect(lateDuty.endLocation, 'Garage');
    expect(lateDuty.displaySpread, '9h 41m');

    final bogey = duties.singleWhere((row) => row.shift == 'PZ2/5X');
    expect(bogey.dutyNumber, '007255');
    expect(bogey.displayReport, '07:56');
    expect(bogey.displayStartBreak, '11:47');
    expect(bogey.displayFinish, '18:50');
    expect(bogey.displayRelief, '3h 02m');
  });

  test('PZ2/32 to PZ2/34 are evening workouts', () {
    for (final code in ['PZ2/32', 'PZ2/33', 'PZ2/34']) {
      expect(
        duties.singleWhere((row) => row.shift == code).isWorkout,
        isTrue,
        reason: code,
      );
    }
  });
}
