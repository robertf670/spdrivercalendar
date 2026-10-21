import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/board_share_capture.dart';
import 'package:spdrivercalendar/features/calendar/widgets/universal_board_timeline.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

UniversalBoard _sampleBoard() {
  return UniversalBoard(
    shift: '13/18',
    duty: '218',
    sections: [
      BoardSection(
        type: 'firstHalf',
        entries: [
          BoardEntry(action: 'Reports', time: '12:47'),
          BoardEntry(
            action: 'Route',
            time: '13:06',
            location: 'Mountjoy Square',
            route: '13',
          ),
          BoardEntry(action: 'Arrives', time: '16:42', location: 'Mountjoy Square'),
        ],
      ),
      BoardSection(
        type: 'secondHalf',
        entries: [
          BoardEntry(
            action: 'Takes up',
            time: '17:45',
            location: 'Mountjoy Square',
          ),
          BoardEntry(action: 'Finish', time: '21:01'),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('share sheet lays out the whole board at a fixed width',
      (tester) async {
    tester.view.physicalSize = const Size(boardShareWidth, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(boardShareWidth, 800),
            textScaler: TextScaler.noScaling,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: BoardShareSheet(board: _sampleBoard()),
          ),
        ),
      ),
    );

    expect(find.text('Board 13/18'), findsOneWidget);
    expect(find.text('Duty 218'), findsOneWidget);
    expect(find.text('First Half'), findsOneWidget);
    expect(find.text('Second Half'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);

    final sheet = tester.getSize(find.byType(BoardShareSheet));
    expect(sheet.width, boardShareWidth);
    expect(tester.takeException(), isNull);
  });
}
