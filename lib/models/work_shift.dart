import 'package:flutter/material.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';

class WorkShift {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String notes;

  WorkShift({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.notes = '',
  });

  // Add this method to save the shift to Google Calendar
  Future<bool> addToGoogleCalendar(BuildContext context) async {
    return await CalendarTestHelper.addWorkShiftToCalendar(
      context: context,
      title: title,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
