import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_reports_list_screen.dart';

void main() {
  testWidgets('empty list shows copy and fits 320px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: BusReportsListScreen()),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Bus Reports'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.text('Date range'), findsOneWidget);
    expect(find.text('No bus reports yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initial bus number fills the search field', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: BusReportsListScreen(initialBusNumber: 'PA150'),
      ),
    );
    await tester.pump();

    expect(find.widgetWithText(TextField, 'PA150'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
