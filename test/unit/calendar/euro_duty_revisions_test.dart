import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/euro_duty_revisions.dart';

void main() {
  const currentLine =
      '307/03,007511,06:28:00,06:36:00,Garage,11:05:00,Garage,15:27:00,15:30:00,Garage,18:28:00,Garage,18:28:00,12:00:00,07:33:00,04:27:00,X28/C1';

  test('keeps the current 307/03 row before 8 Nov 2026', () {
    final csv = EuroDutyRevisions.applyUniMfCsv(
      'shift,duty\n$currentLine\n',
      DateTime(2026, 11, 7),
    );

    expect(csv, contains('007511'));
    expect(csv, isNot(contains('007567')));
    expect(EuroDutyRevisions.boardFor('307/03', DateTime(2026, 11, 7)), isNull);
  });

  test('uses duty 567 and the X32 board from 8 Nov 2026', () {
    final csv = EuroDutyRevisions.applyUniMfCsv(
      'shift,duty\n$currentLine\n',
      DateTime(2026, 11, 8),
    );

    expect(csv, contains(EuroDutyRevisions.revised30703CsvLine));
    expect(csv, isNot(contains('007511')));

    final board = EuroDutyRevisions.boardFor('UNI:307/03', DateTime(2026, 11, 9));
    expect(board, isNotNull);
    expect(board!.duty, '007567');
    expect(board.sections.first.entries[2].route, 'X32');
    expect(board.sections.first.entries[2].location, 'Hewlett Packard');
    expect(board.sections.last.entries.last.time, '19:42');
    expect(board.sections.last.entries[2].location, 'UCD Belfield');
    expect(
      EuroDutyRevisions.workFor('307/03', DateTime(2026, 11, 9)),
      const Duration(hours: 7, minutes: 38),
    );
  });

  test('uses the new 307/04 X26 and C1 board from 8 Nov 2026', () {
    const currentLine =
        '307/04,007532,06:13:00,06:21:00,Garage,10:15:00,Garage,15:27:00,15:30:00,Garage,19:08:00,Garage,19:08:00,12:55:00,07:43:00,05:12:00,X25';
    final before = EuroDutyRevisions.applyUniMfCsv(
      currentLine,
      DateTime(2026, 11, 7),
    );
    expect(before, contains('X25'));

    final csv = EuroDutyRevisions.applyUniMfCsv(
      currentLine,
      DateTime(2026, 11, 8),
    );
    expect(csv, contains(EuroDutyRevisions.revised30704CsvLine));
    expect(EuroDutyRevisions.routesFor('307/04', DateTime(2026, 11, 8)), [
      'X26',
      'C1',
    ]);

    final board = EuroDutyRevisions.boardFor('307/04', DateTime(2026, 11, 8));
    expect(board, isNotNull);
    expect(board!.duty, '007573');
    expect(board.sections.first.entries[2].location, 'Maynooth');
    expect(board.sections.first.entries[2].notes, 'Via Louisa Bridge');
    expect(board.sections.last.entries[2].route, 'C1');
    expect(board.sections.last.entries.last.time, '18:35');
    expect(
      EuroDutyRevisions.spreadFor('307/04', DateTime(2026, 11, 8)),
      const Duration(hours: 12, minutes: 43),
    );
  });

  test('bundled 307/03 is still the current X28 duty', () {
    final csv = File('assets/UNI_M-F.csv').readAsStringSync();
    final board = File('assets/universal_boards.json').readAsStringSync();

    expect(csv, contains(currentLine));
    expect(board, contains('"shift": "307/03"'));
    expect(board, contains('"duty": "007511"'));
    expect(board, contains('Salesian College'));
  });
}
