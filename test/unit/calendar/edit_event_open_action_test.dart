import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/calendar/utils/edit_event_open_action.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _event({
  String id = 'e1',
  String title = 'PZ1/01',
  List<String>? assignedDuties,
}) {
  return Event(
    id: id,
    title: title,
    startDate: DateTime(2026, 8, 4),
    endDate: DateTime(2026, 8, 4),
    startTime: const TimeOfDay(hour: 5, minute: 0),
    endTime: const TimeOfDay(hour: 13, minute: 0),
    assignedDuties: assignedDuties,
  );
}

void main() {
  test('refresh_trigger routes to month refresh', () {
    expect(
      resolveEditEventOpenAction(_event(id: 'refresh_trigger')),
      EditEventOpenAction.refreshMonth,
    );
    expect(
      resolveEditEventOpenAction(_event(id: 'refresh_trigger_2')),
      EditEventOpenAction.refreshMonth,
    );
  });

  test('spare updates refresh in place', () {
    expect(
      resolveEditEventOpenAction(
        _event(title: 'SP0515', assignedDuties: ['PZ1/01']),
      ),
      EditEventOpenAction.refreshSpareInPlace,
    );
  });

  test('normal events open the dialog', () {
    expect(
      resolveEditEventOpenAction(_event()),
      EditEventOpenAction.openDialog,
    );
  });
}
