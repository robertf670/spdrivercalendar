import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

/// Zone dropdown options for the Add Work Shift dialog.
List<String> workShiftZoneOptions({
  required DateTime shiftDate,
  required bool jamestownEnabled,
  required bool donnybrook1Enabled,
}) {
  if (donnybrook1Enabled) {
    return <String>[
      DonnybrookFeatureService.zoneLabel,
      'Training',
    ];
  }

  final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
  final zones = <String>[
    'Zone 1',
    'Zone 2',
    'Zone 3',
    'Zone 4',
  ];

  if (dayOfWeek == 'Sunday') {
    zones.add('22B/01');
  }

  zones.addAll([
    'Spare',
    'Uni/Euro',
    'Bus Check',
    'Training',
    'Union',
    'Mentor',
  ]);

  if (jamestownEnabled) {
    zones.add(JamestownFeatureService.zoneLabel);
  }

  return zones;
}
