import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/shift_info_map_factory.dart';

void main() {
  test('builds expected shift info entries', () {
    final map = buildShiftInfoMap({
      'E': Colors.green,
      'L': Colors.blue,
      'M': Colors.orange,
      'R': Colors.grey,
      'W': Colors.teal,
      'WFO': Colors.purple,
    });

    expect(map.keys, containsAll(['E', 'L', 'M', 'R', 'W', 'WFO']));
    expect(map['E']!.name, 'Early');
    expect(map['WFO']!.color, Colors.purple);
  });
}
