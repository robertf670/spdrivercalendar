import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/marked_in_zone_options.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

void main() {
  test('Route 13 is a marked-in option and Zone 2 is not listed', () {
    expect(
      markedInZoneOptions(jamestownEnabled: false),
      ['Zone 1', 'Route 13', 'Zone 3', 'Zone 4'],
    );
  });

  test('Jamestown appears when unlocked or already saved', () {
    expect(
      markedInZoneOptions(jamestownEnabled: true),
      contains(JamestownFeatureService.zoneLabel),
    );
    expect(
      markedInZoneOptions(
        jamestownEnabled: false,
        currentZone: JamestownFeatureService.zoneLabel,
      ),
      contains(JamestownFeatureService.zoneLabel),
    );
  });
}
