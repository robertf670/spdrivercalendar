import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/payscale/payscale_catalog.dart';
import 'package:spdrivercalendar/features/payscale/screens/payscale_screen.dart';

void main() {
  final catalog = PayScaleCatalog.parse('''
type,year1+2,year3+4,year5,year6,
basicdaily,140.26,145.19,152.56,162.40
spreadover(hourly),17.98,18.61,19.56,20.82
''');

  testWidgets('opens on the saved year and switches rates', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: PayscaleScreen(
          initialYearLevel: 'year5',
          catalog: catalog,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pay Scale'), findsOneWidget);
    expect(find.text('Year 1-2'), findsOneWidget);
    expect(find.text('Year 3-4'), findsOneWidget);
    expect(find.text('Year 5'), findsOneWidget);
    expect(find.text('Year 6+'), findsOneWidget);
    expect(find.text('People XD (Core HR)'), findsOneWidget);
    expect(find.text('View payslips, holiday allowance & more'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Spread'), findsOneWidget);
    expect(find.text('Basic Daily Rate'), findsOneWidget);
    expect(find.text('€152.56'), findsOneWidget);
    expect(find.text('€19.56'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('payscale-year-year6')));
    await tester.pump();

    expect(find.text('€162.40'), findsOneWidget);
    expect(find.text('€20.82'), findsOneWidget);
    expect(find.text('€152.56'), findsNothing);
  });
}
