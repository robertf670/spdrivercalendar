import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/duty_corrections/duty_correction.dart';
import 'package:spdrivercalendar/features/duty_corrections/duty_correction_apply.dart';

void main() {
  const correction = DutyCorrection(
    duty: '13/01',
    dayKey: 'SUN',
    report: '12:05',
    signoff: '12:00',
    boardRows: [
      BoardRowPatch(
        index: 2,
        route: '13',
        place: 'Grange Castle',
        arrive: '',
        depart: '07:10',
      ),
    ],
    bill: BillFieldPatch(
      depart: '06:20:00',
      finish: '12:00:00',
    ),
  );

  test('a board correction replaces one stop and the sign-off', () {
    final day = DutyCorrectionApply.boardDay({
      'signoff': '11:46',
      'board': [
        ['', 'Duty', '201', 'Reports at 06:07', '', ''],
        ['SPL', '', '', 'Departs Garage', '', '06:15'],
        ['13', '', '', 'Grange Castle', '', '07:00'],
      ],
    }, correction);

    expect(day['signoff'], '12:00');
    final board = day['board'] as List<dynamic>;
    expect(board[0], ['', 'Duty', '201', 'Reports at 12:05', '', '']);
    expect(board[1], ['SPL', '', '', 'Departs Garage', '', '06:15']);
    expect(board[2], ['13', '', '', 'Grange Castle', '', '07:10']);
  });

  test('a bill correction changes the take-up and finish columns', () {
    final parts = DutyCorrectionApply.csvParts(
      [
        '13/01',
        '007201',
        '06:07:00',
        '06:15:00',
        'Garage',
        '',
        '',
        '',
        '',
        '',
        '11:30:00',
        'MISQ',
        '11:46:00',
      ],
      correction,
    );

    expect(parts[3], '06:20:00');
    expect(parts[10], '12:00:00');
    expect(parts[12], '11:46:00');
  });

  test('a bill duty keeps the bundled row when there is no correction', () {
    const duty = BillDuty(
      shift: '13/01',
      dutyNumber: '007201',
      report: '06:07:00',
      depart: '06:15:00',
      location: 'Garage',
      startBreak: '',
      startBreakLocation: '',
      breakReport: '',
      finishBreak: '',
      finishBreakLocation: '',
      finish: '11:30:00',
      finishLocation: 'MISQ',
      signOff: '11:46:00',
      spread: '05:39:00',
      work: '05:39:00',
      relief: '00:00:00',
    );

    expect(DutyCorrectionApply.billDuty(duty, null).depart, '06:15:00');
    expect(
      DutyCorrectionApply.billDuty(duty, correction).depart,
      '06:20:00',
    );
  });

  test('document ids stay free of slashes', () {
    expect(DutyCorrection.documentId('PZ2/01', 'MON-FRI'), '13-01_MON-FRI');
    expect(DutyCorrection.documentId('PZ1/43', 'SUN'), 'PZ1-43_SUN');
    expect(
      DutyCorrection.documentId(
        'PZ4/33',
        'MON-FRI',
        era: DutyCorrection.zone4CurrentEra,
      ),
      'PZ4-33_MON-FRI_20260823',
    );
  });

  test('Zone 4 era follows the bill date', () {
    expect(
      DutyCorrection.eraFor('PZ4/33', DateTime(2026, 8, 24)),
      DutyCorrection.zone4CurrentEra,
    );
    expect(
      DutyCorrection.eraFor('PZ4/33', DateTime(2026, 1, 12)),
      DutyCorrection.zone4PreviousEra,
    );
    expect(
      DutyCorrection.eraFor('PZ1/43', DateTime(2026, 8, 24)),
      isNull,
    );
  });
}
