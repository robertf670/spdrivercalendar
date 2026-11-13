import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/jamestown_road.dart';

void main() {
  test('Jamestown Road CSV has euros and universals, not 30hr contracts', () {
    final csv = File('assets/JAMESTOWN_DUTIES.csv').readAsLinesSync();
    expect(csv.first, startsWith('shift,'));
    final codes = csv
        .skip(1)
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.split(',').first)
        .toList();

    expect(codes, contains('311/01'));
    expect(codes, contains('811/01'));
    expect(codes, contains('811/69'));
    expect(codes, isNot(contains('811/03')));
    expect(codes, isNot(contains('811/36')));
    expect(codes.every(JamestownRoad.isShiftCode), isTrue);
    expect(codes.where((code) => code.startsWith('311/')).length, 18);

    final picker = JamestownRoad.orderForPicker(codes);
    expect(picker.first, '811/01');
    expect(picker.last, '311/18');
    expect(
      picker.indexOf('811/69'),
      lessThan(picker.indexOf('311/01')),
    );
  });

  test('30hr Jamestown CSV matches the 8 Nov 30hr list', () {
    final csv = File('assets/jamestown_30hr.csv').readAsLinesSync();
    final rows = csv
        .skip(1)
        .where((line) => line.trim().isNotEmpty)
        .map((line) => line.split(','))
        .toList();
    final codes = rows.map((row) => row.first).toList();

    expect(codes, [
      '811/03',
      '811/36',
      '811/37',
      '811/38',
      '811/39',
      '811/40',
      '811/50',
      '811/51',
      '811/52',
      '811/53',
      '811/54',
      '811/55',
      '811/56',
      '811/57',
    ]);
    expect(rows.firstWhere((row) => row.first == '811/36')[16], '39A/37');
    expect(rows.firstWhere((row) => row.first == '811/03')[10], '20:15:00');
    expect(rows.firstWhere((row) => row.first == '811/57')[12], '19:52:00');
  });
}
