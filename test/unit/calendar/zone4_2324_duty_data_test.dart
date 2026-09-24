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
}
