import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/core/utils/location_utils.dart';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/models/shift_data.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:csv/csv.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final String shiftType;
  final Map<String, ShiftInfo> shiftInfoMap;
  final Function(Event) onEdit;
  final bool isBankHoliday;
  final bool isRestDay;

  const EventCard({
    Key? key,
    required this.event,
    required this.shiftType,
    required this.shiftInfoMap,
    required this.onEdit,
    this.isBankHoliday = false,
    this.isRestDay = false,
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
      
      // Find zone number from the shift code
      String zoneNumber = '1'; // Default to zone 1
      final match = RegExp(r'PZ(\d+)/').firstMatch(shiftCode);
      if (match != null) {
        zoneNumber = match.group(1) ?? '1';
      }
      
      // Get the appropriate filename based on day of week and bank holiday status
      final filename = RosterService.getShiftFilename(zoneNumber, dayOfWeek, widget.event.startDate);
      
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
          String? breakStart = null;
          String? breakEnd = null;
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
    if (widget.event.assignedDuties == null || widget.event.assignedDuties!.isEmpty) {
      setState(() {
        _assignedDutyStartTime = null;
        _assignedDutyEndTime = null;
        _assignedDutyStartLocation = null;
        _assignedDutyEndLocation = null;
        _allDutyDetails = [];
      });
      return;
    }

    // Create a list to store duty details
    List<Map<String, String?>> dutyDetails = [];

    for (String dutyCode in widget.event.assignedDuties!) {
      // Check if it's a half duty
      bool isHalfDuty = dutyCode.endsWith('A') || dutyCode.endsWith('B');
      String baseDutyCode = isHalfDuty ? dutyCode.substring(0, dutyCode.length - 1) : dutyCode;

      // Determine which CSV file to load based on the duty code
      String csvFileName;
      if (baseDutyCode.startsWith('PZ1')) {
        csvFileName = 'M-F_DUTIES_PZ1.csv';
      } else if (baseDutyCode.startsWith('PZ3')) {
        csvFileName = 'M-F_DUTIES_PZ3.csv';
      } else if (baseDutyCode.startsWith('PZ4')) {
        csvFileName = 'M-F_DUTIES_PZ4.csv';
      } else {
        continue; // Skip if not a recognized zone
      }

      // Load the CSV file
      final csvData = await rootBundle.loadString('assets/$csvFileName');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);

      // Find the matching duty in the CSV
      final matchingDuty = csvTable.firstWhere(
        (row) => row[0].toString() == baseDutyCode,
        orElse: () => [],
      );

      if (matchingDuty.isNotEmpty) {
        // Extract times and locations based on duty type
        String startTime, endTime;
        String? startLocation, endLocation;

        if (isHalfDuty) {
          if (dutyCode.endsWith('A')) {
            // First half
            startTime = matchingDuty[2]?.toString() ?? '';  // report time
            endTime = matchingDuty[5]?.toString() ?? '';    // break start time
            startLocation = matchingDuty[4]?.toString() ?? '';  // location
            endLocation = matchingDuty[6]?.toString() ?? '';    // break start location
          } else {
            // Second half
            startTime = matchingDuty[8]?.toString() ?? '';  // break end time
            endTime = matchingDuty[10]?.toString() ?? '';   // finish time
            startLocation = matchingDuty[9]?.toString() ?? '';  // break end location
            endLocation = matchingDuty[11]?.toString() ?? '';   // finish location
          }
        } else {
          // Full duty
          startTime = matchingDuty[2]?.toString() ?? '';    // report time
          endTime = matchingDuty[10]?.toString() ?? '';     // finish time
          startLocation = matchingDuty[4]?.toString() ?? '';  // location
          endLocation = matchingDuty[11]?.toString() ?? '';   // finish location
        }

        // Map location names and ensure they're not null
        startLocation = mapLocationName(startLocation ?? '');
        endLocation = mapLocationName(endLocation ?? '');

        // Only add the duty if we have valid location data
        if (startLocation.isNotEmpty && endLocation.isNotEmpty) {
          dutyDetails.add({
            'dutyCode': dutyCode,
            'startTime': startTime,
            'endTime': endTime,
            'startLocation': startLocation,
            'endLocation': endLocation,
          });
        }
      }
    }

    // Sort duty details by start time
    dutyDetails.sort((a, b) => (a['startTime'] ?? '').compareTo(b['startTime'] ?? ''));

    // Update state with the first duty's details (for backward compatibility)
    if (dutyDetails.isNotEmpty) {
      setState(() {
        _assignedDutyStartTime = dutyDetails[0]['startTime'];
        _assignedDutyEndTime = dutyDetails[0]['endTime'];
        _assignedDutyStartLocation = dutyDetails[0]['startLocation'];
        _assignedDutyEndLocation = dutyDetails[0]['endLocation'];
        _allDutyDetails = dutyDetails;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftInfo = widget.shiftInfoMap[widget.shiftType];
    
    // Check if this is a work shift
    final isWorkShift = widget.event.isWorkShift;
    
    // Check if it's a Spare shift
    final isSpareShift = isWorkShift && widget.event.title.startsWith('SP');
    
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
            ? BorderSide(color: AppTheme.errorColor, width: 1.5)
            : BorderSide.none,
      ),
      color: cardColor,
      child: InkWell(
        onTap: () {
          // Use a specialized dialog for spare shifts
          if (isSpareShift) {
            _showSpareShiftDialog(context);
          } else if (!widget.event.title.contains('A') && !widget.event.title.contains('B')) {
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
                children: [
                  Expanded(
                    child: Text(
                      widget.event.title.isEmpty ? 'Untitled Event' : widget.event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status badges row
                  Row(
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
                ],
              ),
              const SizedBox(height: 4.0),
              
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
                            style: TextStyle(
                              color: Colors.black, // Lighter color -> Changed to black
                              fontSize: 14,
                              // fontWeight: FontWeight.w600, // REMOVE overall bold
                            ),
                            children: <TextSpan>[
                              const TextSpan(text: 'Report: '),
                              TextSpan(
                                text: widget.event.formattedStartTime,
                                style: TextStyle( // Removed const
                                  color: Colors.black, // Use theme color for time -> Changed to black
                                ),
                              ),
                              const TextSpan(text: ' - Sign Off: '),
                              TextSpan(
                                text: widget.event.formattedEndTime,
                                style: TextStyle( // Removed const
                                  color: Colors.black, // Use theme color for time -> Changed to black
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
              const SizedBox(height: 4.0),
              // Break times row (if available)
              if (breakTime != null) ...[
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
                            ? '${startBreakLocation != null ? "$startBreakLocation " : ""}' +
                              breakTime! +
                              '${finishBreakLocation != null ? " $finishBreakLocation" : ""}'
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
                const SizedBox(height: 4.0),
              ],
              const SizedBox(height: 4.0),
              // Show assigned duty details if available
              if (widget.event.assignedDuties != null && widget.event.assignedDuties!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Expanded(
                    child: _buildAssignedDuties(),
                  ),
                ),
              ],
              const SizedBox(height: 4.0),
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
              const SizedBox(height: 4.0),
              // Bus assignment row
              if (widget.event.firstHalfBus != null || widget.event.secondHalfBus != null) ...[
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
                const SizedBox(height: 4.0),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDutySelectionDialog(BuildContext context, [String? halfIndicator]) async {
    String selectedZone = 'Zone 1';
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
                    
                    // Check if this is a workout duty (nan,nan)
                    if (parts[2].trim().toLowerCase() == 'nan' && 
                        parts[3].trim().toLowerCase() == 'nan') {
                      continue; // Skip workout duties
                    }
                    
                    final dutyCode = parts[0].trim();
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
                      
                      // Check if this is a workout duty (nan,nan)
                      if (parts[2].trim().toLowerCase() == 'nan' && 
                          parts[3].trim().toLowerCase() == 'nan') {
                        continue; // Skip workout duties
                      }
                      
                      final dutyCode = parts[0].trim();
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
                      final newDuty = halfIndicator != null 
                          ? '${selectedDuty}$halfIndicator'
                          : selectedDuty;
                      
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
                  side: BorderSide(color: AppTheme.primaryColor),
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
                  side: BorderSide(color: AppTheme.primaryColor),
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
                  side: BorderSide(color: AppTheme.primaryColor),
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
                          'Assigned: ${duty['dutyCode']}',
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
                        child: const Text('Delete'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _allDutyDetails.map((duty) {
        // Calculate work duration for this duty
        String workDuration = '';
        if (duty['startTime'] != null && duty['endTime'] != null) {
          final startParts = duty['startTime']!.split(':');
          final endParts = duty['endTime']!.split(':');
          
          if (startParts.length >= 2 && endParts.length >= 2) {
            final start = DateTime(2024, 1, 1, int.parse(startParts[0]), int.parse(startParts[1]));
            final end = DateTime(2024, 1, 1, int.parse(endParts[0]), int.parse(endParts[1]));
            
            final duration = end.difference(start);
            final hours = duration.inHours;
            final minutes = duration.inMinutes % 60;
            
            workDuration = '${hours}h ${minutes}m';
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
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
                        'Assigned: ${duty['dutyCode']} | '
                        '${duty['startLocation'] ?? ""} - '
                        '${duty['startTime'] ?? ""} '
                        '${duty['endTime'] ?? ""} - '
                        '${duty['endLocation'] ?? ""}',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (workDuration.isNotEmpty)
                      Text(
                        'Work: $workDuration',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
}
