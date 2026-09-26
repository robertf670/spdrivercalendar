import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spdrivercalendar/features/bus_reports/bus_report_assign_warning.dart';
import 'package:spdrivercalendar/models/event.dart';

Event _event({String? first, String? second}) {
  return Event(
    id: 'e1',
    title: 'PZ1/39',
    startDate: DateTime(2026, 9, 26),
    startTime: const TimeOfDay(hour: 8, minute: 0),
    endDate: DateTime(2026, 9, 26),
    endTime: const TimeOfDay(hour: 16, minute: 0),
    firstHalfBus: first,
    secondHalfBus: second,
  );
}

void main() {
  test('primaryAssignedBuses normalizes and ignores empty values', () {
    expect(
      primaryAssignedBuses(_event(first: 'sg 123', second: '')),
      {'SG123'},
    );
    expect(primaryAssignedBuses(_event()), isEmpty);
  });
}
