import 'package:flutter/material.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/models/event.dart';

typedef EventDeleteLocal = Future<void> Function(Event event);
typedef EventSyncEnabledReader = Future<bool> Function();
typedef EventSignedInReader = Future<bool> Function();
typedef EventGoogleDeleter = Future<bool> Function({
  required BuildContext context,
  required String title,
  DateTime? eventStartTime,
});

/// Deletes a local event and optionally removes the matching Google event.
class EventDeletionService {
  EventDeletionService({
    EventDeleteLocal? deleteLocal,
    EventSyncEnabledReader? isSyncEnabled,
    EventSignedInReader? isSignedIn,
    EventGoogleDeleter? deleteFromGoogle,
  })  : _deleteLocal = deleteLocal ?? EventService.deleteEvent,
        _isSyncEnabled = isSyncEnabled ??
            (() => StorageService.getBool(
                  AppConstants.syncToGoogleCalendarKey,
                  defaultValue: false,
                )),
        _isSignedIn = isSignedIn ?? GoogleCalendarService.isSignedIn,
        _deleteFromGoogle = deleteFromGoogle ??
            (({
              required context,
              required title,
              eventStartTime,
            }) =>
                CalendarTestHelper.deleteEventFromCalendar(
                  context: context,
                  title: title,
                  eventStartTime: eventStartTime,
                ));

  final EventDeleteLocal _deleteLocal;
  final EventSyncEnabledReader _isSyncEnabled;
  final EventSignedInReader _isSignedIn;
  final EventGoogleDeleter _deleteFromGoogle;

  Future<void> deleteEvent({
    required Event event,
    required BuildContext context,
    required bool Function() isMounted,
  }) async {
    await _deleteLocal(event);

    final syncEnabled = await _isSyncEnabled();
    final signedIn = await _isSignedIn();
    if (!syncEnabled || !signedIn) {
      return;
    }

    try {
      final startDateTime = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
        event.startTime.hour,
        event.startTime.minute,
      );
      if (!isMounted()) return;
      await _deleteFromGoogle(
        context: context,
        title: event.title,
        eventStartTime: startDateTime,
      );
    } catch (_) {
      // Local delete already succeeded.
    }
  }
}
