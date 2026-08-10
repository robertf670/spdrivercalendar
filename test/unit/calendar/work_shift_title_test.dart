import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/core/constants/training_constants.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_shift_title.dart';

void main() {
  test('builds spare, fixed, and training titles', () {
    expect(
      buildWorkShiftTitle(
        selectedZone: 'Spare',
        selectedShiftNumber: '06:00',
      ),
      'SP0600',
    );
    expect(
      buildWorkShiftTitle(
        selectedZone: '22B/01',
        selectedShiftNumber: '',
      ),
      '22B/01',
    );
    expect(
      buildWorkShiftTitle(
        selectedZone: 'Union',
        selectedShiftNumber: '',
      ),
      'Union',
    );
    expect(
      buildWorkShiftTitle(
        selectedZone: 'Training',
        selectedShiftNumber: TrainingConstants.customTrainingShiftOption,
      ),
      TrainingConstants.customTrainingTitle,
    );
  });

  test('keeps duty codes for zone and uni selections', () {
    expect(
      buildWorkShiftTitle(
        selectedZone: 'Zone 1',
        selectedShiftNumber: 'PZ1/01',
      ),
      'PZ1/01',
    );
    expect(
      buildWorkShiftTitle(
        selectedZone: 'Uni/Euro',
        selectedShiftNumber: '807/20',
      ),
      '807/20',
    );
  });
}
