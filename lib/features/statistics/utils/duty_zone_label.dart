import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';

/// Statistics bucket for a duty code. Route 13 covers both `13/` and old `PZ2/`.
String? dutyZoneLabel(String dutyCode) {
  final code = dutyCode.startsWith('UNI:') ? dutyCode.substring(4) : dutyCode;
  if (code.startsWith(DonnybrookFeatureService.shiftPrefix)) return 'DB Z1';
  if (code.startsWith('PZ1') || code.contains('PZ1/')) return 'Zone 1';
  if (Zone2Duties.isRoute13Code(code) ||
      code.startsWith('PZ2') ||
      code.contains('PZ2/')) {
    return 'Route 13';
  }
  if (code.startsWith('PZ3') || code.contains('PZ3/')) return 'Zone 3';
  if (code.startsWith('PZ4') || code.contains('PZ4/')) return 'Zone 4';
  if (code.startsWith('UNI') || Zone2Duties.isUniEuroCode(code)) {
    return 'Uni/Euro';
  }
  return null;
}
