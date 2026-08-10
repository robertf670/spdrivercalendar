import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/universal_board_dialog.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

void main() {
  testWidgets('fits 320px and shows board sections', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final board = UniversalBoard(
      shift: 'PZ1/01',
      duty: '01',
      sections: [
        BoardSection(
          type: 'firstHalf',
          entries: [
            BoardEntry(
              action: 'Sign On',
              time: '05:30',
              location: 'Depot',
            ),
            BoardEntry(
              action: 'Route',
              time: '05:45',
              location: 'City',
              route: '13',
              notes: 'via Quay',
            ),
          ],
        ),
        BoardSection(
          type: 'secondHalf',
          entries: [
            BoardEntry(
              action: 'Sign Off',
              time: '13:00',
              location: 'Depot',
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UniversalBoardDialog(board: board),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialogRect = tester.getRect(find.byType(Dialog));
    expect(dialogRect.left, greaterThanOrEqualTo(0));
    expect(dialogRect.right, lessThanOrEqualTo(320));
    expect(find.text('Board PZ1/01'), findsOneWidget);
    expect(find.text('Duty 01'), findsOneWidget);
    expect(find.text('First Half'), findsOneWidget);
    expect(find.text('Second Half'), findsOneWidget);
    expect(find.text('Sign On'), findsOneWidget);
    expect(find.text('From City'), findsOneWidget);
    expect(find.text('via Quay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
