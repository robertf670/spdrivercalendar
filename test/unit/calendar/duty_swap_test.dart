import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/duty_swap.dart';
import 'package:spdrivercalendar/features/calendar/utils/marked_in_status.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

void main() {
  test('duty zone follows the title', () {
    expect(dutySwapZoneLabel('PZ1/01'), 'Zone 1');
    expect(dutySwapZoneLabel('13/22'), 'Route 13');
    expect(dutySwapZoneLabel('PZ4/33 (OT)'), 'Zone 4');
    expect(dutySwapZoneLabel('307/01'), 'Uni/Euro');
    expect(dutySwapZoneLabel('311/12'), 'Jamestown Road (40hr)');
    expect(
      dutySwapZoneLabel('811/36', jamestown30hr: true),
      JamestownFeatureService.zoneLabel,
    );
    expect(dutySwapZoneLabel('SP0800'), isNull);
  });

  test('week checkbox is for Jamestown, Monday-Friday, Shift, or the dev menu', () {
    expect(MarkedInStatus.showsWeekDutySwap(MarkedInStatus.jamestown), isTrue);
    expect(MarkedInStatus.showsWeekDutySwap(MarkedInStatus.mf), isTrue);
    expect(MarkedInStatus.showsWeekDutySwap(MarkedInStatus.shift), isTrue);
    expect(MarkedInStatus.showsWeekDutySwap(MarkedInStatus.spare), isFalse);
    expect(MarkedInStatus.showsWeekDutySwap(MarkedInStatus.fourDay), isFalse);
    expect(MarkedInStatus.showsWeekDutySwap(MarkedInStatus.nights), isFalse);
    expect(
      showDutySwapWeekCheckbox(
        markedInEnabled: false,
        status: MarkedInStatus.spare,
        jamestownDevMenu: true,
      ),
      isTrue,
    );
    expect(
      showDutySwapWeekCheckbox(
        markedInEnabled: true,
        status: MarkedInStatus.spare,
        jamestownDevMenu: false,
      ),
      isFalse,
    );
  });

  test('a swapped duty keeps the late break and clears the old places', () {
    final event = Event(
      id: '1',
      title: '13/22',
      startDate: DateTime(2026, 11, 25),
      startTime: const TimeOfDay(hour: 13, minute: 35),
      endDate: DateTime(2026, 11, 25),
      endTime: const TimeOfDay(hour: 21, minute: 20),
      startLocation: 'Mountjoy Square',
      firstHalfBus: 'PA100',
    )
      ..hasLateBreak = true
      ..overtimeDuration = 15;

    final updated = eventWithSwappedDuty(
      event: event,
      title: '13/25',
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 22, minute: 0),
      isNextDay: false,
      workTime: const Duration(hours: 7, minutes: 10),
    );

    expect(updated.title, '13/25');
    expect(updated.startTime, const TimeOfDay(hour: 14, minute: 0));
    expect(updated.hasLateBreak, isTrue);
    expect(updated.overtimeDuration, 15);
    expect(updated.firstHalfBus, 'PA100');
    expect(updated.startLocation, isNull);
    expect(event.title, '13/22');
    expect(event.startLocation, 'Mountjoy Square');
  });

  test('week days are Monday to Friday', () {
    final days = dutySwapWeekDays(DateTime(2026, 11, 25));
    expect(days.map((day) => day.weekday).toList(), [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ]);
    expect(
      days.any((day) =>
          day.weekday == DateTime.saturday || day.weekday == DateTime.sunday),
      isFalse,
    );
  });
}
