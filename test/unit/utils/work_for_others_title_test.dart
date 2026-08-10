import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_for_others_title.dart';

void main() {
  group('buildWorkForOthersTitle', () {
    test('prefixes zone duties with PZ', () {
      expect(
        buildWorkForOthersTitle(
          selectedZone: 'Zone 1',
          selectedShiftNumber: '12',
        ),
        'PZ1/12',
      );
      expect(
        buildWorkForOthersTitle(
          selectedZone: 'Zone 4',
          selectedShiftNumber: '03',
        ),
        'PZ4/03',
      );
    });

    test('keeps existing PZ prefixes and Uni codes unchanged', () {
      expect(
        buildWorkForOthersTitle(
          selectedZone: 'Zone 1',
          selectedShiftNumber: 'PZ1/12',
        ),
        'PZ1/12',
      );
      expect(
        buildWorkForOthersTitle(
          selectedZone: 'Uni/Euro',
          selectedShiftNumber: '807/20',
        ),
        '807/20',
      );
    });
  });
}
