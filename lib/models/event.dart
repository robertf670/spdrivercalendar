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
  final String? startLocation;
  final String? finishLocation;
  final String? startBreakLocation;
  final String? finishBreakLocation;

  AssignedDuty({
    required this.dutyCode,
    this.assignedBus,
    this.startTime,
    this.endTime,
    this.location,
    this.isHalfDuty,
    this.isSecondHalf,
    this.startLocation,
    this.finishLocation,
    this.startBreakLocation,
    this.finishBreakLocation,
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
      'startLocation': startLocation,
      'finishLocation': finishLocation,
      'startBreakLocation': startBreakLocation,
      'finishBreakLocation': finishBreakLocation,
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
      startLocation: map['startLocation'],
      finishLocation: map['finishLocation'],
      startBreakLocation: map['startBreakLocation'],
      finishBreakLocation: map['finishBreakLocation'],
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
    String? startLocation,
    String? finishLocation,
    String? startBreakLocation,
    String? finishBreakLocation,
  }) {
    return AssignedDuty(
      dutyCode: dutyCode ?? this.dutyCode,
      assignedBus: assignedBus ?? this.assignedBus,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      isHalfDuty: isHalfDuty ?? this.isHalfDuty,
      isSecondHalf: isSecondHalf ?? this.isSecondHalf,
      startLocation: startLocation ?? this.startLocation,
      finishLocation: finishLocation ?? this.finishLocation,
      startBreakLocation: startBreakLocation ?? this.startBreakLocation,
      finishBreakLocation: finishBreakLocation ?? this.finishBreakLocation,
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
  TimeOfDay? breakStartTime;  // For UNI shifts and PZ shifts
  TimeOfDay? breakEndTime;    // For UNI shifts and PZ shifts
  List<String>? routes;  // Route information for PZ shifts (e.g., ["39A", "C1"])
  String? startLocation;  // Start location for the shift
  String? finishLocation;  // Finish location for the shift
  String? startBreakLocation;  // Start break location
  String? finishBreakLocation;  // Finish break location
  String? dutyStartTime;  // Actual duty start time (depart time, different from report time)
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
  // Sick day status: null, 'normal', 'self-certified', or 'force-majeure'
  String? sickDayType;

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
    this.routes,
    this.startLocation,
    this.finishLocation,
    this.startBreakLocation,
    this.finishBreakLocation,
    this.dutyStartTime,
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
    this.sickDayType,
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
      
      // CRITICAL FIX: Keep assignedDuties in sync with enhancedAssignedDuties
      // Don't clear assignedDuties - the codebase still relies on it for display and operations
      // This ensures duties persist correctly after app restart
      assignedDuties = enhancedAssignedDuties!.map((duty) => duty.dutyCode).toList();
    } else if (hasEnhancedDuties && (assignedDuties == null || assignedDuties!.isEmpty)) {
      // If we have enhanced duties but no legacy duties, sync them
      assignedDuties = enhancedAssignedDuties!.map((duty) => duty.dutyCode).toList();
    }
  }

  // Get current duties (enhanced or legacy)
  List<String> getCurrentDutyCodes() {
    if (hasEnhancedDuties) {
      return enhancedAssignedDuties!.map((duty) => duty.dutyCode).toList();
    }
    return assignedDuties ?? [];
  }

  // CRITICAL FIX: Sync assignedDuties with enhancedAssignedDuties to ensure persistence
  // Call this whenever assignedDuties is modified to keep both formats in sync
  void syncDutyFormats() {
    // CRITICAL FIX: Check if assignedDuties has been modified (has more items than enhancedAssignedDuties)
    // This handles the case where a duty was added directly to assignedDuties
    if (hasEnhancedDuties && assignedDuties != null) {
      final enhancedCount = enhancedAssignedDuties!.length;
      final assignedCount = assignedDuties!.length;
      
      // If assignedDuties has more items, it means a new duty was added - sync TO enhancedAssignedDuties
      if (assignedCount > enhancedCount) {
        // Update enhancedAssignedDuties to include the new duty
        // Store the original enhancedAssignedDuties before modifying
        final originalEnhancedDuties = List<AssignedDuty>.from(enhancedAssignedDuties!);
        final enhancedDutyCodes = originalEnhancedDuties.map((d) => d.dutyCode).toList();
        enhancedAssignedDuties = assignedDuties!.map((dutyString) {
          // Check if this duty already exists in enhancedAssignedDuties
          final existingIndex = enhancedDutyCodes.indexOf(dutyString);
          if (existingIndex >= 0) {
            // Duty exists - keep the existing enhanced duty object
            return originalEnhancedDuties[existingIndex];
          } else {
            // New duty - create a new AssignedDuty from the string
            return AssignedDuty.fromLegacyString(dutyString);
          }
        }).toList();
      } else if (assignedCount == enhancedCount) {
        // Same count - sync assignedDuties from enhancedAssignedDuties to ensure consistency
        assignedDuties = enhancedAssignedDuties!.map((duty) => duty.dutyCode).toList();
      } else {
        // assignedDuties has fewer items - sync from enhancedAssignedDuties
        assignedDuties = enhancedAssignedDuties!.map((duty) => duty.dutyCode).toList();
      }
    } else if (assignedDuties != null && assignedDuties!.isNotEmpty) {
      // No enhanced duties yet - create them from assignedDuties
      if (!hasEnhancedDuties) {
        enhancedAssignedDuties = assignedDuties!.map((dutyString) => AssignedDuty.fromLegacyString(dutyString)).toList();
      }
    }
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
    String? sickDayType,
    List<String>? routes,
    String? startLocation,
    String? finishLocation,
    String? startBreakLocation,
    String? finishBreakLocation,
    String? dutyStartTime,
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
      routes: routes ?? this.routes,
      startLocation: startLocation ?? this.startLocation,
      finishLocation: finishLocation ?? this.finishLocation,
      startBreakLocation: startBreakLocation ?? this.startBreakLocation,
      finishBreakLocation: finishBreakLocation ?? this.finishBreakLocation,
      dutyStartTime: dutyStartTime ?? this.dutyStartTime,
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
      sickDayType: sickDayType ?? this.sickDayType,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    // CRITICAL FIX: Sync duty formats before saving to ensure persistence
    syncDutyFormats();
    
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
      'routes': routes,
      'startLocation': startLocation,
      'finishLocation': finishLocation,
      'startBreakLocation': startBreakLocation,
      'finishBreakLocation': finishBreakLocation,
      'dutyStartTime': dutyStartTime,
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
      'sickDayType': sickDayType,
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
      routes: map['routes'] != null
        ? List<String>.from(map['routes'])
        : null,
      startLocation: map['startLocation'],
      finishLocation: map['finishLocation'],
      startBreakLocation: map['startBreakLocation'],
      finishBreakLocation: map['finishBreakLocation'],
      dutyStartTime: map['dutyStartTime'],
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
      sickDayType: map['sickDayType'],  // Nullable for backwards compatibility
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
