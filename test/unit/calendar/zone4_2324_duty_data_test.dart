import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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

  test('PZ4/26 Mon-Fri from 23 Aug has no Takes Bus 17 at 17:15 line', () {
    final boards = jsonDecode(
      File('assets/Zone4_Boards_20260823.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final board = boards['PZ4/26']['MON-FRI']['board'] as List<dynamic>;
    final lines = board
        .map((row) => (row as List<dynamic>).join(' '))
        .join('\n');
    expect(lines, isNot(contains('Takes Bus 17 at 17:15')));
    expect(lines, contains('Takes up at 18:05 Constitution Hill'));
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
      final takesUp = lines.indexWhere((line) => line.contains('Takes up at'));
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
      lines.indexWhere((line) => line.contains('Takes up at 12:45')),
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
