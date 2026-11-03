import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/models/bill_duty.dart';
import 'package:spdrivercalendar/features/bills/screens/duty_compare_screen.dart';

BillDuty _duty({
  required String shift,
  required String report,
  required String finish,
  required String work,
}) {
  return BillDuty(
    shift: shift,
    dutyNumber: shift,
    report: report,
    depart: report,
    location: 'GAR',
    startBreak: '',
    startBreakLocation: '',
    breakReport: '',
    finishBreak: '',
    finishBreakLocation: '',
    finish: finish,
    finishLocation: 'GAR',
    signOff: finish,
    spread: work,
    work: work,
    relief: '',
  );
}

void main() {
  testWidgets('compares two duties on a 320px phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DutyCompareScreen(
          zone: 'Zone 1',
          dayType: 'M-F',
          date: DateTime(2026, 11, 3),
          duties: [
            _duty(
              shift: 'PZ1/03',
              report: '5:37',
              finish: '13:02',
              work: '6:31',
            ),
            _duty(
              shift: 'PZ1/18',
              report: '6:21',
              finish: '14:10',
              work: '6:58',
            ),
          ],
        ),
      ),
    );

    expect(find.textContaining('Monday to Friday'), findsNothing);
    expect(find.text('Choose'), findsNWidgets(2));

    await tester.tap(find.text('03'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();

    expect(find.textContaining('more work'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Show running boards'),
      200,
    );
    expect(find.text('Show running boards'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every zone is a pick, not a page label', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: DutyCompareScreen(
          zone: 'Zone 4',
          dayType: 'M-F',
          date: DateTime(2026, 11, 3),
          duties: [
            _duty(
              shift: 'PZ4/18',
              report: '5:37',
              finish: '13:02',
              work: '6:31',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Zone 4 · M-F'), findsNothing);
    expect(find.text('Zone 4 · Monday to Friday'), findsNothing);
    expect(find.text('Zone 4'), findsOneWidget);
    expect(find.text('M-F'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('compare-zone-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Zone 1'), findsOneWidget);
    expect(find.text('Route 13'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
