import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/day_color_swatches.dart';

void main() {
  test('swatches are unique colours', () {
    final swatches = dayColorSwatches();
    final ids = swatches.map((color) => color.toARGB32()).toSet();
    expect(swatches, isNotEmpty);
    expect(ids.length, swatches.length);
  });
}
