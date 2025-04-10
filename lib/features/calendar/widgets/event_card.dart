import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/core/utils/location_utils.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:csv/csv.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final String shiftType;
  final Map<String, ShiftInfo> shiftInfoMap;
  final Function(Event) onEdit;
  final bool isBankHoliday;
  final bool isRestDay;
  final Function(Event) onShowNotes;

  const EventCard({
    Key? key,
    required this.event,
    required this.shiftType,
    required this.shiftInfoMap,
    required this.onEdit,
    this.isBankHoliday = false,
    this.isRestDay = false,
    required this.onShowNotes,
  }) : super(key: key);

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  String? startLocation;
  String? finishLocation;
  String? breakTime;
  String? startBreakLocation;
  String? finishBreakLocation;
  String? workTime;
  String? _departTimeStr;
  String? _finishTimeStr;
  bool isLoading = true;
  String? _assignedDutyStartTime;
  String? _assignedDutyEndTime;
  String? _assignedDutyStartLocation;
  String? _assignedDutyEndLocation;
  List<Map<String, String?>> _allDutyDetails = [];

  @override
  void initState() {
    super.initState();
    _loadBreakTime();
    _loadLocationData();
    if (widget.event.assignedDuties != null && widget.event.assignedDuties!.isNotEmpty) {
      _loadAssignedDutyDetails();
    }
  }

  @override
  void didUpdateWidget(EventCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if the event or assigned duties have changed
    if (oldWidget.event != widget.event || 
        oldWidget.event.assignedDuties != widget.event.assignedDuties) {
      _loadBreakTime();
      _loadLocationData();
      if (widget.event.assignedDuties != null && widget.event.assignedDuties!.isNotEmpty) {
        _loadAssignedDutyDetails();
      } else {
        // Clear duty details if no duties are assigned
        setState(() {
          _assignedDutyStartTime = null;
          _assignedDutyEndTime = null;
          _assignedDutyStartLocation = null;
          _assignedDutyEndLocation = null;
          _allDutyDetails = [];
        });
      }
    }
  }

  Future<void> _loadBreakTime() async {
    try {
      final breakTimeStr = await ShiftService.getBreakTime(widget.event);
      if (mounted) {
        setState(() {
          breakTime = breakTimeStr;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading break time: $e');
      if (mounted) {
        setState(() {
          breakTime = 'Workout';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLocationData() async {
    try {
      // Extract the shift code
      final shiftCode = widget.event.title.replaceAll('Shift: ', '').trim();
      
      // Skip for spare shifts
      if (shiftCode.startsWith('SP')) {
        setState(() {
          startLocation = null;
          finishLocation = null;
          startBreakLocation = null;
          finishBreakLocation = null;
          workTime = null;
        });
        return;
      }
      
      // Special handling for UNI/Euro shifts
      if (RegExp(r'^\d{2,3}/').hasMatch(shiftCode)) {
        await _loadUniShiftData(shiftCode);
        return;
      }
      
      // Regular shift handling for PZ shifts
      // Get the day of week and check if it's a bank holiday
      final dayOfWeek = RosterService.getDayOfWeek(widget.event.startDate);
      final bankHoliday = ShiftService.getBankHoliday(widget.event.startDate, ShiftService.bankHolidays);
      
      // Convert full day name to abbreviated format for file loading
      String dayOfWeekForFilename;
      if (dayOfWeek == 'Saturday') {
        dayOfWeekForFilename = 'SAT';
      } else if (dayOfWeek == 'Sunday') {
        dayOfWeekForFilename = 'SUN';
      } else {
        dayOfWeekForFilename = 'M-F';
      }
      
      // Find zone number from the shift code
      String zoneNumber = '1'; // Default to zone 1
      final match = RegExp(r'PZ(\d+)/').firstMatch(shiftCode);
      if (match != null) {
        zoneNumber = match.group(1) ?? '1';
      }
      
      // Get the appropriate filename based on day of week and bank holiday status
      final filename = RosterService.getShiftFilename(zoneNumber, dayOfWeekForFilename, widget.event.startDate);
      
      // Load the CSV file
      final file = await rootBundle.loadString('assets/$filename');
      final lines = file.split('\n');
      
      // Find the matching shift
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 15) continue; // Need at least 15 parts to get the work time
        
        final shift = parts[0];
        if (shift == shiftCode) {
          // Found the matching shift, get report/finish locations and times
          final reportLocation = parts.length > 4 ? parts[4].trim() : '';
          final finishLoc = parts.length > 11 ? parts[11].trim() : '';
          final departTimeRaw = parts.length > 3 ? parts[3].trim() : '';
          final finishTimeRaw = parts.length > 10 ? parts[10].trim() : '';
          
          // Get break locations
          final breakStartLoc = parts.length > 6 ? parts[6].trim() : '';
          final breakFinishLoc = parts.length > 9 ? parts[9].trim() : '';
          
          // Get work time
          final work = parts.length > 14 ? parts[14].trim() : '';
          
          // Check if it's a workout (in which case we don't need break locations)
          final startBreak = parts.length > 5 ? parts[5].trim().toLowerCase() : '';
          final isWorkout = startBreak == 'nan' || startBreak == 'workout' || startBreak.isEmpty;
          
          // Format locations for display
          final start = reportLocation.isNotEmpty ? mapLocationName(reportLocation) : '';
          final end = finishLoc.isNotEmpty ? mapLocationName(finishLoc) : '';
          final departFormatted = _formatTimeWithoutSeconds(departTimeRaw);
          final finishFormatted = _formatTimeWithoutSeconds(finishTimeRaw);
          
          // Format break locations only if not a workout
          String? breakStart;
          String? breakEnd;
          if (!isWorkout) {
            breakStart = breakStartLoc.isNotEmpty ? mapLocationName(breakStartLoc) : null;
            breakEnd = breakFinishLoc.isNotEmpty ? mapLocationName(breakFinishLoc) : null;
          }
          
          if (mounted) {
            setState(() {
              startLocation = start;
              finishLocation = end;
              startBreakLocation = breakStart;
              finishBreakLocation = breakEnd;
              workTime = work.isNotEmpty ? work : null;
              _departTimeStr = departFormatted;
              _finishTimeStr = finishFormatted;
            });
          }
          return;
        }
      }
      
      // If no match found
      if (mounted) {
        setState(() {
          startLocation = null;
          finishLocation = null;
          startBreakLocation = null;
          finishBreakLocation = null;
          workTime = null;
        });
      }
    } catch (e) {
      print('Error loading location data: $e');
      if (mounted) {
        setState(() {
          startLocation = null;
          finishLocation = null;
          startBreakLocation = null;
          finishBreakLocation = null;
          workTime = null;
        });
      }
    }
  }
  
  // Helper method to load data for Universal/Euro shifts
  Future<void> _loadUniShiftData(String shiftCode) async {
    try {
      final dayOfWeek = RosterService.getDayOfWeek(widget.event.startDate);
      print('Loading UNI shift data for: $shiftCode on $dayOfWeek');
      
      // Check bank holiday status
      final bankHoliday = ShiftService.getBankHoliday(widget.event.startDate, ShiftService.bankHolidays);
      final isBankHoliday = bankHoliday != null;
      
      // First check UNI_7DAYs.csv for all days
      String? startTime;
      String? endTime;
      String? workTimeStr;
      
      // Try 7DAYs file first
      final file7Days = await rootBundle.loadString('assets/UNI_7DAYs.csv');
      final lines7Days = file7Days.split('\n');
      
      for (final line in lines7Days) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 5) continue;
        
        final shift = parts[0];
        if (shift == shiftCode) {
          // For UNI files, columns are: ShiftCode,StartTime,BreakStart,BreakEnd,FinishTime
          startTime = parts[1].trim();
          endTime = parts[4].trim();
          
          // Format times by removing seconds
          startTime = _formatTimeWithoutSeconds(startTime);
          endTime = _formatTimeWithoutSeconds(endTime);
          
          // Calculate work time
          final start = DateFormat('HH:mm').parse(startTime);
          final end = DateFormat('HH:mm').parse(endTime);
          final totalSpread = end.difference(start);
          
          // If there's a break, subtract it
          if (parts[2] != 'nan' && parts[3] != 'nan') {
            final breakStart = DateFormat('HH:mm').parse(parts[2]);
            final breakEnd = DateFormat('HH:mm').parse(parts[3]);
            final breakDuration = breakEnd.difference(breakStart);
            final workTime = totalSpread - breakDuration;
            
            // Format work time as HH:mm
            final hours = workTime.inHours;
            final minutes = workTime.inMinutes % 60;
            workTimeStr = '${hours}h ${minutes}m';
          } else {
            // No break, use total spread
            final hours = totalSpread.inHours;
            final minutes = totalSpread.inMinutes % 60;
            workTimeStr = '${hours}h ${minutes}m';
          }
          
          print('Found UNI shift in 7DAYs file: $shiftCode, start: $startTime, end: $endTime, work: $workTimeStr');
          break;
        }
      }
      
      // If not found in 7DAYs, check M-F file for weekdays
      if (startTime == null && dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday' && !isBankHoliday) {
        final fileMF = await rootBundle.loadString('assets/UNI_M-F.csv');
        final linesMF = fileMF.split('\n');
        
        for (final line in linesMF) {
          if (line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length < 5) continue;
          
          final shift = parts[0];
          if (shift == shiftCode) {
            // For UNI files, columns are: ShiftCode,StartTime,BreakStart,BreakEnd,FinishTime
            startTime = parts[1].trim();
            endTime = parts[4].trim();
            
            // Format times by removing seconds
            startTime = _formatTimeWithoutSeconds(startTime);
            endTime = _formatTimeWithoutSeconds(endTime);
            
            // Calculate work time
            final start = DateFormat('HH:mm').parse(startTime);
            final end = DateFormat('HH:mm').parse(endTime);
            final totalSpread = end.difference(start);
            
            // If there's a break, subtract it
            if (parts[2] != 'nan' && parts[3] != 'nan') {
              final breakStart = DateFormat('HH:mm').parse(parts[2]);
              final breakEnd = DateFormat('HH:mm').parse(parts[3]);
              final breakDuration = breakEnd.difference(breakStart);
              final workTime = totalSpread - breakDuration;
              
              // Format work time as HH:mm
              final hours = workTime.inHours;
              final minutes = workTime.inMinutes % 60;
              workTimeStr = '${hours}h ${minutes}m';
            } else {
              // No break, use total spread
              final hours = totalSpread.inHours;
              final minutes = totalSpread.inMinutes % 60;
              workTimeStr = '${hours}h ${minutes}m';
            }
            
            print('Found UNI shift in M-F file: $shiftCode, start: $startTime, end: $endTime, work: $workTimeStr');
            break;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          // For UNI shifts, we don't have location data in the CSV, so set to null
          startLocation = null;
          finishLocation = null;
          startBreakLocation = null;
          finishBreakLocation = null;
          workTime = workTimeStr;
          
          // Even though we don't use times in the location fields, we're setting them
          // so that the widget can be updated with the modified event times
          if (startTime != null && endTime != null) {
            // Update the event times directly
            // This is needed because we don't have a separate display for Universal shifts
            widget.event.startTime = TimeOfDay.fromDateTime(
              DateFormat('HH:mm').parse(startTime));
            widget.event.endTime = TimeOfDay.fromDateTime(
              DateFormat('HH:mm').parse(endTime));
          }
        });
      }
    } catch (e) {
      print('Error loading UNI shift data: $e');
    }
  }

  Future<void> _loadAssignedDutyDetails() async {
    _allDutyDetails = [];
    
    if (widget.event.assignedDuties == null || widget.event.assignedDuties!.isEmpty) {
      return;
    }
    
    final dayOfWeek = DateFormat('EEEE').format(widget.event.startDate).toLowerCase();
    final isWeekday = widget.event.startDate.weekday >= 1 && widget.event.startDate.weekday <= 5;
    final bankHoliday = ShiftService.getBankHoliday(widget.event.startDate, ShiftService.bankHolidays);
    
    for (String dutyCode in widget.event.assignedDuties!) {
      // Check if it's a UNI/EURO duty
      bool isUniDuty = false;
      if (dutyCode.startsWith('UNI:')) {
        isUniDuty = true;
        dutyCode = dutyCode.substring(4); // Remove the 'UNI:' prefix
      }
      
      // Check if it's a half duty
      bool isFirstHalf = false;
      bool isSecondHalf = false;
      String codeWithoutHalf = dutyCode;
      
      if (dutyCode.endsWith('A')) {
        isFirstHalf = true;
        codeWithoutHalf = dutyCode.substring(0, dutyCode.length - 1);
      } else if (dutyCode.endsWith('B')) {
        isSecondHalf = true;
        codeWithoutHalf = dutyCode.substring(0, dutyCode.length - 1);
      }
      
      if (isUniDuty) {
        // Handle UNI/EURO duties
        try {
          bool dutyFound = false;
          
          // First check UNI_7DAYs.csv which applies to all days
          final file7Days = await rootBundle.loadString('assets/UNI_7DAYs.csv');
          final lines7Days = file7Days.split('\n');
          
          for (var line in lines7Days) {
            if (line.trim().isEmpty) continue;
            
            final parts = line.split(',');
            if (parts.isNotEmpty && parts[0].trim() == codeWithoutHalf) {
              String startTimeStr = parts[1].trim();
              String breakStartStr = parts[2].trim();
              String breakEndStr = parts[3].trim();
              String endTimeStr = parts[4].trim();
              
              // Parse times for start and end
              final startTime = _parseTimeFromString(startTimeStr);
              final endTime = _parseTimeFromString(endTimeStr);
              
              // For half duties, adjust the times
              if (isFirstHalf) {
                // For first half, use original start time but use break start for end time
                _allDutyDetails.add({
                  'dutyCode': dutyCode,
                  'startTime': startTimeStr,
                  'endTime': breakStartStr.toLowerCase() != 'nan' ? breakStartStr : DateFormat('HH:mm:ss').format(startTime.add(Duration(minutes: (endTime.difference(startTime).inMinutes ~/ 2)))),
                  'location': 'UNI/EURO',
                  'isHalfDuty': 'true',
                  'isFirstHalf': 'true',
                });
                dutyFound = true;
                break;
              } else if (isSecondHalf) {
                // For second half, use break end for start time and original end time
                _allDutyDetails.add({
                  'dutyCode': dutyCode,
                  'startTime': breakEndStr.toLowerCase() != 'nan' ? breakEndStr : DateFormat('HH:mm:ss').format(startTime.add(Duration(minutes: (endTime.difference(startTime).inMinutes ~/ 2)))),
                  'endTime': endTimeStr,
                  'location': 'UNI/EURO',
                  'isHalfDuty': 'true',
                  'isSecondHalf': 'true',
                });
                dutyFound = true;
                break;
              } else {
                // Full duty - use original times
                final Map<String, String?> dutyDetail = {
                  'dutyCode': dutyCode,
                  'startTime': startTimeStr,
                  'endTime': endTimeStr,
                  'location': 'UNI/EURO',
                  'isHalfDuty': 'false',
                };
                
                // Add break times only if they're not 'nan'
                if (breakStartStr.toLowerCase() != 'nan' && 
                    breakEndStr.toLowerCase() != 'nan') {
                  dutyDetail['breakStart'] = breakStartStr;
                  dutyDetail['breakEnd'] = breakEndStr;
                }
                
                _allDutyDetails.add(dutyDetail);
                dutyFound = true;
                break;
              }
            }
          }
          
          // If duty wasn't found and it's a weekday, check UNI_M-F.csv
          if (!dutyFound && isWeekday && bankHoliday == null) {
            final fileMF = await rootBundle.loadString('assets/UNI_M-F.csv');
            final linesMF = fileMF.split('\n');
            
            for (var line in linesMF) {
              if (line.trim().isEmpty) continue;
              
              final parts = line.split(',');
              if (parts.isNotEmpty && parts[0].trim() == codeWithoutHalf) {
                String startTimeStr = parts[1].trim();
                String breakStartStr = parts[2].trim();
                String breakEndStr = parts[3].trim();
                String endTimeStr = parts[4].trim();
                
                // Parse times for start and end
                final startTime = _parseTimeFromString(startTimeStr);
                final endTime = _parseTimeFromString(endTimeStr);
                
                // For half duties, adjust the times
                if (isFirstHalf) {
                  // For first half, use original start time but use break start for end time
                  _allDutyDetails.add({
                    'dutyCode': dutyCode,
                    'startTime': startTimeStr,
                    'endTime': breakStartStr.toLowerCase() != 'nan' ? breakStartStr : DateFormat('HH:mm:ss').format(startTime.add(Duration(minutes: (endTime.difference(startTime).inMinutes ~/ 2)))),
                    'location': 'UNI/EURO',
                    'isHalfDuty': 'true',
                    'isFirstHalf': 'true',
                  });
                  dutyFound = true;
                  break;
                } else if (isSecondHalf) {
                  // For second half, use break end for start time and original end time
                  _allDutyDetails.add({
                    'dutyCode': dutyCode,
                    'startTime': breakEndStr.toLowerCase() != 'nan' ? breakEndStr : DateFormat('HH:mm:ss').format(startTime.add(Duration(minutes: (endTime.difference(startTime).inMinutes ~/ 2)))),
                    'endTime': endTimeStr,
                    'location': 'UNI/EURO',
                    'isHalfDuty': 'true',
                    'isSecondHalf': 'true',
                  });
                  dutyFound = true;
                  break;
                } else {
                  // Full duty - use original times
                  final Map<String, String?> dutyDetail = {
                    'dutyCode': dutyCode,
                    'startTime': startTimeStr,
                    'endTime': endTimeStr,
                    'location': 'UNI/EURO',
                    'isHalfDuty': 'false',
                  };
                  
                  // Add break times only if they're not 'nan'
                  if (breakStartStr.toLowerCase() != 'nan' && 
                      breakEndStr.toLowerCase() != 'nan') {
                    dutyDetail['breakStart'] = breakStartStr;
                    dutyDetail['breakEnd'] = breakEndStr;
                  }
                  
                  _allDutyDetails.add(dutyDetail);
                  dutyFound = true;
                  break;
                }
              }
            }
          }
          
          // If the duty wasn't found in either file
          if (!dutyFound) {
            _allDutyDetails.add({
              'dutyCode': dutyCode,
              'startTime': '00:00:00',
              'endTime': '00:00:00',
              'location': 'UNI/EURO - Not found',
              'isHalfDuty': (isFirstHalf || isSecondHalf) ? 'true' : 'false',
              'isFirstHalf': isFirstHalf ? 'true' : 'false',
              'isSecondHalf': isSecondHalf ? 'true' : 'false',
            });
          }
        } catch (e) {
          print('Error loading UNI duty details: $e');
          _allDutyDetails.add({
            'dutyCode': dutyCode,
            'startTime': '00:00:00',
            'endTime': '00:00:00',
            'location': 'UNI/EURO - Error',
            'isHalfDuty': (isFirstHalf || isSecondHalf) ? 'true' : 'false',
          });
        }
      } else {
        // Handle regular zone duties
        try {
          // Fix zone duty parsing for duties that include PZ prefix
          String codeWithoutPrefix = codeWithoutHalf;
          String zone = '1'; // Default to zone 1
          
          // Check for PZx/ format first
          final pzMatch = RegExp(r'^PZ(\d+)/').firstMatch(codeWithoutHalf);
          if (pzMatch != null) {
            zone = pzMatch.group(1) ?? '1';
            // Extract the part after the PZx/ prefix
            codeWithoutPrefix = codeWithoutHalf.substring(pzMatch.end);
          } else {
            // Otherwise, try to determine zone from the first digit of the numeric part
            final zoneMatch = RegExp(r'^(\d+)').firstMatch(codeWithoutHalf);
            final firstDigit = zoneMatch?.group(1)?.substring(0, 1);
            
            if (firstDigit != null) {
              // Determine the zone based on the first digit
              zone = firstDigit == '1' ? '1' : firstDigit == '3' ? '3' : firstDigit == '4' ? '4' : '1';
            }
          }
          
          // Determine the filename based on the day of the week and zone
          final filename = bankHoliday != null ? 'SUN_DUTIES_PZ$zone.csv' :
                         dayOfWeek == 'saturday' ? 'SAT_DUTIES_PZ$zone.csv' :
                         dayOfWeek == 'sunday' ? 'SUN_DUTIES_PZ$zone.csv' :
                         'M-F_DUTIES_PZ$zone.csv';
          
          print('Loading zone duty: $dutyCode, zone: $zone, filename: $filename, searching for duty: $codeWithoutHalf');
                         
          // Load the duty file
          final file = await rootBundle.loadString('assets/$filename');
          final lines = file.split('\n');
          
          bool dutyFound = false;
          
          // Skip the header line
          for (var i = 1; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;
            
            final parts = line.split(',');
            if (parts.length < 8) continue; // Need at least columns for code, start, end
            
            // Try to match both with and without the PZ prefix
            final dutyInFile = parts[0].trim();
            if (dutyInFile == codeWithoutPrefix || dutyInFile == codeWithoutHalf) {
              // Found the duty
              final dutyStartTime = parts[2].trim();
              final dutyEndTime = parts[10].trim();
              final startLocation = parts[4].trim();
              final endLocation = parts[11].trim();
              
              // For half duties, calculate the appropriate time
              if (isFirstHalf) {
                // For first half, use original start time and break start time if available
                final breakStartCol = 5; // Column index for break start time in CSV files
                final breakStartTimeStr = parts.length > breakStartCol ? parts[breakStartCol].trim() : "";
                
                if (breakStartTimeStr.isNotEmpty && 
                    breakStartTimeStr.toLowerCase() != "nan" && 
                    breakStartTimeStr.toLowerCase() != "workout") {
                  // Use break start time for end time of first half
                  _allDutyDetails.add({
                    'dutyCode': dutyCode,
                    'startTime': dutyStartTime,
                    'endTime': breakStartTimeStr,
                    'location': startLocation,
                    'isHalfDuty': 'true',
                    'isFirstHalf': 'true',
                  });
                } else {
                  // Fall back to calculating midpoint if no break time
                  final startTime = _parseTimeFromString(dutyStartTime);
                  final endTime = _parseTimeFromString(dutyEndTime);
                  final duration = endTime.difference(startTime);
                  final halfwayPoint = startTime.add(Duration(minutes: duration.inMinutes ~/ 2));
                  
                  _allDutyDetails.add({
                    'dutyCode': dutyCode,
                    'startTime': dutyStartTime,
                    'endTime': DateFormat('HH:mm:ss').format(halfwayPoint),
                    'location': startLocation,
                    'isHalfDuty': 'true',
                    'isFirstHalf': 'true',
                  });
                }
              } else if (isSecondHalf) {
                // For second half, use break end time and finish time if available
                final breakEndCol = 8; // Column index for break end time in CSV files
                final breakEndTimeStr = parts.length > breakEndCol ? parts[breakEndCol].trim() : "";
                
                if (breakEndTimeStr.isNotEmpty && 
                    breakEndTimeStr.toLowerCase() != "nan" && 
                    breakEndTimeStr.toLowerCase() != "workout") {
                  // Use break end time for start time of second half
                  _allDutyDetails.add({
                    'dutyCode': dutyCode,
                    'startTime': breakEndTimeStr,
                    'endTime': dutyEndTime,
                    'location': endLocation,
                    'isHalfDuty': 'true',
                    'isSecondHalf': 'true',
                  });
                } else {
                  // Fall back to calculating midpoint if no break time
                  final startTime = _parseTimeFromString(dutyStartTime);
                  final endTime = _parseTimeFromString(dutyEndTime);
                  final duration = endTime.difference(startTime);
                  final halfwayPoint = startTime.add(Duration(minutes: duration.inMinutes ~/ 2));
                  
                  _allDutyDetails.add({
                    'dutyCode': dutyCode,
                    'startTime': DateFormat('HH:mm:ss').format(halfwayPoint),
                    'endTime': dutyEndTime,
                    'location': endLocation,
                    'isHalfDuty': 'true',
                    'isSecondHalf': 'true',
                  });
                }
              } else {
                // Full duty
                _allDutyDetails.add({
                  'dutyCode': dutyCode,
                  'startTime': dutyStartTime,
                  'endTime': dutyEndTime,
                  'startLocation': startLocation,
                  'endLocation': endLocation,
                  'location': '$startLocation - $endLocation',
                  'isHalfDuty': 'false',
                });
              }
              
              dutyFound = true;
              break;
            }
          }
          
          // If duty wasn't found
          if (!dutyFound) {
            _allDutyDetails.add({
              'dutyCode': dutyCode,
              'startTime': '00:00:00',
              'endTime': '00:00:00',
              'location': 'Zone $zone - Not found',
              'isHalfDuty': (isFirstHalf || isSecondHalf) ? 'true' : 'false',
              'isFirstHalf': isFirstHalf ? 'true' : 'false',
              'isSecondHalf': isSecondHalf ? 'true' : 'false',
            });
          }
        } catch (e) {
          print('Error loading zone duty details: $e');
          _allDutyDetails.add({
            'dutyCode': dutyCode,
            'startTime': '00:00:00',
            'endTime': '00:00:00',
            'location': 'Error loading duty',
            'isHalfDuty': (isFirstHalf || isSecondHalf) ? 'true' : 'false',
          });
        }
      }
    }
  }
  
  // Helper method to parse time strings
  DateTime _parseTimeFromString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final second = parts.length > 2 ? int.parse(parts[2]) : 0;
        
        return DateTime(2000, 1, 1, hour, minute, second);
      }
    } catch (e) {
      print('Error parsing time string: $e');
    }
    
    return DateTime(2000, 1, 1, 0, 0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final shiftInfo = widget.shiftInfoMap[widget.shiftType];
    
    // Check if this is a work shift
    final isWorkShift = widget.event.isWorkShift;
    
    // Check if it's a Spare shift
    final isSpareShift = isWorkShift && widget.event.title.startsWith('SP');
    // ADD: Check if it's a BusCheck shift
    final bool isBusCheckShift = widget.event.title.startsWith('BusCheck');
    
    // Special styling for holiday events
    if (widget.event.isHoliday) {
      MaterialColor holidayColor;
      IconData holidayIcon;
      
      switch (widget.event.holidayType) {
        case 'winter':
          holidayColor = Colors.blue;
          holidayIcon = Icons.ac_unit;
          break;
        case 'summer':
          holidayColor = Colors.orange;
          holidayIcon = Icons.wb_sunny;
          break;
        case 'other':
          holidayColor = Colors.green;
          holidayIcon = Icons.event;
          break;
        default:
          holidayColor = Colors.grey;
          holidayIcon = Icons.event;
      }

      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        color: holidayColor[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                holidayIcon,
                color: holidayColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.event.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: holidayColor[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Determine card color based on various factors
    Color cardColor = Colors.white;
    if (isWorkShift) {
      if (widget.isRestDay) {
        cardColor = widget.shiftInfoMap['R']?.color.withOpacity(0.3) ?? Colors.grey.shade100;
      } else {
        cardColor = shiftInfo?.color.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2);
      }
    }
    
    // In dark mode, adjust card colors
    if (Theme.of(context).brightness == Brightness.dark) {
      if (isWorkShift) {
        if (widget.isRestDay) {
          cardColor = widget.shiftInfoMap['R']?.color.withOpacity(0.3) ?? Colors.blueGrey.shade700;
        } else {
          cardColor = shiftInfo?.color.withOpacity(0.2) ?? Colors.blueGrey.withOpacity(0.2);
        }
      } else {
        cardColor = Colors.grey.shade800;
      }
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: widget.isBankHoliday
            ? const BorderSide(color: AppTheme.errorColor, width: 1.5)
            : BorderSide.none,
      ),
      color: cardColor,
      child: InkWell(
        onTap: () {
          // Use a specialized dialog for spare shifts
          if (isSpareShift) {
            _showSpareShiftDialog(context);
            // FIX: The previous fix for onTap was lost in the reset.
            // Call onEdit for non-spare shifts.
          } else { 
            widget.onEdit(widget.event);
          }
        },
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      // Format title: Add space for BusCheck, otherwise use original title
                      _formatDisplayTitle(widget.event.title),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.event.notes != null && widget.event.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.notes,
                            size: 18,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: (widget.event.notes != null && widget.event.notes!.isNotEmpty) ? 8.0 : 0,
                        ),
                        child: Row(
                          children: [
                            // Rest day badge
                            if (widget.isRestDay && widget.event.isWorkShift)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: widget.shiftInfoMap['R']?.color ?? Colors.blue,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: const Text(
                                  'Rest Day',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            // Bank holiday badge
                            if (widget.isBankHoliday && widget.event.isWorkShift)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: const Text(
                                  'Bank Holiday',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              
              // NEW: Report - Sign Off line (only for PZ shifts)
              if (widget.event.title.startsWith('PZ'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0), // Keep space below
                  // Add Row for Icon
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule, // Use schedule icon
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      // Use RichText for styling consistency
                      Expanded( // Ensure RichText expands
                        child: RichText(
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                          text: TextSpan(
                            // Default style (slightly de-emphasized)
                            style: TextStyle( // Removed const and hardcoded black color
                              color: Theme.of(context).textTheme.bodyMedium?.color, // Use theme color
                              fontSize: 14,
                              // fontWeight: FontWeight.w600, // REMOVE overall bold
                            ),
                            children: <TextSpan>[
                              const TextSpan(text: 'Report: '),
                              TextSpan(
                                text: widget.event.formattedStartTime,
                                style: TextStyle( // Removed const and hardcoded black color
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9), // Use theme color, slightly less emphasis
                                ),
                              ),
                              const TextSpan(text: ' - Sign Off: '),
                              TextSpan(
                                text: widget.event.formattedEndTime,
                                style: TextStyle( // Removed const and hardcoded black color
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9), // Use theme color, slightly less emphasis
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // MODIFIED: Depart - Finish time with locations (PZ) or Start-End time (others)
              Row(
                children: [
                  Icon(
                    Icons.route,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                      text: TextSpan(
                        // Default style for the row
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: 14,
                        ),
                        children: widget.event.title.startsWith('PZ')
                          // PZ Shift: Location + Depart - Finish + Location
                          ? <TextSpan>[
                              if (startLocation != null && startLocation!.isNotEmpty) ...[
                                TextSpan(
                                  text: '$startLocation ',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                              TextSpan(
                                text: _departTimeStr ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const TextSpan(text: ' - '),
                              TextSpan(
                                text: _finishTimeStr ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (finishLocation != null && finishLocation!.isNotEmpty) ...[
                                TextSpan(
                                  text: ' $finishLocation',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ]
                          // Non-PZ Shift: Start - End Time (Original Logic)
                          : <TextSpan>[
                              TextSpan(
                                text: widget.event.formattedStartTime,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const TextSpan(text: ' - '),
                              TextSpan(
                                text: widget.event.formattedEndTime,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              // MODIFIED: Break times row (if available AND NOT BusCheck)
              if (breakTime != null && !isBusCheckShift) ...[
                Row(
                  children: [
                    Icon(
                      breakTime!.toLowerCase().contains('workout') ? Icons.directions_run : Icons.coffee,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // Only show break locations for PZ shifts that are not workouts
                        (!breakTime!.toLowerCase().contains('workout') && widget.event.title.contains('PZ')) 
                            ? '${startBreakLocation != null ? "$startBreakLocation " : ""}${breakTime!}${finishBreakLocation != null ? " $finishBreakLocation" : ""}'
                            : breakTime!.toLowerCase().contains('workout') ? 'Workout' : breakTime!,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
              ],
              // Show assigned duty details if available
              if (widget.event.assignedDuties != null && widget.event.assignedDuties!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: _buildAssignedDuties(),
                ),
                const SizedBox(height: 6.0),
              ],
              // Date row
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(widget.event.startDate),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Add a Spacer to push work time to the right
                  const Spacer(), 
                  if (workTime != null) ...[
                    Text(
                      'Work: $workTime',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              // --- Debug Print --- 
              // print('Event: ${widget.event.title}, isBusCheck: $isBusCheckShift, bus1: ${widget.event.firstHalfBus}, bus2: ${widget.event.secondHalfBus}');
              // --- End Debug Print --- 

              // MODIFIED: Bus assignment row (Only show if NOT BusCheck AND bus data exists)
              if (!isBusCheckShift && (widget.event.firstHalfBus != null || widget.event.secondHalfBus != null)) ...[
                Row(
                  children: [
                    Icon(
                      Icons.directions_bus,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FutureBuilder<String?>(
                        future: ShiftService.getBreakTime(widget.event),
                        builder: (context, snapshot) {
                          final isWorkout = snapshot.data?.toLowerCase().contains('workout') ?? false;
                          return Text(
                            isWorkout
                                ? 'Assigned Bus: ${widget.event.firstHalfBus}'
                                : [
                                    if (widget.event.firstHalfBus != null)
                                      'First Half: ${widget.event.firstHalfBus}',
                                    if (widget.event.secondHalfBus != null)
                                      'Second Half: ${widget.event.secondHalfBus}',
                                  ].join(' | '),
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDutySelectionDialog(BuildContext context, [String? halfIndicator, String? preSelectedZone]) async {
    String selectedZone = preSelectedZone ?? 'Zone 1';
    String selectedDuty = '';
    List<String> duties = [];
    bool isLoading = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Function to load duties for selected zone
          void loadDuties() async {
            setState(() {
              isLoading = true;
            });

            try {
              final dayOfWeek = RosterService.getDayOfWeek(widget.event.startDate);
              final bankHoliday = ShiftService.getBankHoliday(widget.event.startDate, ShiftService.bankHolidays);
              final zoneNumber = selectedZone.replaceAll('Zone ', '');
              
              duties = [];
              final seenDuties = <String>{};

              if (selectedZone == 'Uni/Euro') {
                // Handle UNI/Euro duties
                // Always load from UNI_7DAYs.csv first
                try {
                  final file7Days = await rootBundle.loadString('assets/UNI_7DAYs.csv');
                  final lines7Days = file7Days.split('\n');
                  
                  // Don't skip any lines for UNI files
                  for (final line in lines7Days) {
                    if (line.trim().isEmpty) continue;
                    final parts = line.split(',');
                    if (parts.length < 5) continue;
                    
                    // For half duties (A or B), only include duties that have break times
                    // For full duties, include all duties
                    final dutyCode = parts[0].trim();
                    final breakStartStr = parts[2].trim().toLowerCase();
                    final breakEndStr = parts[3].trim().toLowerCase();
                    
                    // Skip duties without break times for half duties
                    if (halfIndicator != null && (breakStartStr == 'nan' || breakEndStr == 'nan')) {
                      continue; // Skip duties without breaks for half duties
                    }
                    
                    if (dutyCode.isNotEmpty && !seenDuties.contains(dutyCode)) {
                      seenDuties.add(dutyCode);
                      duties.add(dutyCode);
                    }
                  }
                } catch (e) {
                  print('Error loading UNI_7DAYs.csv: $e');
                }
                
                // On weekdays, also load from UNI_M-F.csv
                if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday' && bankHoliday == null) {
                  try {
                    final fileMF = await rootBundle.loadString('assets/UNI_M-F.csv');
                    final linesMF = fileMF.split('\n');
                    
                    // Skip header line
                    for (var i = 1; i < linesMF.length; i++) {
                      final line = linesMF[i];
                      if (line.trim().isEmpty) continue;
                      final parts = line.split(',');
                      if (parts.length < 5) continue;
                      
                      // For half duties (A or B), only include duties that have break times
                      // For full duties, include all duties
                      final dutyCode = parts[0].trim();
                      final breakStartStr = parts[2].trim().toLowerCase();
                      final breakEndStr = parts[3].trim().toLowerCase();
                      
                      // Skip duties without break times for half duties
                      if (halfIndicator != null && (breakStartStr == 'nan' || breakEndStr == 'nan')) {
                        continue; // Skip duties without breaks for half duties
                      }
                      
                      if (dutyCode.isNotEmpty && !seenDuties.contains(dutyCode)) {
                        seenDuties.add(dutyCode);
                        duties.add(dutyCode);
                      }
                    }
                  } catch (e) {
                    print('Error loading UNI_M-F.csv: $e');
                  }
                }
              } else {
                // Handle regular zone duties
                final filename = bankHoliday != null ? 'SUN_DUTIES_PZ$zoneNumber.csv' :
                               dayOfWeek == 'Saturday' ? 'SAT_DUTIES_PZ$zoneNumber.csv' :
                               dayOfWeek == 'Sunday' ? 'SUN_DUTIES_PZ$zoneNumber.csv' :
                               'M-F_DUTIES_PZ$zoneNumber.csv';

                final file = await rootBundle.loadString('assets/$filename');
                final lines = file.split('\n');

                // Skip header line and process each duty
                for (var i = 1; i < lines.length; i++) {
                  final line = lines[i].trim();
                  if (line.isEmpty) continue;

                  final parts = line.split(',');
                  if (parts.length < 8) continue; // Need at least 8 parts for break times

                  // Check if this is a workout duty (marked as "WORKOUT" or "nan" in startbreak column)
                  final startBreak = parts[5].trim();
                  if (startBreak.toUpperCase() == 'WORKOUT' || 
                      startBreak.toLowerCase() == 'workout' ||
                      startBreak.toLowerCase() == 'nan') {
                    continue; // Skip workout duties
                  }

                  final dutyCode = parts[0].trim();
                  if (dutyCode.isNotEmpty && !seenDuties.contains(dutyCode)) {
                    seenDuties.add(dutyCode);
                    duties.add(dutyCode);
                  }
                }
              }

              selectedDuty = duties.isNotEmpty ? duties[0] : '';

              setState(() {
                isLoading = false;
              });
            } catch (e) {
              print('Error loading duties: $e');
              duties = [];
              selectedDuty = '';
              setState(() {
                isLoading = false;
              });
            }
          }

          // Load duties when zone changes or dialog opens
          if (isLoading) {
            loadDuties();
          }

          return AlertDialog(
            title: Text(halfIndicator == 'A' 
              ? 'Add First Half Duty to ${widget.event.title}'
              : halfIndicator == 'B'
                ? 'Add Second Half Duty to ${widget.event.title}'
                : 'Add Full Duty to ${widget.event.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (halfIndicator != null) ...[
                  const Text(
                    'Workouts excluded, found in full duty',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text('Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedZone,
                  isExpanded: true,
                  items: ['Zone 1', 'Zone 3', 'Zone 4', 'Uni/Euro'].map((zone) {
                    return DropdownMenuItem(
                      value: zone,
                      child: Text(zone),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != selectedZone) {
                      setState(() {
                        selectedZone = value;
                        selectedDuty = '';
                        loadDuties();
                      });
                    }
                  },
                ),
                
                
                const SizedBox(height: 16),
                const Text('Duty:', style: TextStyle(fontWeight: FontWeight.bold)),
                isLoading
                  ? const SizedBox(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : duties.isEmpty
                    ? const Text('No duties available for selected zone and date')
                    : DropdownButton<String>(
                        value: selectedDuty,
                        isExpanded: true,
                        items: duties.map((duty) {
                          // For display, append 'A' or 'B' to the duty code for half duties
                          final displayDuty = halfIndicator != null 
                              ? '$duty$halfIndicator'
                              : duty;
                          return DropdownMenuItem(
                            value: duty, // Keep the original value without suffix
                            child: Text(displayDuty),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedDuty = value;
                            });
                          }
                        },
                      ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading || duties.isEmpty || selectedDuty.isEmpty
                  ? null
                  : () async {
                      // Update the event with the assigned duty
                      final oldEvent = Event(
                        id: widget.event.id,
                        title: widget.event.title,
                        startDate: widget.event.startDate,
                        startTime: widget.event.startTime,
                        endDate: widget.event.endDate,
                        endTime: widget.event.endTime,
                        workTime: widget.event.workTime,
                        breakStartTime: widget.event.breakStartTime,
                        breakEndTime: widget.event.breakEndTime,
                        assignedDuties: widget.event.assignedDuties,
                      );
                      
                      // Add the half indicator if this is a half duty
                      String newDuty;
                      if (selectedZone == 'Uni/Euro') {
                        // For UNI/EURO duties, add the UNI: prefix
                        newDuty = halfIndicator != null 
                            ? 'UNI:$selectedDuty$halfIndicator'
                            : 'UNI:$selectedDuty';
                      } else {
                        // For regular zone duties
                        newDuty = halfIndicator != null 
                            ? '$selectedDuty$halfIndicator'
                            : selectedDuty;
                      }
                      
                      // Initialize or update the assignedDuties list
                      if (widget.event.assignedDuties == null) {
                        widget.event.assignedDuties = [newDuty];
                      } else if (widget.event.assignedDuties!.length < 2) {
                        widget.event.assignedDuties!.add(newDuty);
                      }
                      
                      // Save the updated event
                      await EventService.updateEvent(oldEvent, widget.event);
                      
                      // Close the dialog
                      Navigator.of(dialogContext).pop();
                      
                      // Load the duty details immediately
                      await _loadAssignedDutyDetails();
                      
                      // Refresh the UI
                      if (mounted) {
                        setState(() {});
                        // Notify parent to rebuild without showing edit dialog
                        widget.onEdit(Event(
                          id: 'refresh_trigger',
                          title: '',
                          startDate: widget.event.startDate,
                          startTime: widget.event.startTime,
                          endDate: widget.event.endDate,
                          endTime: widget.event.endTime,
                        ));
                      }
                    },
                child: Text(halfIndicator != null ? 'Add Half Duty' : 'Add Duty'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSpareShiftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spare Shift'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show duty addition buttons if we have less than 2 duties
            if (widget.event.assignedDuties == null || widget.event.assignedDuties!.length < 2) ...[
              // Label text for adding a duty
              const Text(
                'Add another duty to your Spare Event Card:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // "Full Duty" button
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDutySelectionDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
                child: const Text('Full Duty'),
              ),
              const SizedBox(height: 8),

              // "First Half" button
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDutySelectionDialog(context, 'A');  // 'A' indicates first half
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
                child: const Text('First Half'),
              ),
              const SizedBox(height: 8),

              // "Second Half" button
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDutySelectionDialog(context, 'B');  // 'B' indicates second half
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
                child: const Text('Second Half'),
              ),
              const SizedBox(height: 16),
            ],
            
            // Show current duties if any
            if (widget.event.assignedDuties != null && widget.event.assignedDuties!.isNotEmpty) ...[
              const Text(
                'Current duties:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Create a sorted list of duties
              ...(() {
                final sortedDuties = widget.event.assignedDuties!.map((dutyCode) {
                  final dutyDetails = _allDutyDetails.firstWhere(
                    (d) => d['dutyCode'] == dutyCode,
                    orElse: () => {'startTime': '00:00:00', 'dutyCode': dutyCode},
                  );
                  return dutyDetails;
                }).toList()
                  ..sort((a, b) => (a['startTime'] ?? '').compareTo(b['startTime'] ?? ''));

                return sortedDuties.map((duty) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Assigned: ${duty['dutyCode']} | ${_formatTimeString(duty['startTime'])} to ${_formatTimeString(duty['endTime'])}',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          // Create a copy of the old event
                          final oldEvent = Event(
                            id: widget.event.id,
                            title: widget.event.title,
                            startDate: widget.event.startDate,
                            startTime: widget.event.startTime,
                            endDate: widget.event.endDate,
                            endTime: widget.event.endTime,
                            workTime: widget.event.workTime,
                            breakStartTime: widget.event.breakStartTime,
                            breakEndTime: widget.event.breakEndTime,
                            assignedDuties: widget.event.assignedDuties,
                          );
                          
                          // Remove the specific duty
                          widget.event.assignedDuties!.remove(duty['dutyCode']);
                          
                          // If no duties left, set to null
                          if (widget.event.assignedDuties!.isEmpty) {
                            widget.event.assignedDuties = null;
                          }
                          
                          // Save the updated event
                          await EventService.updateEvent(oldEvent, widget.event);
                          
                          // Close the dialog
                          Navigator.of(context).pop();
                          
                          // Clear duty details if no duties left
                          if (widget.event.assignedDuties == null) {
                            setState(() {
                              _assignedDutyStartTime = null;
                              _assignedDutyEndTime = null;
                              _assignedDutyStartLocation = null;
                              _assignedDutyEndLocation = null;
                            });
                          } else {
                            // Reload duty details for the remaining duty
                            await _loadAssignedDutyDetails();
                          }
                          
                          // Refresh the UI by notifying the parent widget
                          if (mounted) {
                            setState(() {}); // Force a rebuild of this widget
                            // Notify parent to rebuild without showing edit dialog
                            widget.onEdit(Event(
                              id: 'refresh_trigger',
                              title: '',
                              startDate: widget.event.startDate,
                              startTime: widget.event.startTime,
                              endDate: widget.event.endDate,
                              endTime: widget.event.endTime,
                            ));
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                )).toList();
              })(),
              const SizedBox(height: 16),
            ],
            
            // Show delete button at the bottom
            OutlinedButton(
              onPressed: () async {
                // Show confirmation dialog
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Event'),
                    content: const Text('Are you sure you want to delete this spare event?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true) {
                  // Delete the event
                  await EventService.deleteEvent(widget.event);
                  
                  // Close the dialog
                  Navigator.of(context).pop();
                  
                  // Notify parent to rebuild
                  widget.onEdit(widget.event);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete Event'),
            ),
          ],
        ),
        // Add actions for the dialog
        actions: [
          TextButton(
            onPressed: () {
              // Close the current dialog
              Navigator.of(context).pop();
              // Call the onShowNotes callback from the parent
              widget.onShowNotes(widget.event);
            },
            child: const Text('Notes'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Simple close action
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimeWithoutSeconds(String timeStr) {
    if (timeStr.isEmpty || timeStr.toLowerCase() == 'nan') return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return timeStr; // Return original if format is unexpected
  }

  Widget _buildAssignedDuties() {
    if (widget.event.assignedDuties == null || widget.event.assignedDuties!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Use map and separate with SizedBox for consistent spacing
    final dutyWidgets = _allDutyDetails.map((duty) {
      // Check if this is a UNI duty
      final dutyCode = duty['dutyCode'] ?? '';
      final isUniDuty = dutyCode.startsWith('UNI:');
      
      // Format the display duty code - remove UNI: prefix if present
      final displayDutyCode = isUniDuty 
          ? dutyCode.substring(4) // Remove 'UNI:' prefix
          : dutyCode;
      
      // Calculate work duration for this duty
      String workDuration = '';
      if (duty['startTime'] != null && duty['endTime'] != null) {
        final startParts = duty['startTime']!.split(':');
        final endParts = duty['endTime']!.split(':');
        
        if (startParts.length >= 2 && endParts.length >= 2) {
          try { // Add try-catch for parsing robustness
            final start = DateTime(2024, 1, 1, int.parse(startParts[0]), int.parse(startParts[1]));
            final end = DateTime(2024, 1, 1, int.parse(endParts[0]), int.parse(endParts[1]));
            
            var duration = end.difference(start);
            // Handle potential overnight shifts
            if (duration.isNegative) {
              duration += const Duration(days: 1);
            }

            final hours = duration.inHours;
            final minutes = duration.inMinutes % 60;
            
            workDuration = '${hours}h ${minutes}m';
          } catch (e) {
            print("Error calculating duty duration: $e");
            workDuration = 'Err'; // Indicate error
          }
        }
      }

      final isHalfDuty = duty['isHalfDuty'] == 'true';
      final isFirstHalf = duty['isFirstHalf'] == 'true';
      final isSecondHalf = duty['isSecondHalf'] == 'true';

      final halfDutyText = isHalfDuty 
          ? (isFirstHalf ? ' (First Half)' : ' (Second Half)')
          : '';
      
      // Determine duty type for display
      final dutyTypeText = isUniDuty ? 'UNI/EURO' : 'Zone';
          
      // Determine if we need to show break times
      final hasBreakTimes = duty['breakStart'] != null && duty['breakEnd'] != null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.work,
                size: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isUniDuty
                          ? 'Assigned: $displayDutyCode | '
                            '${_formatTimeString(duty['startTime'])} to '
                            '${_formatTimeString(duty['endTime'])}$halfDutyText'
                          : 'Assigned: $displayDutyCode | '
                            '${_formatTimeString(duty['startTime'])} to '
                            '${_formatTimeString(duty['endTime'])}$halfDutyText',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis, // Prevent overflow
                        maxLines: 2, // Allow wrapping if needed
                      ),
                    ),
                    if (workDuration.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0), // Add padding before work duration
                        child: Text(
                          'Work: $workDuration',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Show break times for UNI duties if available
          if (hasBreakTimes)
            Padding(
              padding: const EdgeInsets.only(left: 24.0, top: 4.0),
              child: Text(
                'Break: ${_formatTimeString(duty['breakStart'])} - ${_formatTimeString(duty['breakEnd'])}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      );
    }).toList();

    // Insert SizedBox between duty widgets
    List<Widget> spacedDutyWidgets = [];
    for (int i = 0; i < dutyWidgets.length; i++) {
      spacedDutyWidgets.add(dutyWidgets[i]);
      if (i < dutyWidgets.length - 1) {
        // Add spacing between duty rows
        spacedDutyWidgets.add(const SizedBox(height: 6.0)); 
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spacedDutyWidgets,
    );
  }

  Future<void> _showBusAssignmentDialog(BuildContext context, [String? halfIndicator]) async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(halfIndicator == 'A' 
          ? 'Add First Half Bus'
          : halfIndicator == 'B'
            ? 'Add Second Half Bus'
            : 'Add Bus'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter bus number (e.g. PA155)',
            labelText: 'Bus Number',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Normalize the bus number
              String busNumber = controller.text.trim().toUpperCase();
              // Remove any spaces
              busNumber = busNumber.replaceAll(' ', '');
              
              if (busNumber.isNotEmpty) {
                // Create a copy of the old event
                final oldEvent = Event(
                  id: widget.event.id,
                  title: widget.event.title,
                  startDate: widget.event.startDate,
                  startTime: widget.event.startTime,
                  endDate: widget.event.endDate,
                  endTime: widget.event.endTime,
                  workTime: widget.event.workTime,
                  breakStartTime: widget.event.breakStartTime,
                  breakEndTime: widget.event.breakEndTime,
                  assignedDuties: widget.event.assignedDuties,
                  firstHalfBus: widget.event.firstHalfBus,
                  secondHalfBus: widget.event.secondHalfBus,
                );
                
                // Update the event with the new bus number based on the half indicator
                if (halfIndicator == 'A') {
                  widget.event.firstHalfBus = busNumber;
                } else if (halfIndicator == 'B') {
                  widget.event.secondHalfBus = busNumber;
                } else {
                  // For workout shifts or when no half indicator is provided
                  widget.event.firstHalfBus = busNumber;
                }
                
                // Save the updated event
                await EventService.updateEvent(oldEvent, widget.event);
                
                // Close the dialog
                Navigator.of(context).pop();
                
                // Refresh the UI
                if (mounted) {
                  setState(() {});
                  // Notify parent to rebuild without showing edit dialog
                  widget.onEdit(Event(
                    id: 'refresh_trigger',
                    title: '',
                    startDate: widget.event.startDate,
                    startTime: widget.event.startTime,
                    endDate: widget.event.endDate,
                    endTime: widget.event.endTime,
                  ));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Add helper function to format the title
  String _formatDisplayTitle(String title) {
    if (title.startsWith('BusCheck')) {
      // Use RegExp to find the number part and insert a space
      final match = RegExp(r'^BusCheck(\d+)$').firstMatch(title);
      if (match != null && match.groupCount >= 1) {
        final numberPart = match.group(1);
        if (numberPart != null) {
            return 'Bus Check $numberPart';
        }
      }
    }
    // Return original title if not BusCheck or format doesn't match
    return title.isEmpty ? 'Untitled Event' : title;
  }

  String _formatTimeString(String? timeStr) {
    if (timeStr == null || timeStr == 'nan') return '--:--';
    
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return timeStr;
  }
}
