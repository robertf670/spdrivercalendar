import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/widgets/day_detail_section.dart';
import 'package:spdrivercalendar/models/shift_info.dart';

void main() {
  testWidgets('renders the empty selected day responsively and adds events', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var addCalls = 0;
    final selectedDate = DateTime(2026, 8, 4);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DayDetailSection(
              selectedDate: selectedDate,
              shiftInfoMap: {
                'E': ShiftInfo('Early', Colors.green),
              },
              events: const [],
              onAddEvent: () => addCalls++,
              onEditEvent: (_) {},
              onShowEventNotes: (_) {},
              onBusAssignmentUpdate: (_) async {},
              highlightWorkoutDays: false,
              onShowDayNotes: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Events (0)'), findsOneWidget);
    expect(find.text('No events for Tuesday, August 4'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.add_circle));
    expect(addCalls, 1);
  });

  testWidgets('shows the supplied shift summary independently', (tester) async {
    final selectedDate = DateTime(2026, 8, 4);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DayDetailSection(
              selectedDate: selectedDate,
              shiftInfoMap: {
                'E': ShiftInfo('Early', Colors.green),
              },
              events: const [],
              onAddEvent: () {},
              onEditEvent: (_) {},
              onShowEventNotes: (_) {},
              onBusAssignmentUpdate: (_) async {},
              highlightWorkoutDays: false,
              showShiftSummary: true,
              shift: 'E',
              hasDayNote: true,
              onShowDayNotes: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Early'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
