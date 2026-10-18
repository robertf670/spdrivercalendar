import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/statistics/utils/duty_zone_label.dart';

void main() {
  test('buckets Route 13 and old PZ2 codes together, not Uni/Euro', () {
    expect(dutyZoneLabel('13/01'), 'Route 13');
    expect(dutyZoneLabel('PZ2/01'), 'Route 13');
    expect(dutyZoneLabel('2/01'), 'Route 13');
    expect(dutyZoneLabel('307/01'), 'Uni/Euro');
    expect(dutyZoneLabel('UNI:807/06'), 'Uni/Euro');
    expect(dutyZoneLabel('PZ1/01'), 'Zone 1');
    expect(dutyZoneLabel('PZ3/01'), 'Zone 3');
    expect(dutyZoneLabel('PZ4/16'), 'Zone 4');
  });
}
