import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/services/event_status_update_service.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _event() {
  return Event(
    id: 'e1',
    title: 'PZ1/01',
    startDate: DateTime(2026, 8, 4),
    endDate: DateTime(2026, 8, 4),
    startTime: const TimeOfDay(hour: 5, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
  );
}

void main() {
  test('applyFullBreak clears overtime and marks full break', () {
    final event = _event();
    event.overtimeDuration = 30;
    EventStatusUpdateService.applyFullBreak(event);
    expect(event.hasLateBreak, isTrue);
    expect(event.tookFullBreak, isTrue);
    expect(event.overtimeDuration, isNull);
  });

  test('clearBreakStatus resets break fields', () {
    final event = _event()
      ..hasLateBreak = true
      ..tookFullBreak = true
      ..overtimeDuration = 45;
    EventStatusUpdateService.clearBreakStatus(event);
    expect(event.hasLateBreak, isFalse);
    expect(event.tookFullBreak, isFalse);
    expect(event.overtimeDuration, isNull);
  });

  test('applyOvertimeDuration persists via updater', () async {
    Event? oldSnap;
    Event? newSnap;
    final service = EventStatusUpdateService(
      updateEvent: (oldEvent, newEvent) async {
        oldSnap = oldEvent;
        newSnap = newEvent;
      },
    );

    final event = _event();
    await service.applyOvertimeDuration(event, 75);

    expect(oldSnap, isNotNull);
    expect(newSnap, same(event));
    expect(event.hasLateBreak, isTrue);
    expect(event.tookFullBreak, isFalse);
    expect(event.overtimeDuration, 75);
  });

  test('applySickDayType updates sick day type', () async {
    final service = EventStatusUpdateService(
      updateEvent: (_, __) async {},
    );
    final event = _event();
    await service.applySickDayType(event, 'normal');
    expect(event.sickDayType, 'normal');
  });

  test('statusRefreshTriggerEvent uses refresh id', () {
    final trigger = statusRefreshTriggerEvent(
      now: DateTime(2026, 8, 4, 12),
    );
    expect(trigger.id, 'refresh_trigger');
  });
}
