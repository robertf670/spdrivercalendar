import 'package:flutter/material.dart';

class Event {
  String title;
  String description;
  DateTime startDate;
  DateTime endDate;
  TimeOfDay startTime;
  TimeOfDay endTime;

  Event({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
  });

  // Convert Event to a Map for saving to a database or API
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(), // Store the DateTime as a string
      'endDate': endDate.toIso8601String(),
      // Convert TimeOfDay to a string in 'HH:mm' format
      'startTime': _timeOfDayToString(startTime),
      'endTime': _timeOfDayToString(endTime),
    };
  }

  // Optionally, you can create a fromMap method to retrieve events from storage
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      title: map['title'],
      description: map['description'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      // Convert string back to TimeOfDay
      startTime: _stringToTimeOfDay(map['startTime']),
      endTime: _stringToTimeOfDay(map['endTime']),
    );
  }

  // Helper method to convert TimeOfDay to a string in HH:mm format
  String _timeOfDayToString(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  // Helper method to convert string back to TimeOfDay
  static TimeOfDay _stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }
}
