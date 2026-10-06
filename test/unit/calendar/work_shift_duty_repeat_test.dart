import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_shift_duty_repeat.dart';

void main() {
  test('nights repeats weekday work days only, not Saturday or Sunday', () {
    expect(
      WorkShiftDutyRepeat.shouldShow(
        selectedZone: 'Zone 1',
        shiftDate: DateTime(2024, 4, 9), // Tuesday work in week 1
        isMFMarkedIn: false,
        isShiftMarkedIn: false,
        isNightsRoster: true,
        markedInZone: '',
        jamestownEnabled: false,
        isNightsWorkDay: (date) =>
            date.weekday >= DateTime.monday &&
            date.weekday <= DateTime.thursday,
      ),
      isTrue,
    );
    expect(
      WorkShiftDutyRepeat.shouldShow(
        selectedZone: 'Zone 1',
        shiftDate: DateTime(2024, 4, 13), // Saturday
        isMFMarkedIn: false,
        isShiftMarkedIn: false,
        isNightsRoster: true,
        markedInZone: '',
        jamestownEnabled: false,
        isNightsWorkDay: (_) => true,
      ),
      isFalse,
    );
    expect(
      WorkShiftDutyRepeat.shouldShow(
        selectedZone: 'Zone 1',
        shiftDate: DateTime(2024, 4, 12), // Friday rest in week 1
        isMFMarkedIn: false,
        isShiftMarkedIn: false,
        isNightsRoster: true,
        markedInZone: '',
        jamestownEnabled: false,
        isNightsWorkDay: (_) => false,
      ),
      isFalse,
    );
  });

  test('shift marked-in still repeats Mon-Fri only for the marked-in zone', () {
    expect(
      WorkShiftDutyRepeat.shouldShow(
        selectedZone: 'Zone 2',
        shiftDate: DateTime(2026, 10, 12),
        isMFMarkedIn: false,
        isShiftMarkedIn: true,
        isNightsRoster: false,
        markedInZone: 'Zone 2',
        jamestownEnabled: false,
      ),
      isTrue,
    );
    expect(
      WorkShiftDutyRepeat.shouldShow(
        selectedZone: 'Zone 2',
        shiftDate: DateTime(2026, 10, 17),
        isMFMarkedIn: false,
        isShiftMarkedIn: true,
        isNightsRoster: false,
        markedInZone: 'Zone 2',
        jamestownEnabled: false,
      ),
      isFalse,
    );
  });
}
