import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/utils/duty_compare.dart';

BillDuty duty({
  required String shift,
  String report = '',
  String depart = '',
  String location = '',
  String startBreak = '',
  String startBreakLocation = '',
  String breakReport = '',
  String finishBreak = '',
  String finishBreakLocation = '',
  String finish = '',
  String finishLocation = '',
  String signOff = '',
  String spread = '',
  String work = '',
  String relief = '',
}) {
  return BillDuty(
    shift: shift,
    dutyNumber: shift,
    report: report,
    depart: depart,
    location: location,
    startBreak: startBreak,
    startBreakLocation: startBreakLocation,
    breakReport: breakReport,
    finishBreak: finishBreak,
    finishBreakLocation: finishBreakLocation,
    finish: finish,
    finishLocation: finishLocation,
    signOff: signOff,
    spread: spread,
    work: work,
    relief: relief,
  );
}

void main() {
  test('says who has more work and who finishes later', () {
    final compare = DutyCompare.of(
      duty(
        shift: 'PZ1/03',
        report: '5:37',
        finish: '13:02',
        signOff: '13:02',
        work: '6:31',
        startBreak: '9:43',
        finishBreak: '10:42',
      ),
      duty(
        shift: 'PZ1/18',
        report: '6:21',
        finish: '14:10',
        signOff: '14:10',
        work: '6:58',
        startBreak: '10:15',
        finishBreak: '11:14',
      ),
    );

    expect(
      compare.headline,
      'PZ1/18 has 27m more work, and PZ1/18 finishes 1h 08m later.',
    );
    expect(compare.hasClock, isTrue);
    expect(compare.yoursSpan!.hasBreak, isTrue);
    final work = compare.lines.firstWhere((line) => line.label == 'Work');
    expect(work.deltaMinutes, 27);
    expect(DutyCompare.formatDelta(27), '+27m');
    expect(DutyCompare.formatDelta(-68), '−1h 08m');
  });

  test('an overnight finish stays on the same clock', () {
    final compare = DutyCompare.of(
      duty(
        shift: 'PZ1/35',
        report: '22:10',
        finish: '6:05',
        signOff: '6:05',
        work: '7:10',
      ),
      duty(
        shift: 'PZ1/01',
        report: '5:30',
        finish: '13:40',
        signOff: '13:40',
        work: '7:10',
      ),
    );

    expect(compare.yoursSpan!.end, 6 * 60 + 5 + 1440);
    expect(compare.axisStart, lessThan(22 * 60));
    expect(compare.axisEnd, greaterThan(13 * 60 + 40));
    expect(compare.headline, contains('PZ1/35 signs off the next morning'));
    expect(compare.headline, contains('PZ1/01 finishes at 13:40'));
  });

  test('the same duty is called out', () {
    final one = duty(
      shift: '13/05',
      report: '5:37',
      finish: '13:02',
      signOff: '13:02',
      work: '6:31',
    );
    final compare = DutyCompare.of(one, one);
    expect(compare.headline, 'Same duty.');
  });
}
