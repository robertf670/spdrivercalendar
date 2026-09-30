import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';

void main() {
  test('Zone 2 shifts cannot be added before 10 Oct 2026', () {
    expect(Zone2Duties.canAddShiftsOn(DateTime(2026, 10, 9)), isFalse);
    expect(Zone2Duties.canAddShiftsOn(DateTime(2026, 10, 9, 23, 59)), isFalse);
  });

  test('Zone 2 shifts can be added from 10 Oct 2026', () {
    expect(Zone2Duties.canAddShiftsOn(DateTime(2026, 10, 10)), isTrue);
    expect(Zone2Duties.canAddShiftsOn(DateTime(2026, 10, 18)), isTrue);
  });
}
