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

  // Calculate work time for overtime shifts
  String? _calculateOvertimeWorkTime() {
    if (widget.event.title.contains('(OT)')) {
      // For UNI/Euro overtime shifts, use the work time already calculated in _loadUniShiftData
      if (RegExp(r'^\d{2,3}/').hasMatch(widget.event.title.replaceAll(RegExp(r'[AB]? \(OT\)$'), ''))) {
        if (workTime != null) {
          return workTime;
        }
      }
      
      // Handle regular overtime shifts
      // Convert TimeOfDay to minutes from midnight
      int startMinutes = widget.event.startTime.hour * 60 + widget.event.startTime.minute;
      int endMinutes = widget.event.endTime.hour * 60 + widget.event.endTime.minute;
      
      // Handle overnight shifts (end time is earlier than start time)
      if (endMinutes < startMinutes) {
        endMinutes += 24 * 60; // Add 24 hours
      }
      
      // Calculate the duration in minutes
      int durationMinutes = endMinutes - startMinutes;
      
      // Format as hours and minutes
      int hours = durationMinutes ~/ 60;
      int minutes = durationMinutes % 60;
      
      return '${hours}h ${minutes}m';
    }
    return null;
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
      String shiftCode;
      
      // Handle overtime shifts
      if (widget.event.title.contains('(OT)')) {
        // Extract the shift code from overtime title (e.g., "101A (OT)" becomes "101")
        // Remove the half indicator (A/B) and the (OT) suffix
        final otPattern = RegExp(r'^(.*?)[AB]? \(OT\)$');
        final match = otPattern.firstMatch(widget.event.title);
        if (match != null && match.groupCount >= 1) {
          shiftCode = match.group(1) ?? '';
        } else {
          shiftCode = widget.event.title.replaceAll(' (OT)', '');
          // Remove A or B if it exists at the end
          if (shiftCode.endsWith('A') || shiftCode.endsWith('B')) {
            shiftCode = shiftCode.substring(0, shiftCode.length - 1);
          }
        }
      } else {
        shiftCode = widget.event.title.replaceAll('Shift: ', '').trim();
      }
      
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
      
      // Check if this is a half overtime shift
      final bool isOvertimeShift = widget.event.title.contains('(OT)');
      final bool isFirstHalf = widget.event.title.contains('A (OT)');
      final bool isSecondHalf = widget.event.title.contains('B (OT)');
      
      // First check UNI_7DAYs.csv for all days
      String? startTime;
      String? endTime;
      String? workTimeStr;
      String? breakStartTime;
      String? breakEndTime;
      
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
          breakStartTime = parts[2].trim();
          breakEndTime = parts[3].trim();
          
          // Format times by removing seconds
          startTime = _formatTimeWithoutSeconds(startTime);
          endTime = _formatTimeWithoutSeconds(endTime);
          breakStartTime = _formatTimeWithoutSeconds(breakStartTime);
          breakEndTime = _formatTimeWithoutSeconds(breakEndTime);
          
          // For overtime half shifts, adjust times and calculate work time accordingly
          if (isOvertimeShift) {
            if (isFirstHalf && breakStartTime != null && breakStartTime.toLowerCase() != "nan") {
              // For first half, use start time to break start time
              final start = DateFormat('HH:mm').parse(startTime!);
              final end = DateFormat('HH:mm').parse(breakStartTime);
              final halfShiftDuration = end.difference(start);
              
              // Format work time
              final hours = halfShiftDuration.inHours;
              final minutes = halfShiftDuration.inMinutes % 60;
              workTimeStr = '${hours}h ${minutes}m';
              
              // Update end time for display
              endTime = breakStartTime;
            } else if (isSecondHalf && breakEndTime != null && breakEndTime.toLowerCase() != "nan") {
              // For second half, use break end time to finish time
              final start = DateFormat('HH:mm').parse(breakEndTime);
              final end = DateFormat('HH:mm').parse(endTime!);
              final halfShiftDuration = end.difference(start);
              
              // Format work time
              final hours = halfShiftDuration.inHours;
              final minutes = halfShiftDuration.inMinutes % 60;
              workTimeStr = '${hours}h ${minutes}m';
              
              // Update start time for display
              startTime = breakEndTime;
            } else {
              // Calculate full work time
              final start = DateFormat('HH:mm').parse(startTime!);
              final end = DateFormat('HH:mm').parse(endTime!);
              final totalSpread = end.difference(start);
              
              // If there's a break, subtract it
              if (breakStartTime != null && breakEndTime != null && 
                  breakStartTime.toLowerCase() != 'nan' && breakEndTime.toLowerCase() != 'nan') {
                final breakStart = DateFormat('HH:mm').parse(breakStartTime);
                final breakEnd = DateFormat('HH:mm').parse(breakEndTime);
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
            }
          } else {
            // Original code for non-overtime shifts
            // Calculate work time
            final start = DateFormat('HH:mm').parse(startTime!);
            final end = DateFormat('HH:mm').parse(endTime!);
            final totalSpread = end.difference(start);
            
            // If there's a break, subtract it
            if (breakStartTime != null && breakEndTime != null && 
                breakStartTime.toLowerCase() != 'nan' && breakEndTime.toLowerCase() != 'nan') {
              final breakStart = DateFormat('HH:mm').parse(breakStartTime);
              final breakEnd = DateFormat('HH:mm').parse(breakEndTime);
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
            breakStartTime = parts[2].trim();
            breakEndTime = parts[3].trim();
            
            // Format times by removing seconds
            startTime = _formatTimeWithoutSeconds(startTime);
            endTime = _formatTimeWithoutSeconds(endTime);
            breakStartTime = _formatTimeWithoutSeconds(breakStartTime);
            breakEndTime = _formatTimeWithoutSeconds(breakEndTime);
            
            // For overtime half shifts, adjust times and calculate work time accordingly
            if (isOvertimeShift) {
              if (isFirstHalf && breakStartTime != null && breakStartTime.toLowerCase() != "nan") {
                // For first half, use start time to break start time
                final start = DateFormat('HH:mm').parse(startTime!);
                final end = DateFormat('HH:mm').parse(breakStartTime);
                final halfShiftDuration = end.difference(start);
                
                // Format work time
                final hours = halfShiftDuration.inHours;
                final minutes = halfShiftDuration.inMinutes % 60;
                workTimeStr = '${hours}h ${minutes}m';
                
                // Update end time for display
                endTime = breakStartTime;
              } else if (isSecondHalf && breakEndTime != null && breakEndTime.toLowerCase() != "nan") {
                // For second half, use break end time to finish time
                final start = DateFormat('HH:mm').parse(breakEndTime);
                final end = DateFormat('HH:mm').parse(endTime!);
                final halfShiftDuration = end.difference(start);
                
                // Format work time
                final hours = halfShiftDuration.inHours;
                final minutes = halfShiftDuration.inMinutes % 60;
                workTimeStr = '${hours}h ${minutes}m';
                
                // Update start time for display
                startTime = breakEndTime;
              } else {
                // Calculate full work time
                final start = DateFormat('HH:mm').parse(startTime!);
                final end = DateFormat('HH:mm').parse(endTime!);
                final totalSpread = end.difference(start);
                
                // If there's a break, subtract it
                if (breakStartTime != null && breakEndTime != null && 
                    breakStartTime.toLowerCase() != 'nan' && breakEndTime.toLowerCase() != 'nan') {
                  final breakStart = DateFormat('HH:mm').parse(breakStartTime);
                  final breakEnd = DateFormat('HH:mm').parse(breakEndTime);
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
              }
            } else {
              // Original code for non-overtime shifts
              // Calculate work time
              final start = DateFormat('HH:mm').parse(startTime!);
              final end = DateFormat('HH:mm').parse(endTime!);
              final totalSpread = end.difference(start);
              
              // If there's a break, subtract it
              if (breakStartTime != null && breakEndTime != null && 
                  breakStartTime.toLowerCase() != 'nan' && breakEndTime.toLowerCase() != 'nan') {
                final breakStart = DateFormat('HH:mm').parse(breakStartTime);
                final breakEnd = DateFormat('HH:mm').parse(breakEndTime);
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
    // Check if it's a BusCheck shift
    final bool isBusCheckShift = widget.event.title.startsWith('BusCheck');
    
    // Define if this is a workout shift based on break time
    final isWorkout = breakTime?.toLowerCase().contains('workout') ?? false;
    
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
        cardColor = widget.shiftInfoMap['R']?.color.withValues(alpha: 0.3) ?? Colors.grey.shade100;
      } else {
        cardColor = shiftInfo?.color.withValues(alpha: 0.2) ?? Colors.blue.withValues(alpha: 0.2);
      }
    }
    
    // In dark mode, adjust card colors
    if (Theme.of(context).brightness == Brightness.dark) {
      if (isWorkShift) {
        if (widget.isRestDay) {
          cardColor = widget.shiftInfoMap['R']?.color.withValues(alpha: 0.3) ?? Colors.blueGrey.shade700;
        } else {
          cardColor = shiftInfo?.color.withValues(alpha: 0.2) ?? Colors.blueGrey.withValues(alpha: 0.2);
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
          // Check if it's a Spare shift
          if (isSpareShift) {
            _showSpareShiftDialog(context); // Call the internal dialog for spare shifts
          } else {
            widget.onEdit(widget.event); // Call the parent's onEdit for other shifts
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
                      if (workTime != null && !widget.event.title.contains('(OT)')) ...[
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
                ],
              ),
              const SizedBox(height: 6.0),
              
              // NEW: Report - Sign Off line (for PZ shifts and UNI overtime shifts)
              if (widget.event.title.startsWith('PZ') || (widget.event.title.contains('(OT)') && RegExp(r'^\d{2,3}/').hasMatch(widget.event.title.replaceAll(RegExp(r'[AB]? \(OT\)$'), ''))))
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
                              fontWeight: widget.event.title.contains('(OT)') ? FontWeight.bold : FontWeight.normal,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: widget.event.title.contains('(OT)') ? 'Start: ' : 'Report: ',
                              ),
                              TextSpan(
                                text: widget.event.formattedStartTime,
                                style: TextStyle( // Removed const and hardcoded black color
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9), // Use theme color, slightly less emphasis
                                  fontWeight: widget.event.title.contains('(OT)') ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              // Add location for overtime shifts if available - with correct locations based on shift type
                              if (widget.event.title.contains('A (OT)') && startLocation != null && startLocation!.isNotEmpty) ...[
                                // First half (A) overtime: show start location
                                TextSpan(
                                  text: ' $startLocation',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else if (widget.event.title.contains('B (OT)') && finishBreakLocation != null && finishBreakLocation!.isNotEmpty) ...[
                                // Second half (B) overtime: show finish break location as start location
                                TextSpan(
                                  text: ' $finishBreakLocation',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else if (widget.event.title.contains('(OT)') && startLocation != null && startLocation!.isNotEmpty) ...[
                                // Generic overtime: show start location
                                TextSpan(
                                  text: ' $startLocation',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              TextSpan(
                                text: widget.event.title.contains('(OT)') ? ' - Finish: ' : ' - Sign Off: ',
                              ),
                              TextSpan(
                                text: widget.event.formattedEndTime,
                                style: TextStyle( // Removed const and hardcoded black color
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9), // Use theme color, slightly less emphasis
                                  fontWeight: widget.event.title.contains('(OT)') ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              // Add appropriate finish location for overtime shifts based on half type
                              if (widget.event.title.contains('A (OT)') && startBreakLocation != null && startBreakLocation!.isNotEmpty) ...[
                                // First half (A) overtime: show break start location as finish location
                                TextSpan(
                                  text: ' $startBreakLocation',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else if (widget.event.title.contains('B (OT)') && finishLocation != null && finishLocation!.isNotEmpty) ...[
                                // Second half (B) overtime: show finish location
                                TextSpan(
                                  text: ' $finishLocation',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ] else if (widget.event.title.contains('(OT)') && finishLocation != null && finishLocation!.isNotEmpty) ...[
                                // Generic overtime: show finish location
                                TextSpan(
                                  text: ' $finishLocation',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Add work time display for overtime shifts
              if (widget.event.title.contains('(OT)')) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 6.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 14,
                            ),
                            children: <TextSpan>[
                              const TextSpan(text: 'Work Time: '),
                              TextSpan(
                                text: _calculateOvertimeWorkTime() ?? '',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // MODIFIED: Depart - Finish time with locations (PZ) or Start-End time (others)
              // Don't show this row for overtime shifts
              if (!widget.event.title.contains('(OT)')) ...[
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
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            fontSize: 14,
                          ),
                          children: _buildTimeDisplay(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
              ],
              // MODIFIED: Break times row (if available AND NOT BusCheck)
              if (breakTime != null && !isBusCheckShift && !widget.event.title.contains('(OT)')) ...[
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
                        // Calculate and include break duration
                        () {
                          String baseText;
                        // Only show break locations for PZ shifts that are not workouts
                          if (!breakTime!.toLowerCase().contains('workout') && widget.event.title.contains('PZ')) {
                            baseText = '${startBreakLocation != null ? "$startBreakLocation " : ""}${breakTime!}${finishBreakLocation != null ? " $finishBreakLocation" : ""}';
                          } else if (breakTime!.toLowerCase().contains('workout')) {
                            baseText = 'Workout';
                          } else {
                            baseText = breakTime!;
                          }
                          
                          // Add duration if not a workout
                          if (!breakTime!.toLowerCase().contains('workout')) {
                            final duration = _calculateBreakDuration(breakTime!);
                            if (duration != null) {
                              baseText += ' ($duration)';
                            }
                          }
                          
                          return baseText;
                        }(),
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
                  // Work time has been moved to the top right
                ],
              ),

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
                          final isOvertimeShift = widget.event.title.contains('(OT)');
                          final isWorkoutOrOvertime = isWorkout || isOvertimeShift;
                          
                          return Text(
                            isWorkoutOrOvertime
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

              // Late Break Status Section
              if (widget.event.hasLateBreak) ...[
                Row(
                  children: [
                    Icon(
                      widget.event.tookFullBreak
                          ? Icons.free_breakfast
                          : Icons.monetization_on,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.event.tookFullBreak
                            ? 'Late Break: Full Break Taken'
                            : 'Late Break: Overtime (${widget.event.overtimeDuration} mins)',
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
                  // Skip workouts for half duty assignments (when halfIndicator is not null)
                  if (halfIndicator != null && (startBreak.toUpperCase() == 'WORKOUT' || 
                      startBreak.toLowerCase() == 'workout' ||
                      startBreak.toLowerCase() == 'nan')) {
                    continue; // Skip workout duties for half duties
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
                    'Workouts excluded for half duty assignments',
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.schedule,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spare Shift',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.event.title} • ${widget.event.formattedStartTime} - ${widget.event.formattedEndTime}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show duty addition buttons if we have less than 2 duties
            if (widget.event.assignedDuties == null || widget.event.assignedDuties!.length < 2) ...[
              // Analyze existing duties to determine what can be added
              () {
                bool hasFullDuty = false;
                bool hasHalfDuty = false;
                
                if (widget.event.assignedDuties != null) {
                  for (String duty in widget.event.assignedDuties!) {
                    // Remove UNI: prefix if present for analysis
                    String dutyCode = duty.startsWith('UNI:') ? duty.substring(4) : duty;
                    
                    if (dutyCode.endsWith('A') || dutyCode.endsWith('B')) {
                      hasHalfDuty = true;
                    } else {
                      hasFullDuty = true;
                    }
                  }
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Enhanced section header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_circle_outline, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add Duty',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasFullDuty 
                              ? 'Full duty assigned - no additional duties allowed'
                              : hasHalfDuty
                                ? 'Half duties assigned - only additional half duties allowed'
                                : 'Choose the type of duty to add to your spare shift:',
                style: TextStyle(
                  fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                ),
              ),
              const SizedBox(height: 16),

                    // Show buttons based on existing duties
                    if (!hasFullDuty && !hasHalfDuty) ...[
                      // No duties assigned - show all options
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDutySelectionDialog(context);
                },
                          icon: const Icon(Icons.work, size: 18),
                          label: const Text('Full Duty'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                ),
                        ),
              ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                                _showDutySelectionDialog(context, 'A');
                              },
                              icon: const Icon(Icons.schedule, size: 16),
                              label: const Text('First Half'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                ),
                              ),
                            ),
              ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                                _showDutySelectionDialog(context, 'B');
                              },
                              icon: const Icon(Icons.access_time, size: 16),
                              label: const Text('Second Half'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (hasHalfDuty && !hasFullDuty) ...[
                      // Half duties assigned - only show half duty options
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showDutySelectionDialog(context, 'A');
                              },
                              icon: const Icon(Icons.schedule, size: 16),
                              label: const Text('First Half'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showDutySelectionDialog(context, 'B');
                              },
                              icon: const Icon(Icons.access_time, size: 16),
                              label: const Text('Second Half'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // If hasFullDuty is true, no buttons are shown
                  ],
                );
              }(),
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
                                       child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         // Duty info row
                         Row(
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
                             IconButton(
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
                                   busAssignments: widget.event.busAssignments,
                          );
                          
                                 // Remove the specific duty and its bus assignment
                                 final dutyCode = duty['dutyCode'] as String;
                                 widget.event.assignedDuties!.remove(dutyCode);
                                 widget.event.setBusForDuty(dutyCode, null);
                          
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
                               icon: const Icon(Icons.delete_outline),
                               color: Colors.red,
                               iconSize: 20,
                               constraints: const BoxConstraints(
                                 minWidth: 32,
                                 minHeight: 32,
                               ),
                               padding: EdgeInsets.zero,
                               tooltip: 'Remove duty',
                             ),
                           ],
                         ),
                         const SizedBox(height: 8),
                         // Bus assignment row
                         Container(
                           padding: const EdgeInsets.all(10),
                           decoration: BoxDecoration(
                             color: widget.event.getBusForDuty(duty['dutyCode'] ?? '') != null 
                                 ? Colors.green.withValues(alpha: 0.1)
                                 : Colors.orange.withValues(alpha: 0.1),
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(
                               color: widget.event.getBusForDuty(duty['dutyCode'] ?? '') != null 
                                   ? Colors.green.withValues(alpha: 0.3)
                                   : Colors.orange.withValues(alpha: 0.3),
                             ),
                           ),
                           child: Row(
                             children: [
                               Icon(
                                 widget.event.getBusForDuty(duty['dutyCode'] ?? '') != null 
                                     ? Icons.directions_bus 
                                     : Icons.bus_alert_outlined,
                                 color: widget.event.getBusForDuty(duty['dutyCode'] ?? '') != null 
                                     ? Colors.green 
                                     : Colors.orange,
                                 size: 18,
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(
                                       widget.event.getBusForDuty(duty['dutyCode'] ?? '') != null 
                                           ? 'Assigned Bus'
                                           : 'No Bus Assigned',
                                       style: TextStyle(
                                         fontSize: 11,
                                         fontWeight: FontWeight.w600,
                                         color: widget.event.getBusForDuty(duty['dutyCode'] ?? '') != null 
                                             ? Colors.green 
                                             : Colors.orange,
                                       ),
                                     ),
                                     if (widget.event.getBusForDuty(duty['dutyCode'] ?? '') != null)
                                       Text(
                                         widget.event.getBusForDuty(duty['dutyCode'] ?? '')!,
                                         style: TextStyle(
                                           fontSize: 13,
                                           fontWeight: FontWeight.bold,
                                           color: Colors.green[700],
                        ),
                                       ),
                                   ],
                                 ),
                               ),
                                                                ElevatedButton(
                                   onPressed: () async {
                                     await _showDutyBusAssignmentDialog(context, duty['dutyCode'] ?? '');
                                   },
                                 child: const Icon(
                                   Icons.add,
                                   size: 14,
                                 ),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: AppTheme.primaryColor,
                                   foregroundColor: Colors.white,
                                   padding: const EdgeInsets.all(8),
                                   minimumSize: Size.zero,
                                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                   shape: RoundedRectangleBorder(
                                     borderRadius: BorderRadius.circular(6),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                      ),
                    ],
                  ),
                )).toList();
              })(),
              const SizedBox(height: 16),
            ],
            
            // Show delete button at the bottom
             Container(
               width: double.infinity,
               margin: const EdgeInsets.only(top: 8),
               child: ElevatedButton.icon(
              onPressed: () async {
                // Show confirmation dialog
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                       title: Row(
                         children: [
                           Icon(Icons.warning_amber, color: Colors.red, size: 24),
                           const SizedBox(width: 8),
                           const Text('Delete Event'),
                         ],
                       ),
                       content: const Text('Are you sure you want to delete this spare event? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                         ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.red,
                             foregroundColor: Colors.white,
                           ),
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
                 icon: const Icon(Icons.delete_forever),
                 label: const Text('Delete Spare Event'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.red,
                   foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(8),
              ),
                 ),
               ),
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
                          'Assigned: $displayDutyCode | '
                            '${_formatTimeString(duty['startTime'])} to '
                          '${_formatTimeString(duty['endTime'])}'
                          '${widget.event.getBusForDuty(duty['dutyCode'] ?? '') != null ? ' | Bus: ${widget.event.getBusForDuty(duty['dutyCode'] ?? '')}' : ''}',
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

  // Show bus assignment dialog for a specific duty
  Future<void> _showDutyBusAssignmentDialog(BuildContext context, String dutyCode) async {
    String? busNumber = widget.event.getBusForDuty(dutyCode);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Assign Bus to $dutyCode'),
        content: TextField(
          onChanged: (value) => busNumber = value.isEmpty ? null : value,
          controller: TextEditingController(text: widget.event.getBusForDuty(dutyCode) ?? ''),
          decoration: const InputDecoration(
            labelText: 'Bus Number',
            hintText: 'e.g., EW64, PA168, SG559',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          if (widget.event.getBusForDuty(dutyCode) != null)
            TextButton(
              onPressed: () async {
                await _updateDutyBus(dutyCode, null);
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove Bus'),
            ),
          TextButton(
            onPressed: () async {
              // Normalize the bus number like other duties
              String? normalizedBusNumber = busNumber?.trim().toUpperCase();
              // Remove any spaces
              normalizedBusNumber = normalizedBusNumber?.replaceAll(' ', '');
              
              await _updateDutyBus(dutyCode, normalizedBusNumber?.isEmpty == true ? null : normalizedBusNumber);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  // Update duty bus assignment
  Future<void> _updateDutyBus(String dutyCode, String? newBus) async {
    // Create a copy of the old event
    final oldEvent = Event(
      id: widget.event.id,
      title: widget.event.title,
      startDate: widget.event.startDate,
      startTime: widget.event.startTime,
      endDate: widget.event.endDate,
      endTime: widget.event.endTime,
      assignedDuties: widget.event.assignedDuties,
      busAssignments: widget.event.busAssignments,
    );
    
    // Update the bus assignment
    widget.event.setBusForDuty(dutyCode, newBus);
    
    // Save the updated event
    await EventService.updateEvent(oldEvent, widget.event);
    
    // Refresh the UI
    if (mounted) {
      setState(() {});
      // Also close and reopen the spare shift dialog to show the updated bus assignment
      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _showSpareShiftDialog(context);
      });
    }
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

  // Method to build the appropriate time display based on shift type
  List<TextSpan> _buildTimeDisplay() {
    // Check if this is an overtime shift by looking for (OT) in title and A/B indicator
    final bool isOvertimeShift = widget.event.title.contains('(OT)');
    final bool isFirstHalf = isOvertimeShift && widget.event.title.contains('A (OT)');
    final bool isSecondHalf = isOvertimeShift && widget.event.title.contains('B (OT)');
    
    // For PZ shifts, use the specialized display format
    if (widget.event.title.startsWith('PZ')) {
      return <TextSpan>[
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
      ];
    }
    
    // For overtime shifts, show special time displays
    else if (isOvertimeShift) {
      // Extract the break time from the string format "10:00 - 10:40"
      String? breakStartStr;
      String? breakEndStr;
      
      if (breakTime != null && breakTime!.contains('-')) {
        final parts = breakTime!.split('-');
        if (parts.length == 2) {
          breakStartStr = parts[0].trim();
          breakEndStr = parts[1].trim();
        }
      }
      
      if (isFirstHalf) {
        // First half overtime: Show start time to break start time
        return <TextSpan>[
          const TextSpan(
            text: 'First Half: ',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: widget.event.formattedStartTime,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' - '),
          TextSpan(
            text: breakStartStr ?? widget.event.formattedEndTime, // Use break start time if available
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ];
      } else if (isSecondHalf) {
        // Second half overtime: Show break end time to finish time
        return <TextSpan>[
          const TextSpan(
            text: 'Second Half: ',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: breakEndStr ?? widget.event.formattedStartTime, // Use break end time if available
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' - '),
          TextSpan(
            text: widget.event.formattedEndTime,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ];
      } else {
        // Generic overtime display with OT indicator
        return <TextSpan>[
          TextSpan(
            text: widget.event.formattedStartTime,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' - '),
          TextSpan(
            text: widget.event.formattedEndTime,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' (OT)', style: TextStyle(color: Colors.orange)),
        ];
      }
    }
    
    // For regular (non-PZ, non-overtime) shifts: Standard time display
    else {
      return <TextSpan>[
        TextSpan(
          text: widget.event.formattedStartTime,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const TextSpan(text: ' - '),
        TextSpan(
          text: widget.event.formattedEndTime,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ];
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Helper method to calculate break duration from break time string
  String? _calculateBreakDuration(String breakTimeString) {
    try {
      // Handle workout case
      if (breakTimeString.toLowerCase().contains('workout')) {
        return null;
      }
      
      // Extract times from format like "13:30 - 14:00" or "Location 13:30 - 14:00 Location"
      final timePattern = RegExp(r'(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})');
      final match = timePattern.firstMatch(breakTimeString);
      
      if (match == null) return null;
      
      final startTimeStr = match.group(1)!;
      final endTimeStr = match.group(2)!;
      
      // Parse the times
      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      // Create DateTime objects for calculation (using same day)
      final now = DateTime.now();
      final startDateTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
      var endDateTime = DateTime(now.year, now.month, now.day, endHour, endMinute);
      
      // Handle case where break spans midnight (end time is earlier than start time)
      if (endDateTime.isBefore(startDateTime)) {
        endDateTime = endDateTime.add(const Duration(days: 1));
      }
      
      final duration = endDateTime.difference(startDateTime);
      final minutes = duration.inMinutes;
      
      if (minutes <= 0) return null;
      
      // Format duration
      if (minutes < 60) {
        return '${minutes}m';
      } else {
        final hours = minutes ~/ 60;
        final remainingMinutes = minutes % 60;
        if (remainingMinutes == 0) {
          return '${hours}h';
        } else {
          return '${hours}h ${remainingMinutes}m';
        }
      }
    } catch (e) {
      return null;
    }
  }
}
