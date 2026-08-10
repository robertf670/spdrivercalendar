import 'package:spdrivercalendar/core/constants/training_constants.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

/// Builds the calendar event title for an Add Work Shift selection.
String buildWorkShiftTitle({
  required String selectedZone,
  required String selectedShiftNumber,
}) {
  if (selectedZone == '22B/01') {
    return '22B/01';
  }
  if (selectedZone == 'Union') {
    return 'Union';
  }
  if (selectedZone == 'Mentor') {
    return 'Mentor';
  }
  if (selectedZone == 'Spare') {
    final timeWithoutColon = selectedShiftNumber.replaceAll(':', '');
    return 'SP$timeWithoutColon';
  }
  if (selectedZone == 'Uni/Euro' ||
      selectedZone == 'Bus Check' ||
      selectedZone == DonnybrookFeatureService.zoneLabel ||
      selectedZone == JamestownFeatureService.zoneLabel ||
      selectedZone == 'Jamestown Road') {
    return selectedShiftNumber;
  }
  if (selectedZone == 'Training') {
    if (selectedShiftNumber == TrainingConstants.customTrainingShiftOption) {
      return TrainingConstants.customTrainingTitle;
    }
    return selectedShiftNumber;
  }
  // Regular PZ shifts — title is the duty code (e.g. PZ1/01).
  return selectedShiftNumber;
}
