import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/jamestown_road.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_shift_zone_options.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

void main() {
  test('donnybrook mode only offers depot and training', () {
    final zones = workShiftZoneOptions(
      shiftDate: DateTime(2026, 8, 4),
      jamestownEnabled: true,
      donnybrook1Enabled: true,
    );
    expect(zones, [
      DonnybrookFeatureService.zoneLabel,
      'Training',
    ]);
  });

  test('sunday includes 22B/01 and optional Jamestown', () {
    final zones = workShiftZoneOptions(
      shiftDate: DateTime(2026, 8, 2), // Sunday
      jamestownEnabled: true,
      donnybrook1Enabled: false,
    );
    expect(zones, contains('22B/01'));
    expect(zones, contains(JamestownFeatureService.zoneLabel));
    expect(zones.last, JamestownRoad.zoneLabel);
    expect(zones.first, 'Zone 1');
  });

  test('weekday omits 22B/01', () {
    final zones = workShiftZoneOptions(
      shiftDate: DateTime(2026, 8, 4), // Tuesday
      jamestownEnabled: false,
      donnybrook1Enabled: false,
    );
    expect(zones, isNot(contains('22B/01')));
    expect(zones, isNot(contains(JamestownFeatureService.zoneLabel)));
    expect(zones.last, JamestownRoad.zoneLabel);
  });

  test('30hr and 40hr Jamestown sit at the end of the zone picker', () {
    final zones = workShiftZoneOptions(
      shiftDate: DateTime(2026, 10, 12),
      jamestownEnabled: true,
      donnybrook1Enabled: false,
    );
    expect(zones.sublist(zones.length - 2), [
      JamestownFeatureService.zoneLabel,
      JamestownRoad.zoneLabel,
    ]);
  });
}
