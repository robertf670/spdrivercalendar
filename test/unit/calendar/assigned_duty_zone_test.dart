import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/zone2_duties.dart';
import 'package:spdrivercalendar/features/calendar/utils/assigned_duty_zone.dart';

void main() {
  test('Zone 2 assigned duties stay empty before 10 Oct 2026', () {
    final before = DateTime(2026, 10, 9);
    expect(
      AssignedDutyZone.canLoadDuties(selectedZone: 'Zone 2', date: before),
      isFalse,
    );
    expect(
      AssignedDutyZone.emptyDutiesMessage(
        selectedZone: 'Zone 2',
        date: before,
      ),
      Zone2Duties.availableFromMessage,
    );
  });

  test('Zone 2 assigned duties load from 10 Oct 2026', () {
    final from = DateTime(2026, 10, 10);
    expect(
      AssignedDutyZone.canLoadDuties(selectedZone: 'Zone 2', date: from),
      isTrue,
    );
    expect(
      AssignedDutyZone.emptyDutiesMessage(
        selectedZone: 'Zone 2',
        date: from,
      ),
      'No duties available for selected zone and date',
    );
  });
}
