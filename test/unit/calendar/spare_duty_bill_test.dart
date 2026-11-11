import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/spare_duty_bill.dart';

void main() {
  test('Route 13 spare duties use the Route 13 bill', () {
    final bill = SpareDutyBill.resolve('13/25');
    expect(bill.zone, '2');
    expect(bill.codes, containsAll(['13/25', 'PZ2/25']));
  });

  test('a stored PZ2 code still matches the 13/ row', () {
    final bill = SpareDutyBill.resolve('PZ2/01');
    expect(bill.zone, '2');
    expect(bill.codes, containsAll(['13/01', 'PZ2/01']));
  });

  test('Zone 1 and Zone 4 codes stay on their own bills', () {
    final zone1 = SpareDutyBill.resolve('PZ1/65');
    expect(zone1.zone, '1');
    expect(zone1.codes, contains('PZ1/65'));

    final zone4 = SpareDutyBill.resolve('PZ4/16');
    expect(zone4.zone, '4');
    expect(zone4.codes, contains('PZ4/16'));
  });
}
