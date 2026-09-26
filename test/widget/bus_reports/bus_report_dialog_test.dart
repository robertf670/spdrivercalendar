import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_dialog.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_key.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('report dialog shows bus number and close', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: BusReportDialog(
          target: BusReportTarget(
            busNumber: 'SG123',
            date: '2026-09-26',
            slot: BusReportSlot.full,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('SG123'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
