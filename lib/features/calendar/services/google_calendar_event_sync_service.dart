import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/models/event.dart';

typedef GoogleSyncEnabledReader = Future<bool> Function();
typedef GoogleSignedInReader = Future<bool> Function();
typedef GoogleEventLister = Future<List<calendar.Event>> Function({
  required DateTime startTime,
  required DateTime endTime,
});
typedef GoogleEventUpdater = Future<void> Function({
  required String eventId,
  required calendar.Event event,
});
typedef GoogleDescriptionBuilder = Future<String?> Function(Event event);
typedef GoogleWorkShiftAdder = Future<bool> Function({
  required BuildContext context,
  required String title,
  required DateTime startTime,
  required DateTime endTime,
  String? description,
});

/// Orchestrates syncing local calendar [Event]s to Google Calendar.
///
/// UI ownership (mounted checks, snackbars) stays with the caller where needed.
class GoogleCalendarEventSyncService {
  GoogleCalendarEventSyncService({
    required GoogleDescriptionBuilder buildDescription,
    GoogleSyncEnabledReader? isSyncEnabled,
    GoogleSignedInReader? isSignedIn,
    GoogleEventLister? listEvents,
    GoogleEventUpdater? updateEvent,
    GoogleWorkShiftAdder? addWorkShift,
  })  : _buildDescription = buildDescription,
        _isSyncEnabled = isSyncEnabled ??
            (() => StorageService.getBool(
                  AppConstants.syncToGoogleCalendarKey,
                  defaultValue: false,
                )),
        _isSignedIn = isSignedIn ?? GoogleCalendarService.isSignedIn,
        _listEvents = listEvents ??
            (({required startTime, required endTime}) =>
                GoogleCalendarService.listEvents(
                  startTime: startTime,
                  endTime: endTime,
                )),
        _updateEvent = updateEvent ??
            (({required eventId, required event}) =>
                GoogleCalendarService.updateEvent(
                  eventId: eventId,
                  event: event,
                )),
        _addWorkShift = addWorkShift ??
            (({
              required context,
              required title,
              required startTime,
              required endTime,
              description,
            }) =>
                CalendarTestHelper.addWorkShiftToCalendar(
                  context: context,
                  title: title,
                  startTime: startTime,
                  endTime: endTime,
                  description: description,
                ));

  final GoogleDescriptionBuilder _buildDescription;
  final GoogleSyncEnabledReader _isSyncEnabled;
  final GoogleSignedInReader _isSignedIn;
  final GoogleEventLister _listEvents;
  final GoogleEventUpdater _updateEvent;
  final GoogleWorkShiftAdder _addWorkShift;

  /// Updates an existing Google event description when bus assignments change.
  Future<void> syncBusAssignments(Event event) async {
    try {
      final syncEnabled = await _isSyncEnabled();
      final signedIn = await _isSignedIn();
      if (!syncEnabled || !signedIn) {
        return;
      }

      final startDateTime = _toDateTime(event.startDate, event.startTime);
      final endDateTime = _toDateTime(event.endDate, event.endTime);

      final dayStart = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final dayEnd = dayStart.add(const Duration(days: 1));

      final existingEvents = await _listEvents(
        startTime: dayStart.toUtc(),
        endTime: dayEnd.toUtc(),
      );

      calendar.Event? matchingEvent;
      for (final gcalEvent in existingEvents) {
        if (gcalEvent.summary == event.title &&
            gcalEvent.start?.dateTime != null &&
            gcalEvent.end?.dateTime != null) {
          final gcalStart = gcalEvent.start!.dateTime!.toLocal();
          final gcalEnd = gcalEvent.end!.dateTime!.toLocal();

          if ((gcalStart.difference(startDateTime).abs().inMinutes <= 1) &&
              (gcalEnd.difference(endDateTime).abs().inMinutes <= 1)) {
            matchingEvent = gcalEvent;
            break;
          }
        }
      }

      if (matchingEvent != null) {
        matchingEvent.description = await _buildDescription(event);
        await _updateEvent(
          eventId: matchingEvent.id!,
          event: matchingEvent,
        );
      }
    } catch (_) {
      // Continue silently - don't block user if sync fails
    }
  }

  /// Creates a Google Calendar event when sync is enabled and signed in.
  ///
  /// Returns `true` when a Google event was created successfully.
  Future<bool> syncNewEvent({
    required Event event,
    required BuildContext context,
    required bool Function() isMounted,
  }) async {
    if (!isMounted()) return false;

    final syncEnabled = await _isSyncEnabled();
    final signedIn = await _isSignedIn();
    if (!syncEnabled || !signedIn) {
      return false;
    }

    try {
      final startDateTime = _toDateTime(event.startDate, event.startTime);
      final endDateTime = _toDateTime(event.endDate, event.endTime);
      final finalDescription = await _buildDescription(event);

      if (!isMounted()) return false;
      return _addWorkShift(
        context: context,
        title: event.title,
        startTime: startDateTime,
        endTime: endDateTime,
        description: finalDescription,
      );
    } catch (_) {
      // Don't surface error - the local event was added successfully
      return false;
    }
  }

  DateTime _toDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
