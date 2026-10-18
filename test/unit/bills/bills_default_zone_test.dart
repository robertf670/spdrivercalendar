import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bills/utils/bills_default_zone.dart';
import 'package:spdrivercalendar/features/calendar/utils/jamestown_road.dart';

void main() {
  test('spare and empty marked-in open Zone 1', () {
    expect(billsDefaultZone(''), 'Zone 1');
    expect(billsDefaultZone('Spare'), 'Zone 1');
  });

  test('Shift / M-F marked-in opens that bills zone', () {
    expect(billsDefaultZone('Route 13'), 'Route 13');
    expect(billsDefaultZone('Zone 2'), 'Route 13');
    expect(billsDefaultZone('Zone 1'), 'Zone 1');
    expect(billsDefaultZone('Zone 3'), 'Zone 3');
    expect(billsDefaultZone('Zone 4'), 'Zone 4');
  });

  test('Jamestown and other non-bill zones fall back to Zone 1', () {
    expect(billsDefaultZone(JamestownRoad.zoneLabel), 'Zone 1');
    expect(billsDefaultZone('Nights'), 'Zone 1');
  });
}
