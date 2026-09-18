import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/widgets/shift_details_card.dart';
import 'package:spdrivercalendar/models/shift_info.dart';

void main() {
  testWidgets('Rest Shift rectangle uses the day colour override', (tester) async {
    const override = Color(0xFFEC407A);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShiftDetailsCard(
            date: DateTime(2026, 9, 18),
            shift: 'R',
            shiftInfoMap: {
              'R': ShiftInfo('Rest', Colors.blue),
            },
            hasDayNote: false,
            onShowDayNotes: () {},
            colorOverride: override,
          ),
        ),
      ),
    );

    expect(find.textContaining('Rest Shift'), findsOneWidget);

    final gradientContainer = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere((container) {
      final decoration = container.decoration;
      return decoration is BoxDecoration && decoration.gradient is LinearGradient;
    });
    final gradient =
        (gradientContainer.decoration as BoxDecoration).gradient as LinearGradient;
    expect(gradient.colors.first, override.withValues(alpha: 0.2));
  });
}
