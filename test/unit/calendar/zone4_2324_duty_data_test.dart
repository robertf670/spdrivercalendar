import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PZ4/33 Mon-Fri from 23 Aug matches the August running board', () {
    final row = File('assets/M-F_ROUTE2324_20260823.csv')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('PZ4/33,'));
    expect(
      row,
      'PZ4/33,007433,15:32:00,15:35:00,ConHill #1619(24),20:15:00,Bstone #190(24),21:22:00,21:25:00,Garage(23),23:25:00,Garage,23:25:00,07:53:00,06:46:00,01:07:00',
    );

    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final day = boards['PZ4/33']['MON-FRI'] as Map<String, dynamic>;
    expect(day['depart'], '15:35');
    expect(day['signoff'], '23:25');
    final lines = (day['board'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).join(' '))
        .join('\n');
    expect(lines, contains('Takes Route 24 at 15:35 Constitution Hill'));
    expect(lines, contains('Dublin Airport  16:50'));
    expect(lines, contains('Merrion Square  18:30'));
    expect(lines, contains('Charlestown SC  19:40'));
    expect(lines, contains('Broadstone 20:15'));
    expect(lines, contains('Hands over to Duty 438 at 20:15 Broadstone'));
    expect(lines, contains('Departs Garage  21:25'));
    expect(lines, contains('Merrion Square  21:50'));
    expect(lines, contains('SPL   Charlestown SC  22:55'));
    expect(lines, contains('Phibsboro Garage 23:25'));
  });

  test('PZ4/01 Mon-Fri from 23 Aug finishes at Constitution Hill', () {
    final row = File('assets/M-F_ROUTE2324_20260823.csv')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('PZ4/01,'));
    expect(row, contains('09:50:00,ConHill #1619,09:50:00'));

    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final board = boards['PZ4/01']['MON-FRI']['board'] as List<dynamic>;
    final lines = board
        .map((row) => (row as List<dynamic>).join(' '))
        .join('\n');
    expect(lines, contains('Constitution Hill'));
    expect(lines, contains('09:50'));
  });

  test('PZ4/24 Mon-Fri from 23 Aug matches 17:00 break and 21:55 finish', () {
    final row = File('assets/M-F_ROUTE2324_20260823.csv')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('PZ4/24,'));
    expect(row, contains('17:00:00,ConHill #1619(24)'));
    expect(
      row,
      contains('21:55:00,Garage,21:55:00,09:28:00,08:28:00,01:00:00'),
    );

    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final header = boards['PZ4/24']['MON-FRI'] as Map<String, dynamic>;
    expect(header['signoff'], '21:55');
    expect(header['spread'], '09:28');
    expect(header['relief'], '01:00');
  });

  test('PZ4/16 Mon-Fri second half takes up at Broadstone, not Constitution Hill',
      () {
    final row = File('assets/M-F_ROUTE2324_20260823.csv')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('PZ4/16,'));
    expect(row, contains('11:30:00,Bstone #190(24)'));
    expect(row, contains('15:35:00,ConHill #1619,15:35:00'));

    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final board = boards['PZ4/16']['MON-FRI']['board'] as List<dynamic>;
    final lines = board
        .map((row) => (row as List<dynamic>).join(' '))
        .join('\n');
    expect(lines, contains('Takes Route 24 at 11:30 Broadstone'));
    expect(lines, contains('Broadstone'));
    expect(lines, contains('Merrion Square'));
    expect(lines, contains('12:00'));
    expect(lines, contains('13:30'));
    expect(lines, contains('15:00'));
    expect(lines, contains('Constitution Hill'));
    expect(lines, contains('15:35'));
    expect(lines, isNot(contains('Takes up at 11:30 Constitution Hill')));
  });

  test('PZ4/26 Mon-Fri from 23 Aug has no Takes Bus 17 at 17:15 line', () {
    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final board = boards['PZ4/26']['MON-FRI']['board'] as List<dynamic>;
    final lines = board
        .map((row) => (row as List<dynamic>).join(' '))
        .join('\n');
    expect(lines, isNot(contains('Takes Bus 17 at 17:15')));
    expect(lines, contains('Takes Route 23 at 18:05 Constitution Hill'));
  });

  test('PZ4/05 boards keep the garage report before the take-up half', () {
    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    for (final day in ['MON-FRI', 'SAT', 'SUN']) {
      final board = boards['PZ4/05'][day]['board'] as List<dynamic>;
      final lines = board
          .map((row) => (row as List<dynamic>)[3].toString())
          .toList();
      final reportsAt = lines.indexWhere((line) => line.contains('Reports at'));
      final takesUp = lines.indexWhere((line) => line.contains('Takes Route'));
      expect(reportsAt, greaterThanOrEqualTo(0), reason: 'PZ4/05 $day');
      expect(takesUp, greaterThan(reportsAt), reason: 'PZ4/05 $day');
    }
  });

  test('PZ4/12 Sunday take-up at 12:45 stays before the 16:17 garage piece', () {
    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final board = boards['PZ4/12']['SUN']['board'] as List<dynamic>;
    final lines = board
        .map((row) => (row as List<dynamic>)[3].toString())
        .toList();
    expect(
      lines.indexWhere((line) => line.contains('Takes Route 24 at 12:45')),
      lessThan(lines.indexWhere((line) => line.contains('Reports at 16:17'))),
    );
  });

  test('PZ4/1N Mon-Fri evening half stays before the 02:22 piece', () {
    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final board = boards['PZ4/1N']['MON-FRI']['board'] as List<dynamic>;
    final lines = board
        .map((row) => (row as List<dynamic>)[3].toString())
        .toList();
    expect(
      lines.indexWhere((line) => line.contains('20:40')),
      lessThan(lines.indexWhere((line) => line.contains('Reports at 02:22'))),
    );
  });

  test('PZ4/34 Mon-Fri second half continues after 20:30 to the garage at 00:35', () {
    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final board = boards['PZ4/34']['MON-FRI']['board'] as List<dynamic>;
    final lines = board
        .map((row) => (row as List<dynamic>).join(' '))
        .join('\n');
    expect(lines, contains('Take up at 19:55 Broadstone'));
    expect(lines, contains('21:40'));
    expect(lines, contains('22:40'));
    expect(lines, contains('00:00'));
    expect(lines, contains('Phibsboro Garage'));
    expect(lines, contains('00:35'));
  });
}
