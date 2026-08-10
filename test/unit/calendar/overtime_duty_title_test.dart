import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/overtime_duty_title.dart';

void main() {
  test('appends half type and OT suffix for normal duties', () {
    expect(
      buildOvertimeDutyTitle(
        selectedShiftNumber: 'PZ1/01',
        overtimeHalfType: 'A',
      ),
      'PZ1/01A (OT)',
    );
    expect(
      buildOvertimeDutyTitle(
        selectedShiftNumber: '807/20',
        overtimeHalfType: 'B',
      ),
      '807/20B (OT)',
    );
  });

  test('omits half type for EA Type Training', () {
    expect(
      buildOvertimeDutyTitle(
        selectedShiftNumber: 'EA Type Training',
        overtimeHalfType: 'A',
      ),
      'EA Type Training (OT)',
    );
  });
}
