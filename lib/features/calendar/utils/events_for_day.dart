import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/holiday.dart';

/// Merges synthetic holiday events ahead of persisted day events.
List<Event> eventsForDay({
  required DateTime day,
  required List<Event> persistedEvents,
  required List<Holiday> holidays,
}) {
  final holidayEvents = <Event>[];

  for (final holiday in holidays) {
    if (!holiday.containsDate(day)) continue;

    final holidayExists = persistedEvents.any(
      (event) =>
          event.isHoliday &&
          event.holidayType == holiday.type &&
          event.startDate == day,
    );
    if (holidayExists) continue;

    holidayEvents.add(
      Event(
        id: 'holiday_${holiday.id}_${day.millisecondsSinceEpoch}',
        title: holidayTitleForType(holiday.type),
        startDate: day,
        startTime: const TimeOfDay(hour: 0, minute: 0),
        endDate: day,
        endTime: const TimeOfDay(hour: 23, minute: 59),
        isHoliday: true,
        holidayType: holiday.type,
      ),
    );
  }

  return [...holidayEvents, ...persistedEvents];
}

String holidayTitleForType(String type) {
  switch (type) {
    case 'winter':
      return 'Winter Holiday';
    case 'summer':
      return 'Summer Holiday';
    case 'unpaid_leave':
      return 'Unpaid Leave';
    case 'day_in_lieu':
      return 'Day In Lieu';
    case 'other':
    default:
      return 'Holiday';
  }
}
