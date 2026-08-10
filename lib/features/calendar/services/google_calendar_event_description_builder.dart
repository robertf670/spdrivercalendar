import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/sick_day_display.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/services/bus_tracking_service.dart';

/// Builds Google Calendar event descriptions for local [Event]s.
class GoogleCalendarEventDescriptionBuilder {
  /// Optional [busUrlLookup] / [readBool] hooks keep unit tests offline.
  static Future<String?> build({
    required Event event,
    required Future<String?> Function(Event event) getBreakTime,
    required bool Function(DateTime date) isWorkingOnRestDay,
    Future<String?> Function(String busNumber)? busUrlLookup,
    Future<bool> Function(String key, {required bool defaultValue})? readBool,
  }) async {
    final boolReader = readBool ?? StorageService.getBool;
    final urlLookup = busUrlLookup ?? BusTrackingService.getBusUrl;
    final descriptionParts = <String>[];

    final breakTime = await getBreakTime(event);
    if (breakTime != null &&
        !breakTime.toLowerCase().contains('workout') &&
        breakTime.isNotEmpty) {
      descriptionParts.add('Break Times: $breakTime');
    }

    if (event.isWorkForOthers) {
      descriptionParts.add('(Work For Others)');
    } else if (isWorkingOnRestDay(event.startDate)) {
      descriptionParts.add('(Working on Rest Day)');
    }

    if (event.sickDayType != null) {
      final sickDayLabel = SickDayDisplay.typeLabel(event.sickDayType!);
      descriptionParts.add('📋 Sick Day: $sickDayLabel');
    }

    final includeBusAssignments = await boolReader(
      AppConstants.includeBusAssignmentsInGoogleCalendarKey,
      defaultValue: true,
    );

    if (includeBusAssignments) {
      final busInfo = await formatBusAssignment(
        event: event,
        busUrlLookup: urlLookup,
        readBool: boolReader,
      );
      if (busInfo != null) {
        if (descriptionParts.isNotEmpty) {
          descriptionParts.add('');
        }
        descriptionParts.add('Bus Assignment:');
        descriptionParts.add(busInfo);
      }
    }

    final description = descriptionParts.join('\n');
    return description.isEmpty ? null : description;
  }

  static Future<String?> formatBusAssignment({
    required Event event,
    Future<String?> Function(String busNumber)? busUrlLookup,
    Future<bool> Function(String key, {required bool defaultValue})? readBool,
  }) async {
    final boolReader = readBool ?? StorageService.getBool;
    final urlLookup = busUrlLookup ?? BusTrackingService.getBusUrl;
    final includeLinks = await boolReader(
      AppConstants.includeBustimesLinksInGoogleCalendarKey,
      defaultValue: true,
    );

    Future<String> busLine(String label, String busNumber) async {
      if (includeLinks) {
        final busUrl = await urlLookup(busNumber);
        if (busUrl != null) {
          return '$label: $busNumber ($busUrl)';
        }
      }
      return '$label: $busNumber';
    }

    if (event.title.toLowerCase().contains('workout')) {
      final workoutBus = event.firstHalfBus ??
          (event.busAssignments?.values.isNotEmpty == true
              ? event.busAssignments!.values.first
              : null);
      if (workoutBus != null && workoutBus.isNotEmpty) {
        if (includeLinks) {
          final busUrl = await urlLookup(workoutBus);
          if (busUrl != null) {
            return 'Bus: $workoutBus ($busUrl)';
          }
        }
        return 'Bus: $workoutBus';
      }
      return null;
    }

    final busParts = <String>[];

    if (event.firstHalfBus != null && event.firstHalfBus!.isNotEmpty) {
      busParts.add(await busLine('First Half', event.firstHalfBus!));
    }

    if (event.secondHalfBus != null && event.secondHalfBus!.isNotEmpty) {
      busParts.add(await busLine('Second Half', event.secondHalfBus!));
    }

    if (event.busAssignments != null && event.busAssignments!.isNotEmpty) {
      for (final entry in event.busAssignments!.entries) {
        final dutyCode = entry.key;
        final busNumber = entry.value;
        if (busNumber.isNotEmpty) {
          busParts.add(await busLine(dutyCode, busNumber));
        }
      }
    }

    if (busParts.isEmpty) return null;
    return busParts.join('\n');
  }
}
