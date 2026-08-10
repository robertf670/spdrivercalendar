import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/models/event.dart';

typedef EventStatusUpdater = Future<void> Function(Event oldEvent, Event newEvent);

/// Persistence helpers for break / overtime / late-finish / sick-day status edits.
///
/// Dialog navigation and snackbars stay with the caller.
class EventStatusUpdateService {
  EventStatusUpdateService({EventStatusUpdater? updateEvent})
      : _updateEvent = updateEvent ?? EventService.updateEvent;

  final EventStatusUpdater _updateEvent;

  /// Snapshot used by break/OT/late-finish updates (matches prior screen fields).
  Event snapshotForStatusUpdate(Event event) {
    return Event(
      id: event.id,
      title: event.title,
      startDate: event.startDate,
      startTime: event.startTime,
      endDate: event.endDate,
      endTime: event.endTime,
      workTime: event.workTime,
      breakStartTime: event.breakStartTime,
      breakEndTime: event.breakEndTime,
      assignedDuties: event.assignedDuties,
      busAssignments: event.busAssignments,
      firstHalfBus: event.firstHalfBus,
      secondHalfBus: event.secondHalfBus,
      notes: event.notes,
      hasLateBreak: event.hasLateBreak,
      tookFullBreak: event.tookFullBreak,
      overtimeDuration: event.overtimeDuration,
      hasLateFinish: event.hasLateFinish,
      lateFinishDuration: event.lateFinishDuration,
    );
  }

  /// Snapshot used by sick-day updates (matches prior screen fields).
  Event snapshotForSickDayUpdate(Event event) {
    return Event(
      id: event.id,
      title: event.title,
      startDate: event.startDate,
      startTime: event.startTime,
      endDate: event.endDate,
      endTime: event.endTime,
      workTime: event.workTime,
      breakStartTime: event.breakStartTime,
      breakEndTime: event.breakEndTime,
      assignedDuties: event.assignedDuties,
      firstHalfBus: event.firstHalfBus,
      secondHalfBus: event.secondHalfBus,
      busAssignments: event.busAssignments,
      notes: event.notes,
      hasLateBreak: event.hasLateBreak,
      tookFullBreak: event.tookFullBreak,
      overtimeDuration: event.overtimeDuration,
      sickDayType: event.sickDayType,
    );
  }

  Future<void> applyBreakStatusChange(
    Event event, {
    required void Function(Event event) applyChanges,
  }) async {
    final oldEvent = snapshotForStatusUpdate(event);
    applyChanges(event);
    await _updateEvent(oldEvent, event);
  }

  Future<void> applyOvertimeDuration(Event event, int durationMinutes) {
    return applyBreakStatusChange(
      event,
      applyChanges: (target) {
        target.hasLateBreak = true;
        target.tookFullBreak = false;
        target.overtimeDuration = durationMinutes;
      },
    );
  }

  Future<void> applyLateFinishDuration(Event event, int durationMinutes) {
    return applyBreakStatusChange(
      event,
      applyChanges: (target) {
        target.hasLateFinish = true;
        target.lateFinishDuration = durationMinutes;
      },
    );
  }

  Future<void> applySickDayType(Event event, String? sickDayType) async {
    final oldEvent = snapshotForSickDayUpdate(event);
    event.sickDayType = sickDayType;
    await _updateEvent(oldEvent, event);
  }

  static void clearBreakStatus(Event target) {
    target.hasLateBreak = false;
    target.tookFullBreak = false;
    target.overtimeDuration = null;
  }

  static void applyFullBreak(Event target) {
    target.hasLateBreak = true;
    target.tookFullBreak = true;
    target.overtimeDuration = null;
  }

  static void clearLateFinish(Event target) {
    target.hasLateFinish = false;
    target.lateFinishDuration = null;
  }
}

/// Builds the empty refresh-trigger event used after status dialogs.
Event statusRefreshTriggerEvent({DateTime? now}) {
  final timestamp = now ?? DateTime.now();
  return Event(
    id: 'refresh_trigger',
    title: '',
    startDate: timestamp,
    startTime: const TimeOfDay(hour: 0, minute: 0),
    endDate: timestamp,
    endTime: const TimeOfDay(hour: 0, minute: 0),
    busAssignments: {},
  );
}
