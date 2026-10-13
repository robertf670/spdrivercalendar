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
}
