import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

/// Zones shown in Settings → Marked In Status.
///
/// Zone 2 can be saved now so drivers are marked in ahead of 10 Oct 2026.
/// Adding or assigning Zone 2 duties is still gated to that date.
List<String> markedInZoneOptions({
  required bool jamestownEnabled,
  String currentZone = '',
}) {
  return [
    'Zone 1',
    'Zone 2',
    'Zone 3',
    'Zone 4',
    if (jamestownEnabled ||
        currentZone == JamestownFeatureService.zoneLabel)
      JamestownFeatureService.zoneLabel,
  ];
}
