import 'package:flutter/material.dart';

// New class for enhanced duty tracking
class AssignedDuty {
  final String dutyCode;
  final String? assignedBus;
  final String? startTime;
  final String? endTime;
  final String? location;
  final bool? isHalfDuty;
  final bool? isSecondHalf;

  AssignedDuty({
    required this.dutyCode,
    this.assignedBus,
    this.startTime,
    this.endTime,
    this.location,
    this.isHalfDuty,
    this.isSecondHalf,
  });

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'dutyCode': dutyCode,
      'assignedBus': assignedBus,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'isHalfDuty': isHalfDuty,
      'isSecondHalf': isSecondHalf,
    };
  }

  // Create from map
  factory AssignedDuty.fromMap(Map<String, dynamic> map) {
    return AssignedDuty(
      dutyCode: map['dutyCode'],
      assignedBus: map['assignedBus'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      location: map['location'],
      isHalfDuty: map['isHalfDuty'],
      isSecondHalf: map['isSecondHalf'],
    );
  }

  // Create from legacy string format for migration
  factory AssignedDuty.fromLegacyString(String dutyString) {
    return AssignedDuty(
      dutyCode: dutyString,
    );
  }

  // Copy with method for updates
  AssignedDuty copyWith({
    String? dutyCode,
    String? assignedBus,
    String? startTime,
    String? endTime,
    String? location,
    bool? isHalfDuty,
    bool? isSecondHalf,
  }) {
    return AssignedDuty(
      dutyCode: dutyCode ?? this.dutyCode,
      assignedBus: assignedBus ?? this.assignedBus,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      isHalfDuty: isHalfDuty ?? this.isHalfDuty,
      isSecondHalf: isSecondHalf ?? this.isSecondHalf,
    );
  }
}

class Event {
  final String id;
  String title;
  DateTime startDate;
  TimeOfDay startTime;
  DateTime endDate;
  TimeOfDay endTime;
  Duration? workTime;  // For PZ shifts
  TimeOfDay? breakStartTime;  // For UNI shifts
  TimeOfDay? breakEndTime;    // For UNI shifts
  List<String>? assignedDuties;  // For storing multiple duties assigned to spare shifts (legacy)
  List<AssignedDuty>? enhancedAssignedDuties;  // New enhanced duty tracking
  String? firstHalfBus;  // For storing the first half bus number
  String? secondHalfBus;  // For storing the second half bus number
  Map<String, String>? busAssignments;  // Map of duty code to assigned bus number
  bool isHoliday;  // Whether this event represents a holiday
  String? holidayType;  // The type of holiday ('winter' or 'summer')
  String? notes; // Add notes field
  // Add new fields for overtime tracking
  bool hasLateBreak;
  bool tookFullBreak; 
  int? overtimeDuration; // In minutes

  Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    this.workTime,
    this.breakStartTime,
    this.breakEndTime,
    this.assignedDuties,
    this.enhancedAssignedDuties,
    this.firstHalfBus,
    this.secondHalfBus,
    this.busAssignments,
    this.isHoliday = false,
    this.holidayType,
    this.notes,
    this.hasLateBreak = false,
    this.tookFullBreak = false,
    this.overtimeDuration,
  });

  // Helper method to check if using enhanced duties
  bool get hasEnhancedDuties => enhancedAssignedDuties != null && enhancedAssignedDuties!.isNotEmpty;

  // Migrate legacy duties to enhanced format
  void migrateLegacyDuties() {
    if (assignedDuties != null && assignedDuties!.isNotEmpty && !hasEnhancedDuties) {
      enhancedAssignedDuties = assignedDuties!.map((dutyString) => AssignedDuty.fromLegacyString(dutyString)).toList();
      
      // Migrate bus assignments if this is a spare shift
      if (title.startsWith('SP') && enhancedAssignedDuties!.isNotEmpty) {
        // Assign firstHalfBus to first duty, secondHalfBus to second duty if they exist
        if (firstHalfBus != null && enhancedAssignedDuties!.isNotEmpty) {
          enhancedAssignedDuties![0] = enhancedAssignedDuties![0].copyWith(assignedBus: firstHalfBus);
        }
        if (secondHalfBus != null && enhancedAssignedDuties!.length > 1) {
          enhancedAssignedDuties![1] = enhancedAssignedDuties![1].copyWith(assignedBus: secondHalfBus);
        }
      }
      
      // Clear legacy fields after migration
      assignedDuties = null;
    }
  }

  // Get current duties (enhanced or legacy)
  List<String> getCurrentDutyCodes() {
    if (hasEnhancedDuties) {
      return enhancedAssignedDuties!.map((duty) => duty.dutyCode).toList();
    }
    return assignedDuties ?? [];
  }

  // Get assigned bus for a specific duty
  String? getBusForDuty(String dutyCode) {
    return busAssignments?[dutyCode];
  }

  // Set assigned bus for a specific duty
  void setBusForDuty(String dutyCode, String? busNumber) {
    if (busNumber == null || busNumber.trim().isEmpty) {
      // Remove bus assignment
      busAssignments?.remove(dutyCode);
      if (busAssignments?.isEmpty == true) {
        busAssignments = null;
      }
    } else {
      // Add/update bus assignment
      busAssignments ??= {};
      busAssignments![dutyCode] = busNumber.trim();
    }
  }

  // Add copyWith method
  Event copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    TimeOfDay? startTime,
    DateTime? endDate,
    TimeOfDay? endTime,
    Duration? workTime,
    TimeOfDay? breakStartTime,
    TimeOfDay? breakEndTime,
    List<String>? assignedDuties,
    List<AssignedDuty>? enhancedAssignedDuties,
    String? firstHalfBus,
    String? secondHalfBus,
    Map<String, String>? busAssignments,
    bool? isHoliday,
    String? holidayType,
    String? notes,
    bool? hasLateBreak,
    bool? tookFullBreak,
    int? overtimeDuration,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      workTime: workTime ?? this.workTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      assignedDuties: assignedDuties ?? this.assignedDuties,
      enhancedAssignedDuties: enhancedAssignedDuties ?? this.enhancedAssignedDuties,
      firstHalfBus: firstHalfBus ?? this.firstHalfBus,
      secondHalfBus: secondHalfBus ?? this.secondHalfBus,
      busAssignments: busAssignments ?? this.busAssignments,
      isHoliday: isHoliday ?? this.isHoliday,
      holidayType: holidayType ?? this.holidayType,
      notes: notes ?? this.notes,
      hasLateBreak: hasLateBreak ?? this.hasLateBreak,
      tookFullBreak: tookFullBreak ?? this.tookFullBreak,
      overtimeDuration: overtimeDuration ?? this.overtimeDuration,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
      'endDate': endDate.toIso8601String(),
      'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
      'workTime': workTime?.inMinutes,  // Store work time in minutes
      'breakStartTime': breakStartTime != null 
        ? {'hour': breakStartTime!.hour, 'minute': breakStartTime!.minute}
        : null,
      'breakEndTime': breakEndTime != null
        ? {'hour': breakEndTime!.hour, 'minute': breakEndTime!.minute}
        : null,
      'assignedDuties': assignedDuties,
      'enhancedAssignedDuties': enhancedAssignedDuties?.map((duty) => duty.toMap()).toList(),
      'firstHalfBus': firstHalfBus,
      'secondHalfBus': secondHalfBus,
      'busAssignments': busAssignments,
      'isHoliday': isHoliday,
      'holidayType': holidayType,
      'notes': notes,
      'hasLateBreak': hasLateBreak,
      'tookFullBreak': tookFullBreak,
      'overtimeDuration': overtimeDuration,
    };
  }

  // Create from map from storage
  factory Event.fromMap(Map<String, dynamic> map) {
    final event = Event(
      id: map['id'],
      title: map['title'],
      startDate: DateTime.parse(map['startDate']),
      startTime: TimeOfDay(
        hour: map['startTime']['hour'],
        minute: map['startTime']['minute'],
      ),
      endDate: DateTime.parse(map['endDate']),
      endTime: TimeOfDay(
        hour: map['endTime']['hour'],
        minute: map['endTime']['minute'],
      ),
      workTime: map['workTime'] != null 
        ? Duration(minutes: map['workTime'])
        : null,
      breakStartTime: map['breakStartTime'] != null
        ? TimeOfDay(
            hour: map['breakStartTime']['hour'],
            minute: map['breakStartTime']['minute'],
          )
        : null,
      breakEndTime: map['breakEndTime'] != null
        ? TimeOfDay(
            hour: map['breakEndTime']['hour'],
            minute: map['breakEndTime']['minute'],
          )
        : null,
      assignedDuties: map['assignedDuties'] != null 
        ? List<String>.from(map['assignedDuties'])
        : null,
      enhancedAssignedDuties: map['enhancedAssignedDuties'] != null
        ? (map['enhancedAssignedDuties'] as List)
            .map((dutyMap) => AssignedDuty.fromMap(dutyMap))
            .toList()
        : null,
      firstHalfBus: map['firstHalfBus'],
      secondHalfBus: map['secondHalfBus'],
      busAssignments: map['busAssignments'] != null 
        ? Map<String, String>.from(map['busAssignments'])
        : null,
      isHoliday: map['isHoliday'] ?? false,
      holidayType: map['holidayType'],
      notes: map['notes'],
      hasLateBreak: map['hasLateBreak'] ?? false,
      tookFullBreak: map['tookFullBreak'] ?? false,
      overtimeDuration: map['overtimeDuration'],
    );
    
    // Auto-migrate legacy duties if needed
    event.migrateLegacyDuties();
    
    return event;
  }

  // Format times for display
  String get formattedStartTime => _formatTimeOfDay(startTime);
  String get formattedEndTime => _formatTimeOfDay(endTime);
  
  // Get a full DateTime with time components
  DateTime get fullStartDateTime => DateTime(
    startDate.year,
    startDate.month, 
    startDate.day,
    startTime.hour,
    startTime.minute,
  );
  
  DateTime get fullEndDateTime => DateTime(
    endDate.year,
    endDate.month, 
    endDate.day,
    endTime.hour,
    endTime.minute,
  );
  
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Is this a work shift?
  bool get isWorkShift => title.startsWith('Shift:') || 
                         title.startsWith('SP') || 
                         title.startsWith('PZ') || 
                         title.startsWith('BusCheck') ||
                         title == 'TRAIN23/24' ||
                         title == 'CPC' ||
                         title == '22B/01' ||
                         RegExp(r'^\d+/').hasMatch(title);
  
  // Check if this duty is eligible for overtime tracking
  bool get isEligibleForOvertimeTracking {
    // First check if it's a work shift
    if (!isWorkShift) return false;
    
    // Include spare duties and 22B/01
    final isSpareOrSpecial = title.startsWith('SP') || title == '22B/01';
    
    // Check if it's a Zone 1, 3, or 4 duty
    final isZoneDuty = title.startsWith('PZ1') || 
                      title.startsWith('PZ3') || 
                      title.startsWith('PZ4') ||
                      // Handle case when PZ is not in the title
                      title.startsWith('1/') || 
                      title.startsWith('3/') || 
                      title.startsWith('4/');
    
    // Exclude workout shifts - look for 'workout' in the title
    final isWorkout = title.toLowerCase().contains('workout');
    
    return (isZoneDuty && !isWorkout) || isSpareOrSpecial;
  }
  
  // Get shift code - properly handle shift codes
  String get shiftCode {
    String code = title;
    if (title.startsWith('Shift:')) {
      code = title.substring(6).trim();
    }
    if (!code.startsWith('PZ') && (code.startsWith('1') || code.startsWith('3') || code.startsWith('4'))) {
      code = 'PZ$code';
    }
    return code;
  }

  factory Event.fromList(List<String> data) {
    // Parse work time if it exists (for PZ shifts)
    Duration? workTime;
    if (data.length > 14 && data[14].isNotEmpty) {  // Changed from 8 to 14 to read from correct column
      final parts = data[14].split(':');
      if (parts.length == 2) {
        workTime = Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
        );
      }
    }

    return Event(
      id: '',
      title: data[0],
      startDate: DateTime.parse(data[1]),
      endDate: DateTime.parse(data[2]),
      startTime: TimeOfDay(
        hour: int.parse(data[3].split(':')[0]),
        minute: int.parse(data[3].split(':')[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(data[4].split(':')[0]),
        minute: int.parse(data[4].split(':')[1]),
      ),
      workTime: workTime,
    );
  }
}
