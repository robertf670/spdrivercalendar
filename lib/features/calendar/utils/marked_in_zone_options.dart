import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

/// Zones shown in Settings → Marked In Status.
///
/// Route 13 can be saved now so drivers are marked in ahead of 10 Oct 2026.
/// Adding or assigning Route 13 duties is still gated to that date.
List<String> markedInZoneOptions({
  required bool jamestownEnabled,
  String currentZone = '',
}) {
  return [
    'Zone 1',
    Zone2Duties.zoneLabel,
    'Zone 3',
    'Zone 4',
    if (jamestownEnabled ||
        JamestownFeatureService.isZone(currentZone))
      JamestownFeatureService.zoneLabel,
  ];
}
