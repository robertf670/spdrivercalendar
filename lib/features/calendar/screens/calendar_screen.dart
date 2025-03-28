import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:spdrivercalendar/features/calendar/widgets/event_card.dart';
import 'package:spdrivercalendar/features/calendar/widgets/shift_details_card.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/add_event_dialog.dart';
import 'package:spdrivercalendar/features/statistics/screens/statistics_screen.dart';
import 'package:spdrivercalendar/features/settings/screens/settings_screen.dart';
import 'package:spdrivercalendar/features/about/screens/about_screen.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/models/shift_data.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:spdrivercalendar/services/board_service.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/view_board_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:spdrivercalendar/services/rest_days_service.dart'; // Added import
import 'package:spdrivercalendar/features/contacts/contacts_page.dart'; // Add this line

class CalendarScreen extends StatefulWidget {
  final ValueNotifier<bool> isDarkModeNotifier;

  const CalendarScreen(this.isDarkModeNotifier, {Key? key}) : super(key: key);

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> 
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _startDate;
  int _startWeek = 0;
  Map<DateTime, List<Event>> _events = {};
  List<BankHoliday>? _bankHolidays;
  List<Holiday> _holidays = [];
  late AnimationController _animationController;
  
  final Map<String, ShiftInfo> _shiftInfoMap = {
    'E': ShiftInfo('Early', AppTheme.shiftColors['E']!),
    'L': ShiftInfo('Late', AppTheme.shiftColors['L']!),
    'M': ShiftInfo('Middle', AppTheme.shiftColors['M']!),
    'R': ShiftInfo('Rest', AppTheme.shiftColors['R']!),
  };

  // Add holiday color constant
  static const Color holidayColor = Color(0xFF00BCD4); // Teal color for holidays

  @override
  void initState() {
    // print("*** initState: Entered ***"); // Basic Debug 1 -- Removed
    super.initState();
    // print("*** initState: After super.initState() ***"); // Basic Debug 2 -- Removed
    _initializeData(); // Call the async initialization method
    _selectedDay = DateTime.now();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    WidgetsBinding.instance.addObserver(this);
    
    // Add this line to update all events when the app starts
    // _updateAllEvents(); // Temporarily comment out if suspected to interfere
    // print("*** initState: Exiting ***"); // Basic Debug 3 -- Removed
  }

  Future<void> _initializeData() async {
    // print("*** _initializeData: Entered ***"); // Basic Debug 4 -- Removed
    // print("[Init Debug] Starting _initializeData..."); // Keep previous debug -- Removed
    try {
      // Ensure RestDaysService is initialized before loading other data that might depend on it
      await RestDaysService.initialize(); 
      // print("[Init Debug] RestDaysService initialized."); // Debug -- Removed
      
      // Load bank holidays
      _bankHolidays = await RosterService.loadBankHolidays();
      // print("[Init Debug] Bank holidays loaded."); // Debug -- Removed
      
      // Load holidays
      _holidays = await HolidayService.getHolidays();
      // print("[Init Debug] Holidays loaded."); // Debug -- Removed
      
      // Load settings (which might depend on RosterService indirectly)
      await _loadSettings();
      // print("[Init Debug] Settings loaded."); // Debug -- Removed
      
      // Load events
      _events = await EventService.loadEvents();
      // print("[Init Debug] Events loaded."); // Debug -- Removed
      
      // Update UI only after all data is loaded
      if (mounted) {
          setState(() {});
          // print("[Init Debug] _initializeData complete, calling setState."); // Debug -- Removed
      }
    } catch (e) {
      // print('[Init Debug] Error initializing data: $e'); // Debug -- Removed
      // Optionally show an error message to the user
    }
  }

  Future<void> _loadSettings() async {
    final startDateString = await StorageService.getString(AppConstants.startDateKey);
    final startWeek = await StorageService.getInt(AppConstants.startWeekKey) ?? 0;
    
    setState(() {
      if (startDateString != null) {
        _startDate = DateTime.parse(startDateString);
        _startWeek = startWeek;
      }
    });

    if (_startDate == null) {
      // Display first run dialog after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFirstRunDialog();
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_startDate != null) {
      await StorageService.saveString(AppConstants.startDateKey, _startDate!.toIso8601String());
      await StorageService.saveInt(AppConstants.startWeekKey, _startWeek);
    }
  }

  void _showFirstRunDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Choose rest days:'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Choose this weeks rest days'),
                    DropdownButton<int>(
                      value: _startWeek,
                      items: List.generate(5, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text('Rest: ${RosterService.getRestDaysForWeek(index)}'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _startWeek = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Automatically set the start date to the Sunday of the current week
                        _startDate = RosterService.getSundayOfCurrentWeek();
                        
                        await _saveSettings();
                        Navigator.of(context).pop();
                        
                        // Force a rebuild to show the updated calendar
                        this.setState(() {});
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Calculate the shift for a given date
  String getShiftForDate(DateTime date) {
    if (_startDate == null) return '';
    return RosterService.getShiftForDate(date, _startDate!, _startWeek);
  }
  
  // Get events for a specific day
  List<Event> getEventsForDay(DateTime day) {
    List<Event> events = EventService.getEventsForDay(day);
    List<Event> holidayEvents = [];
    
    // First, check for holidays and create holiday events
    for (final holiday in _holidays) {
      if (holiday.containsDate(day)) {
        // Check if a holiday event already exists for this day
        bool holidayExists = events.any((event) => 
          event.isHoliday && 
          event.holidayType == holiday.type &&
          event.startDate == day
        );
        
        if (!holidayExists) {
          final holidayEvent = Event(
            id: 'holiday_${holiday.id}_${day.millisecondsSinceEpoch}',
            title: holiday.type == 'winter' ? 'Winter Holiday' : 
                   holiday.type == 'summer' ? 'Summer Holiday' : 
                   'Other Holiday',
            startDate: day,
            startTime: const TimeOfDay(hour: 0, minute: 0),
            endDate: day,
            endTime: const TimeOfDay(hour: 23, minute: 59),
            isHoliday: true,
            holidayType: holiday.type,
          );
          holidayEvents.add(holidayEvent);
        }
      }
    }
    
    // Combine holiday events with regular events, ensuring holidays appear first
    return [...holidayEvents, ...events];
  }

  // Get bank holiday for a specific date
  BankHoliday? getBankHoliday(DateTime date) {
    if (_bankHolidays == null) return null;
    for (final holiday in _bankHolidays!) {
      if (holiday.matchesDate(date)) {
        return holiday;
      }
    }
    return null;
  }
  
  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: const Text('What type of event would you like to add?'),
          actions: [
            TextButton(
              child: const Text('Normal Event'),
              onPressed: () {
                Navigator.of(context).pop();
                _showNormalEventDialog();
              },
            ),
            TextButton(
              child: const Text('Work Shift'),
              onPressed: () {
                Navigator.of(context).pop();
                _showWorkShiftDialog();
              },
            ),
          ],
        );
      },
    );
  }

  void _showNormalEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        selectedDate: _selectedDay ?? DateTime.now(),
        onEventAdded: (event) {
          EventService.addEvent(event).then((_) {
            setState(() {});
          });
        },
      ),
    );
  }

  // Show dialog to select and add a work shift
  void _showWorkShiftDialog() {
    final now = DateTime.now();
    final shiftDate = _selectedDay ?? now;
    String selectedZone = 'Zone 1';
    String selectedShiftNumber = '';
    List<String> shiftNumbers = [];
    bool isLoading = true;
    
    // Show dialog with loading state initially
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          // Function to load shift numbers for selected zone
          void loadShiftNumbers() async {
            setState(() {
              isLoading = true;
            });
            
            try {
              final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
              final zoneNumber = selectedZone.replaceAll('Zone ', '');
              
              // Handle Spare and Uni/Euro differently
              if (selectedZone == 'Spare') {
                // For Spare, create shift options using just the time
                shiftNumbers = [];
                
                // Generate time options for spare shifts (04:00 to 16:00 in 15 min increments)
                for (int hour = 4; hour <= 16; hour++) {
                  for (int minute = 0; minute < 60; minute += 15) {
                    // Stop at 16:00 exactly (don't include 16:15, 16:30, etc.)
                    if (hour == 16 && minute > 0) continue;
                    
                    final hourStr = hour.toString().padLeft(2, '0');
                    final minuteStr = minute.toString().padLeft(2, '0');
                    final timeStr = '$hourStr:$minuteStr';
                    // Store both the visible time and the SP code for later use
                    shiftNumbers.add(timeStr);
                  }
                }
              } else if (selectedZone == 'Uni/Euro') {
                // Uni/Euro shifts - use both files on weekdays, only 7DAYs on weekends
                List<String> combinedShifts = [];
                
                // Always load from UNI_7DAYs.csv first
                try {
                  final csv = await rootBundle.loadString('assets/UNI_7DAYs.csv');
                  final lines = csv.split('\n');
                  
                  // Don't skip any lines for UNI files
                  for (final line in lines) {
                    if (line.trim().isEmpty) continue;
                    final parts = line.split(',');
                    if (parts.isNotEmpty) {
                      combinedShifts.add(parts[0]);
                    }
                  }
                } catch (e) {
                  print('Error loading UNI_7DAYs.csv: $e');
                }
                
                // On weekdays, also load from UNI_M-F.csv
                if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {
                  try {
                    final csv = await rootBundle.loadString('assets/UNI_M-F.csv');
                    final lines = csv.split('\n');
                    
                    // Don't skip any lines for UNI files
                    for (final line in lines) {
                      if (line.trim().isEmpty) continue;
                      final parts = line.split(',');
                      if (parts.isNotEmpty) {
                        combinedShifts.add(parts[0]);
                      }
                    }
                  } catch (e) {
                    print('Error loading UNI_M-F.csv: $e');
                  }
                }
                
                // Keep only unique shifts while preserving order (first occurrence wins)
                shiftNumbers = [];
                final seenShifts = <String>{};
                for (final shift in combinedShifts) {
                  if (!seenShifts.contains(shift)) {
                    seenShifts.add(shift);
                    shiftNumbers.add(shift);
                  }
                }
              } else {
                // Regular zone shifts - preserve CSV file order
                final filename = RosterService.getShiftFilename(zoneNumber, dayOfWeek, shiftDate);
                
                try {
                  final csv = await rootBundle.loadString('assets/$filename');
                  final lines = csv.split('\n');
                  shiftNumbers = [];
                  final seenShifts = <String>{};
                  
                  // Skip the header line (first line)
                  for (int i = 1; i < lines.length; i++) {
                    final line = lines[i];
                    if (line.trim().isEmpty) continue;
                    final parts = line.split(',');
                    if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
                      final shift = parts[0].trim();
                      if (!seenShifts.contains(shift) && shift != "shift") {
                        seenShifts.add(shift);
                        shiftNumbers.add(shift);
                      }
                    }
                  }
                } catch (e) {
                  shiftNumbers = [];
                  print('Error loading shifts for $filename: $e');
                }
              }
            } catch (e) {
              print('Error loading shift numbers: $e');
              shiftNumbers = [];
            }
            
            selectedShiftNumber = shiftNumbers.isNotEmpty ? shiftNumbers[0] : '';
            
            setState(() {
              isLoading = false;
            });
          }
          
          // Load shift numbers when zone changes or dialog opens
          if (isLoading) {
            loadShiftNumbers();
          }
                  
          return AlertDialog(
            title: Text('Add Work Shift for ${DateFormat('EEE, MMM d').format(shiftDate)}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedZone,
                  isExpanded: true,
                  items: ['Zone 1', 'Zone 3', 'Zone 4', 'Spare', 'Uni/Euro'].map((zone) {
                    return DropdownMenuItem(
                      value: zone,
                      child: Text(zone),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != selectedZone) {
                      setState(() {
                        selectedZone = value;
                        selectedShiftNumber = '';
                        loadShiftNumbers();
                      });
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                const Text('Shift:', style: TextStyle(fontWeight: FontWeight.bold)),
                isLoading
                  ? const SizedBox(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : shiftNumbers.isEmpty
                    ? const Text('No shifts available for selected zone and date')
                    : DropdownButton<String>(
                        value: selectedShiftNumber.isEmpty ? shiftNumbers[0] : selectedShiftNumber,
                        isExpanded: true,
                        items: shiftNumbers.map((shift) {
                          return DropdownMenuItem(
                            value: shift,
                            child: Text(shift),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedShiftNumber = value;
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
                onPressed: isLoading || shiftNumbers.isEmpty || selectedShiftNumber.isEmpty
                  ? null  // Disable button if loading or no shifts available
                  : () async {
                      // Create title based on zone and shift
                      String title = '';
                      // For Spare shifts, create SP code from time
                      if (selectedZone == 'Spare') {
                        // Convert the time (like "06:00") to SP code (like "SP0600")
                        final timeStr = selectedShiftNumber; // The time is now directly stored
                        final timeWithoutColon = timeStr.replaceAll(':', '');
                        title = 'SP$timeWithoutColon';
                      } else if (selectedZone == 'Uni/Euro') {
                        title = selectedShiftNumber;
                      } else {
                        title = selectedShiftNumber;
                      }
                      
                      // Load shift times based on zone
                      Map<String, dynamic>? shiftTimes;
                      
                      if (selectedZone == 'Spare') {
                        // Parse the time directly from the dropdown value (e.g., "04:00")
                        final timeParts = selectedShiftNumber.split(':');
                        if (timeParts.length == 2) {
                          final hour = int.parse(timeParts[0]);
                          final minute = int.parse(timeParts[1]);
                          
                          // Calculate end time (8h 38m later)
                          int endHour = hour + 8;
                          int endMinute = minute + 38;
                          
                          // Adjust for minute overflow
                          if (endMinute >= 60) {
                            endHour += 1;
                            endMinute -= 60;
                          }
                          
                          // Adjust for 24-hour wrap
                          if (endHour >= 24) {
                            endHour -= 24;
                          }
                          
                          shiftTimes = {
                            'startTime': TimeOfDay(hour: hour, minute: minute),
                            'endTime': TimeOfDay(hour: endHour, minute: endMinute),
                          };
                        } else {
                          // Fallback if pattern doesn't match
                          shiftTimes = {
                            'startTime': const TimeOfDay(hour: 4, minute: 0),
                            'endTime': const TimeOfDay(hour: 12, minute: 38),
                          };
                        }
                      } else {
                        // For other zones, load from CSV
                        shiftTimes = await _getShiftTimes(selectedZone, selectedShiftNumber, shiftDate);
                      }
                      
                      if (shiftTimes == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error loading shift times')),
                        );
                        return;
                      }
                      
                      // Create the event with non-null assurances
                      final event = Event(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        startDate: shiftDate,
                        startTime: shiftTimes['startTime']!,
                        endDate: shiftTimes['isNextDay'] == true
                            ? shiftDate.add(const Duration(days: 1))  // Next day
                            : shiftDate,
                        endTime: shiftTimes['endTime']!,
                      );
                      
                      // Add event and close dialog
                      await EventService.addEvent(event);
                      Navigator.of(dialogContext).pop();
                      
                      // Sync to Google if enabled
                      _checkAndSyncToGoogleCalendar(event, context);
                      
                      // Force UI refresh immediately after adding an event
                      if (mounted) {
                        // Reload events directly to ensure we have the latest data
                        _events = await EventService.loadEvents();
                        
                        // Update state to show the new event immediately
                        this.setState(() {});
                      }
                    },
                child: const Text('Add Shift'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Get shift times from CSV file
  Future<Map<String, dynamic>> _getShiftTimes(String zone, String shiftNumber, DateTime shiftDate) async {
    print('Getting shift times for zone: $zone, shift: $shiftNumber, date: $shiftDate');
    
    // Get the appropriate CSV file using RosterService
    final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
    final zoneNumber = zone.replaceAll("Zone ", "");
    final csvPath = 'assets/${RosterService.getShiftFilename(zoneNumber, dayOfWeek, shiftDate)}';
    print('Loading CSV file: $csvPath');

    try {
      final csv = await rootBundle.loadString(csvPath);
      final lines = csv.split('\n');
      
      // Skip header row
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(',');
        if (parts.length < 15) continue;
        
        // Get the shift code from the CSV (format: PZ1/01)
        final csvShiftCode = parts[0].trim();
        print('Comparing CSV shift code: $csvShiftCode with event shift: $shiftNumber');
        
        // Normalize both codes for comparison
        final normalizedCsvCode = csvShiftCode.replaceAll('PZ', '').replaceAll('/', '');
        final normalizedEventCode = shiftNumber.replaceAll('PZ', '').replaceAll('/', '');
        print('Normalized codes - CSV: $normalizedCsvCode, Event: $normalizedEventCode');
        
        if (normalizedCsvCode == normalizedEventCode) {
          print('Found matching shift code');
          final shiftData = ShiftData(
            shift: parts[0],
            duty: parts[1],
            report: parts[2],
            depart: parts[3],
            location: parts[4],
            startBreak: parts[5],
            startBreakLocation: parts[6],
            breakReport: parts[7],
            finishBreak: parts[8],
            finishBreakLocation: parts[9],
            finish: parts[10],
            finishLocation: parts[11],
            signOff: parts[12],
            spread: parts[13],
            work: parts[14],
            relief: parts.length > 15 ? parts[15] : '',
          );
          
          // Parse report and sign-off times
          final reportTime = shiftData.report.split(':');
          final signOffTime = shiftData.signOff.split(':');
          
          // Use null-safe parsing with default values
          final startHour = int.tryParse(reportTime[0]) ?? 9;
          final startMinute = int.tryParse(reportTime[1]) ?? 0;
          final endHour = int.tryParse(signOffTime[0]) ?? 17;
          final endMinute = int.tryParse(signOffTime[1]) ?? 0;
          
          // Check if end time is on next day
          final isNextDay = endHour < startHour || (endHour == startHour && endMinute < startMinute);
          
          print('Parsed times - Start: $startHour:$startMinute, End: $endHour:$endMinute, Next Day: $isNextDay');
          
          return {
            'startTime': TimeOfDay(hour: startHour, minute: startMinute),
            'endTime': TimeOfDay(hour: endHour, minute: endMinute),
            'isNextDay': isNextDay,
          };
        }
      }
    } catch (e) {
      print('Error loading CSV file: $e');
    }
    
    // Default times if no match found
    print('No matching shift found, using default times');
    return {
      'startTime': const TimeOfDay(hour: 9, minute: 0),
      'endTime': const TimeOfDay(hour: 17, minute: 0),
      'isNextDay': false,
    };
  }

  // Helper to check settings and sync to Google Calendar if enabled
  Future<void> _checkAndSyncToGoogleCalendar(Event event, BuildContext context) async {
    // Check if Google Calendar sync is enabled
    final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
    final isSignedIn = await GoogleCalendarService.isSignedIn();
    
    // print('[Sync Debug] Checking sync for event: ${event.title} on ${event.startDate.toIso8601String()}'); // Debug -- Removed
    
    if (syncEnabled && isSignedIn) {
      // print('[Sync Debug] Sync enabled and user signed in.'); // Debug -- Removed
      try {
        // Convert to full DateTime objects for Google Calendar
        final startDateTime = DateTime(
          event.startDate.year, 
          event.startDate.month, 
          event.startDate.day,
          event.startTime.hour,
          event.startTime.minute,
        );
        
        final endDateTime = DateTime(
          event.endDate.year, 
          event.endDate.month, 
          event.endDate.day,
          event.endTime.hour,
          event.endTime.minute,
        );

        // Get break information
        final breakTime = await ShiftService.getBreakTime(event);
        final breakStartTime = event.breakStartTime;
        final breakEndTime = event.breakEndTime;
        
        // Build description with all break information
        String description = ''; // Initialize as empty string
        if (breakTime != null) {
          description = 'Break: $breakTime';
          if (breakStartTime != null && breakEndTime != null) {
            // Ensure context is still valid before using it
            if (context.mounted) {
              description += '\nBreak Time: ${breakStartTime.format(context)} - ${breakEndTime.format(context)}';
            }
          }
        }
        
        // print('[Sync Debug] Initial description: "$description"'); // Debug -- Removed
        
        // Check if it's a rest day using RosterService
        // final normalizedDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day); // Not needed anymore
        // final bool isRest = RestDaysService.isRestDay(normalizedDate); // Replaced with RosterService check
        final String shiftType = getShiftForDate(event.startDate); // Use existing screen method
        final bool isRest = shiftType == 'R';
        // print('[Sync Debug] Is Rest Day based on Roster ($shiftType)? $isRest'); // Updated Debug -- Removed
        
        if (isRest) {
          // print('[Sync Debug] Appending rest day info.'); // Debug -- Removed
          if (description.isNotEmpty) {
            description += '\n(Working on Rest Day)';
          } else {
            description = '(Working on Rest Day)';
          }
        }
        
        // print('[Sync Debug] Final description before check: "$description"'); // Debug -- Removed
        
        // Handle case where description might still be empty
        final finalDescription = description.isEmpty ? null : description;
        
        // print('[Sync Debug] Final description passed to helper: "$finalDescription"'); // Debug -- Removed
        
        // Add to Google Calendar
        final success = await CalendarTestHelper.addWorkShiftToCalendar(
          context: context,
          title: event.title,
          startTime: startDateTime,
          endTime: endDateTime,
          description: finalDescription, // Use the updated description
        );
        
        // Ensure context is still valid before showing SnackBar
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shift added to Google Calendar')),
          );
        }
      } catch (e) {
        print('Error adding to Google Calendar: $e');
        // Don't show error - the local event was added successfully
      }
    }
  }

  void _editEvent(Event event) {
    // If this is a refresh trigger, just refresh the UI
    if (event.id == 'refresh_trigger') {
      setState(() {});
      return;
    }

    // Show a dialog to edit or delete the event
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text('${DateFormat('EEE, MMM d').format(event.startDate)} ${event.formattedStartTime} - ${event.formattedEndTime}'),
              const SizedBox(height: 8),
              const Text('What would you like to do with this event?'),
              const SizedBox(height: 8),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Add View Board button for Zone 3 duties
                  if (event.title.contains('PZ3') || event.title.contains('Zone 3'))
                    TextButton(
                      onPressed: () async {
                        // Extract duty number from the title
                        // Handles both formats:
                        // 1. Regular duties: PZ3/01 to PZ3/10 (two digits)
                        // 2. Bogey duties: PZ3/1X to PZ3/2X (translates to 351-352)
                        final dutyMatch = RegExp(r'PZ3/(\d{1,2})').firstMatch(event.title);
                        if (dutyMatch != null) {
                          String dutyNumber = dutyMatch.group(1)!;
                          
                          // Convert duty numbers to their actual numbers
                          if (dutyNumber.length == 1) {
                            // If it's a single digit (1 or 2), it's a bogey duty
                            dutyNumber = '35${dutyNumber}';
                          } else {
                            // For two-digit numbers (01-10), prepend 3 to make it 301-310
                            dutyNumber = '3${dutyNumber}';
                          }
                          
                          // Load board entries
                          final entries = await BoardService.loadBoardEntries(dutyNumber, event.startDate);
                          
                          // Close the edit dialog
                          Navigator.of(context).pop();
                          
                          // Show the board dialog
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => ViewBoardDialog(
                                entries: entries,
                                dutyNumber: dutyNumber,
                                weekday: event.startDate.weekday,
                                isBankHoliday: ShiftService.getBankHoliday(event.startDate, ShiftService.bankHolidays) != null,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('View Board'),
                    ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      // First close the dialog to make the UI responsive
                      Navigator.of(context).pop();
                      
                      // Show a loading indicator that can be dismissed
                      final snackBar = SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Deleting event...'),
                          ],
                        ),
                        duration: const Duration(seconds: 3),
                      );
                      
                      // Show the loading snackbar
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      
                      // Delete the event from local storage
                      await EventService.deleteEvent(event);
                      
                      // Check if Google Calendar sync is enabled and delete from Google Calendar
                      final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
                      final isSignedIn = await GoogleCalendarService.isSignedIn();
                      
                      if (syncEnabled && isSignedIn) {
                        try {
                          // Create a full DateTime for the event's start time
                          final startDateTime = DateTime(
                            event.startDate.year,
                            event.startDate.month,
                            event.startDate.day,
                            event.startTime.hour,
                            event.startTime.minute,
                          );
                          
                          // Delete from Google Calendar
                          await CalendarTestHelper.deleteEventFromCalendar(
                            context: context,
                            title: event.title,
                            eventStartTime: startDateTime,
                          );
                        } catch (e) {
                          print('Error deleting from Google Calendar: $e');
                          // Don't show error - the local event was deleted successfully
                        }
                      }
                      
                      // Update the UI state immediately after local deletion
                      setState(() {});
                      
                      // Hide the loading indicator immediately after local deletion is complete
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      
                      // Show confirmation of successful local deletion
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Event deleted'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Add a divider before the bus selection section
              if (event.isWorkShift) ...[
                const Divider(),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_bus, size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Bus Assignment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (event.firstHalfBus != null || event.secondHalfBus != null) ...[
                        if (event.firstHalfBus != null)
                          FutureBuilder<String?>(
                            future: ShiftService.getBreakTime(event),
                            builder: (context, snapshot) {
                              final isWorkout = snapshot.data?.toLowerCase().contains('workout') ?? false;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isWorkout ? 'Assigned Bus: ${event.firstHalfBus}' : 'First Half: ${event.firstHalfBus}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                      onPressed: () async {
                                        // Create a copy of the old event
                                        final oldEvent = Event(
                                          id: event.id,
                                          title: event.title,
                                          startDate: event.startDate,
                                          startTime: event.startTime,
                                          endDate: event.endDate,
                                          endTime: event.endTime,
                                          workTime: event.workTime,
                                          breakStartTime: event.breakStartTime,
                                          breakEndTime: event.breakEndTime,
                                          assignedDuties: event.assignedDuties,
                                          firstHalfBus: event.firstHalfBus,
                                          secondHalfBus: event.secondHalfBus,
                                        );
                                        
                                        // Create a new event with the updated bus
                                        final updatedEvent = Event(
                                          id: event.id,
                                          title: event.title,
                                          startDate: event.startDate,
                                          startTime: event.startTime,
                                          endDate: event.endDate,
                                          endTime: event.endTime,
                                          workTime: event.workTime,
                                          breakStartTime: event.breakStartTime,
                                          breakEndTime: event.breakEndTime,
                                          assignedDuties: event.assignedDuties,
                                          firstHalfBus: null, // Remove first half bus
                                          secondHalfBus: event.secondHalfBus,
                                        );
                                        
                                        // Save the updated event
                                        await EventService.updateEvent(oldEvent, updatedEvent);
                                        
                                        // Refresh the UI
                                        if (mounted) {
                                          setState(() {});
                                          // Close the current dialog
                                          Navigator.of(context).pop();
                                          // Reopen the dialog with the updated event
                                          _editEvent(updatedEvent);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        if (event.firstHalfBus != null && event.secondHalfBus != null)
                          const SizedBox(height: 4),
                        if (event.secondHalfBus != null)
                          FutureBuilder<String?>(
                            future: ShiftService.getBreakTime(event),
                            builder: (context, snapshot) {
                              final isWorkout = snapshot.data?.toLowerCase().contains('workout') ?? false;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isWorkout ? 'Assigned Bus: ${event.secondHalfBus}' : 'Second Half: ${event.secondHalfBus}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                      onPressed: () async {
                                        // Create a copy of the old event
                                        final oldEvent = Event(
                                          id: event.id,
                                          title: event.title,
                                          startDate: event.startDate,
                                          startTime: event.startTime,
                                          endDate: event.endDate,
                                          endTime: event.endTime,
                                          workTime: event.workTime,
                                          breakStartTime: event.breakStartTime,
                                          breakEndTime: event.breakEndTime,
                                          assignedDuties: event.assignedDuties,
                                          firstHalfBus: event.firstHalfBus,
                                          secondHalfBus: event.secondHalfBus,
                                        );
                                        
                                        // Create a new event with the updated bus
                                        final updatedEvent = Event(
                                          id: event.id,
                                          title: event.title,
                                          startDate: event.startDate,
                                          startTime: event.startTime,
                                          endDate: event.endDate,
                                          endTime: event.endTime,
                                          workTime: event.workTime,
                                          breakStartTime: event.breakStartTime,
                                          breakEndTime: event.breakEndTime,
                                          assignedDuties: event.assignedDuties,
                                          firstHalfBus: event.firstHalfBus,
                                          secondHalfBus: null, // Remove second half bus
                                        );
                                        
                                        // Save the updated event
                                        await EventService.updateEvent(oldEvent, updatedEvent);
                                        
                                        // Refresh the UI
                                        if (mounted) {
                                          setState(() {});
                                          // Close the current dialog
                                          Navigator.of(context).pop();
                                          // Reopen the dialog with the updated event
                                          _editEvent(updatedEvent);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 4),
                      ],
                      FutureBuilder<String?>(
                        future: ShiftService.getBreakTime(event),
                        builder: (context, snapshot) {
                          final isWorkout = snapshot.data?.toLowerCase().contains('workout') ?? false;
                          
                          if (isWorkout) {
                            // Single button for workout shifts - only show if no bus is assigned
                            if (event.firstHalfBus == null) {
                              return ElevatedButton(
                                onPressed: () async {
                                  // Show the bus assignment dialog
                                  final TextEditingController controller = TextEditingController();
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Add Bus'),
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
                                          onPressed: () {
                                            String busNumber = controller.text.trim().toUpperCase();
                                            busNumber = busNumber.replaceAll(' ', '');
                                            if (busNumber.isNotEmpty) {
                                              Navigator.of(context).pop(busNumber);
                                            }
                                          },
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (result != null) {
                                    // Create a new event with the updated bus number
                                    final updatedEvent = Event(
                                      id: event.id,
                                      title: event.title,
                                      startDate: event.startDate,
                                      startTime: event.startTime,
                                      endDate: event.endDate,
                                      endTime: event.endTime,
                                      workTime: event.workTime,
                                      breakStartTime: event.breakStartTime,
                                      breakEndTime: event.breakEndTime,
                                      assignedDuties: event.assignedDuties,
                                      firstHalfBus: result,
                                      secondHalfBus: event.secondHalfBus,
                                    );
                                    
                                    // Save the updated event
                                    await EventService.updateEvent(event, updatedEvent);
                                    
                                    // Refresh the UI
                                    if (mounted) {
                                      setState(() {});
                                      // Close the current dialog
                                      Navigator.of(context).pop();
                                      // Reopen the dialog with the updated event
                                      _editEvent(updatedEvent);
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.directions_bus, size: 18),
                                      SizedBox(width: 8),
                                      Text('Add Bus'),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink(); // Return empty widget if bus is already assigned
                          } else {
                            // Two buttons for regular shifts
                            return Row(
                              children: [
                                if (event.firstHalfBus == null)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // Create a copy of the old event
                                        final oldEvent = Event(
                                          id: event.id,
                                          title: event.title,
                                          startDate: event.startDate,
                                          startTime: event.startTime,
                                          endDate: event.endDate,
                                          endTime: event.endTime,
                                          workTime: event.workTime,
                                          breakStartTime: event.breakStartTime,
                                          breakEndTime: event.breakEndTime,
                                          assignedDuties: event.assignedDuties,
                                          firstHalfBus: event.firstHalfBus,
                                          secondHalfBus: event.secondHalfBus,
                                        );
                                        
                                        // Show the bus assignment dialog
                                        final TextEditingController controller = TextEditingController();
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Add First Half Bus'),
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
                                                onPressed: () {
                                                  String busNumber = controller.text.trim().toUpperCase();
                                                  busNumber = busNumber.replaceAll(' ', '');
                                                  if (busNumber.isNotEmpty) {
                                                    Navigator.of(context).pop(busNumber);
                                                  }
                                                },
                                                child: const Text('Add'),
                                              ),
                                            ],
                                          ),
                                        );
                                        
                                        if (result != null) {
                                          // Create a new event with the updated bus number
                                          final updatedEvent = Event(
                                            id: event.id,
                                            title: event.title,
                                            startDate: event.startDate,
                                            startTime: event.startTime,
                                            endDate: event.endDate,
                                            endTime: event.endTime,
                                            workTime: event.workTime,
                                            breakStartTime: event.breakStartTime,
                                            breakEndTime: event.breakEndTime,
                                            assignedDuties: event.assignedDuties,
                                            firstHalfBus: result,
                                            secondHalfBus: event.secondHalfBus,
                                          );
                                          
                                          // Save the updated event
                                          await EventService.updateEvent(oldEvent, updatedEvent);
                                          
                                          // Refresh the UI
                                          if (mounted) {
                                            setState(() {});
                                            // Close the current dialog
                                            Navigator.of(context).pop();
                                            // Reopen the dialog with the updated event
                                            _editEvent(updatedEvent);
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        minimumSize: const Size(0, 48),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.directions_bus, size: 18),
                                            SizedBox(width: 8),
                                            Text('1st Half'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (event.firstHalfBus == null && event.secondHalfBus == null)
                                  const SizedBox(width: 8),
                                if (event.secondHalfBus == null)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // Create a copy of the old event
                                        final oldEvent = Event(
                                          id: event.id,
                                          title: event.title,
                                          startDate: event.startDate,
                                          startTime: event.startTime,
                                          endDate: event.endDate,
                                          endTime: event.endTime,
                                          workTime: event.workTime,
                                          breakStartTime: event.breakStartTime,
                                          breakEndTime: event.breakEndTime,
                                          assignedDuties: event.assignedDuties,
                                          firstHalfBus: event.firstHalfBus,
                                          secondHalfBus: event.secondHalfBus,
                                        );
                                        
                                        // Show the bus assignment dialog
                                        final TextEditingController controller = TextEditingController();
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Add Second Half Bus'),
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
                                                onPressed: () {
                                                  String busNumber = controller.text.trim().toUpperCase();
                                                  busNumber = busNumber.replaceAll(' ', '');
                                                  if (busNumber.isNotEmpty) {
                                                    Navigator.of(context).pop(busNumber);
                                                  }
                                                },
                                                child: const Text('Add'),
                                              ),
                                            ],
                                          ),
                                        );
                                        
                                        if (result != null) {
                                          // Create a new event with the updated bus number
                                          final updatedEvent = Event(
                                            id: event.id,
                                            title: event.title,
                                            startDate: event.startDate,
                                            startTime: event.startTime,
                                            endDate: event.endDate,
                                            endTime: event.endTime,
                                            workTime: event.workTime,
                                            breakStartTime: event.breakStartTime,
                                            breakEndTime: event.breakEndTime,
                                            assignedDuties: event.assignedDuties,
                                            firstHalfBus: event.firstHalfBus,
                                            secondHalfBus: result,
                                          );
                                          
                                          // Save the updated event
                                          await EventService.updateEvent(oldEvent, updatedEvent);
                                          
                                          // Refresh the UI
                                          if (mounted) {
                                            setState(() {});
                                            // Close the current dialog
                                            Navigator.of(context).pop();
                                            // Reopen the dialog with the updated event
                                            _editEvent(updatedEvent);
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        minimumSize: const Size(0, 48),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.directions_bus, size: 18),
                                            SizedBox(width: 8),
                                            Text('2nd Half'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              // Cancel button at the bottom
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spare Driver Shift Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.settings),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'about',
                child: Text('About'),
              ),
              PopupMenuItem(
                value: 'statistics',
                child: Text('Statistics'),
              ),
              PopupMenuItem(
                value: 'add_holidays',
                child: Text('Holidays'),
              ),
              PopupMenuItem(
                value: 'contacts',
                child: Text('Contacts'),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
            onSelected: (value) {
              if (value == 'statistics') {
                _showStatisticsPage();
              } else if (value == 'about') {
                _showAboutPage();
              } else if (value == 'settings') {
                _showSettingsPage();
              } else if (value == 'add_holidays') {
                _showAddHolidaysDialog();
              } else if (value == 'contacts') { // Add this condition
                _showContactsPage();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TableCalendar stays fixed at the top
            _buildCalendar(),
            // The rest of the content becomes scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    if (_selectedDay != null && _startDate != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ShiftDetailsCard(
                          date: _selectedDay!,
                          shift: getShiftForDate(_selectedDay!),
                          shiftInfoMap: _shiftInfoMap,
                          bankHoliday: getBankHoliday(_selectedDay!),
                        ),
                      ),
                    if (_selectedDay != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildEventsList(),
                      ),
                    // Add some padding at the bottom to ensure the last item is fully visible
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        // Add custom header with clickable month/year title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                      _focusedDay.day,
                    );
                  });
                },
              ),
              GestureDetector(
                onTap: _showMonthYearPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('  MMMM yyyy').format(_focusedDay),
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                      _focusedDay.day,
                    );
                  });
                },
              ),
            ],
          ),
        ),
        // The TableCalendar with headerVisible: false to hide the default header
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          headerVisible: false, // Hide default header since we're using our custom one above
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          eventLoader: getEventsForDay,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: true,
            markersMaxCount: 0,
            markersAnchor: 1.0,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, _) {
              return _buildCalendarDay(date, isToday: false);
            },
            todayBuilder: (context, date, _) {
              return _buildCalendarDay(date, isToday: true);
            },
            markerBuilder: (context, date, events) {
              return null;
            },
          ),
        ),
      ],
    );
  }

  // Add this new method to show month/year picker
  void _showMonthYearPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Month',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Year selector with better styling
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showMonthYearPickerForYear(_focusedDay.year - 1);
                        },
                        tooltip: 'Previous Year',
                        splashRadius: 24,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _focusedDay.year.toString(),
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showMonthYearPickerForYear(_focusedDay.year + 1);
                        },
                        tooltip: 'Next Year',
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Months grid with improved styling - more compact and tidier
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,  // Changed from 3 to 4 columns
                    childAspectRatio: 2.0,  // Wider than tall for a better look
                    crossAxisSpacing: 8,  // Reduced spacing
                    mainAxisSpacing: 8,   // Reduced spacing
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == _focusedDay.month;
                    final monthName = DateFormat('MMM').format(DateTime(2022, month));
                    
                    return Material( // Added Material for better ink effect
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              month,
                              1,
                            );
                          });
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              )
                            ] : null,
                          ),
                          child: Center(
                            child: Text(
                              monthName,
                              style: TextStyle(
                                fontSize: 14,  // Slightly reduced font size
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8), // Added a bit of bottom padding
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Helper method for showing picker with specific year
  void _showMonthYearPickerForYear(int year) {
    setState(() {
      _focusedDay = DateTime(year, _focusedDay.month, 1);
    });
    _showMonthYearPicker();
  }

  Widget _buildCalendarDay(DateTime date, {required bool isToday}) {
    final shift = _startDate != null ? getShiftForDate(date) : '';
    final shiftInfo = _shiftInfoMap[shift];
    final hasEvents = getEventsForDay(date).isNotEmpty;
    final bankHoliday = getBankHoliday(date);
    final isBankHoliday = bankHoliday != null;
    final isHoliday = _holidays.any((h) => h.containsDate(date));

    return Container(
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isHoliday 
            ? holidayColor.withOpacity(0.3)
            : shiftInfo?.color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.0),
        border: isToday
            ? Border.all(
                color: isBankHoliday ? Colors.red : Colors.blue,
                width: 2,
              )
            : isBankHoliday
                ? Border.all(
                    color: Colors.red,
                    width: 1.5,
                  )
                : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${date.day}'),
          if (shift.isNotEmpty && !isHoliday)
            Text(
              shift,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (isHoliday)
            const Text(
              'H',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (hasEvents)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isHoliday 
                    ? holidayColor 
                    : (shiftInfo?.color ?? Theme.of(context).primaryColor),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final events = getEventsForDay(_selectedDay!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Events (${events.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: Colors.blue,
                onPressed: _showAddEventDialog,
              ),
            ],
          ),
        ),
        events.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No events for ${DateFormat('EEEE, MMMM d').format(_selectedDay!)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            : Column(
                children: events.map((event) => EventCard(
                  event: event,
                  shiftType: getShiftForDate(event.startDate),
                  shiftInfoMap: _shiftInfoMap,
                  isBankHoliday: getBankHoliday(event.startDate) != null,
                  isRestDay: getShiftForDate(event.startDate) == 'R',
                  onEdit: _editEvent,
                )).toList(),
              ),
      ],
    );
  }

  void _showStatisticsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatisticsScreen(
          events: _events,
        ),
      ),
    );
  }
  
  void _showAboutPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  void _showSettingsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          resetRestDaysCallback: _showFirstRunDialog,
          isDarkModeNotifier: widget.isDarkModeNotifier,
        ),
      ),
    );
  }

  void _showAddHolidaysDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Add Holidays',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Existing holidays section
                          if (_holidays.isNotEmpty) ...[
                            const Text(
                              'Existing Holidays',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _holidays.length,
                                itemBuilder: (context, index) {
                                  final holiday = _holidays[index];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        holiday.type == 'winter' ? Icons.ac_unit : 
                                        holiday.type == 'summer' ? Icons.wb_sunny :
                                        Icons.event,
                                        color: holidayColor,
                                      ),
                                      title: Text(
                                        holiday.type == 'winter' ? 'Winter Holiday' : 
                                        holiday.type == 'summer' ? 'Summer Holiday' :
                                        'Other Holiday',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        holiday.startDate == holiday.endDate
                                            ? DateFormat('MMM d').format(holiday.startDate)
                                            : '${DateFormat('MMM d').format(holiday.startDate)} - ${DateFormat('MMM d').format(holiday.endDate)}',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () async {
                                          // Show confirmation dialog
                                          final shouldDelete = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Remove Holiday'),
                                              content: const Text('Are you sure you want to remove this holiday?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Remove'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (shouldDelete == true) {
                                            // Remove the holiday
                                            await HolidayService.removeHoliday(holiday.id);
                                            
                                            // Update the holidays list
                                            setState(() {
                                              _holidays.removeWhere((h) => h.id == holiday.id);
                                            });
                                            
                                            // Show success message
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Holiday removed successfully'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              
                                              // Force a rebuild of the calendar to update holiday indicators
                                              _updateAllEvents();
                                              
                                              // Close and reopen the dialog to refresh the view
                                              Navigator.of(context).pop();
                                              _showAddHolidaysDialog();
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],
                          // Add new holiday section
                          const Text(
                            'Add New Holiday',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.wb_sunny),
                            title: const Text('Summer (2 Weeks)'),
                            onTap: () {
                              Navigator.of(context).pop(); // Close the current dialog
                              _showSummerHolidayDateDialog();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.ac_unit),
                            title: const Text('Winter (1 Week)'),
                            onTap: () {
                              Navigator.of(context).pop(); // Close the current dialog
                              _showWinterHolidayDateDialog();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.event),
                            title: const Text('Other'),
                            onTap: () {
                              Navigator.of(context).pop(); // Close the current dialog
                              _showOtherHolidayDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 0),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWinterHolidayDateDialog() {
    // Get the current date
    final now = DateTime.now();
    // Get the first day of the current year
    final firstDayOfYear = DateTime(now.year, 1, 1);
    // Get the last day of the current year
    final lastDayOfYear = DateTime(now.year, 12, 31);
    
    // Find the first Sunday of the year
    var firstSunday = firstDayOfYear;
    while (firstSunday.weekday != DateTime.sunday) {
      firstSunday = firstSunday.add(const Duration(days: 1));
    }
    
    // Create a list of all Sundays in the year
    final sundays = <DateTime>[];
    var currentSunday = firstSunday;
    
    while (currentSunday.isBefore(lastDayOfYear)) {
      sundays.add(currentSunday);
      currentSunday = currentSunday.add(const Duration(days: 7));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.ac_unit, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              const Text('Select Winter Holiday Start Date'),
            ],
          ),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sundays.length,
                    itemBuilder: (context, index) {
                      final date = sundays[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              // Create a new holiday starting on the selected Sunday
                              final holiday = Holiday(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                startDate: date,
                                endDate: date.add(const Duration(days: 6)), // End on Saturday
                                type: 'winter',
                              );
                              
                              // Add the holiday
                              await HolidayService.addHoliday(holiday);
                              
                              // Update the holidays list
                              setState(() {
                                _holidays.add(holiday);
                              });
                              
                              // Close the dialog
                              Navigator.of(context).pop();
                              
                              // Show success message
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Winter holiday added successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Sun',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('MMM d, yyyy').format(date),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.blue.shade300,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Scroll to see more dates',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: 8),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showSummerHolidayDateDialog() {
    // Get the current date
    final now = DateTime.now();
    // Get the first day of the current year
    final firstDayOfYear = DateTime(now.year, 1, 1);
    // Get the last day of the current year
    final lastDayOfYear = DateTime(now.year, 12, 31);
    
    // Find the first Sunday of the year
    var firstSunday = firstDayOfYear;
    while (firstSunday.weekday != DateTime.sunday) {
      firstSunday = firstSunday.add(const Duration(days: 1));
    }
    
    // Create a list of all Sundays in the year
    final sundays = <DateTime>[];
    var currentSunday = firstSunday;
    
    while (currentSunday.isBefore(lastDayOfYear)) {
      sundays.add(currentSunday);
      currentSunday = currentSunday.add(const Duration(days: 7));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wb_sunny, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Select Summer Holiday Start Date'),
            ],
          ),
          contentPadding: const EdgeInsets.only(top: 8, bottom: 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sundays.length,
                    itemBuilder: (context, index) {
                      final date = sundays[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.shade100,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              // Create a new holiday starting on the selected Sunday
                              final holiday = Holiday(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                startDate: date,
                                endDate: date.add(const Duration(days: 13)), // End on Saturday (2 weeks)
                                type: 'summer',
                              );
                              
                              // Add the holiday
                              await HolidayService.addHoliday(holiday);
                              
                              // Update the holidays list
                              setState(() {
                                _holidays.add(holiday);
                              });
                              
                              // Close the dialog
                              Navigator.of(context).pop();
                              
                              // Show success message
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Summer holiday added successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Sun',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('MMM d, yyyy').format(date),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'Ends: ${DateFormat('MMM d, yyyy').format(date.add(const Duration(days: 13)))}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.orange.shade300,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Scroll to see more dates',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: 8),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Add this new function to update all events
  Future<void> _updateAllEvents() async {
    try {
      // Load existing events
      _events = await EventService.loadEvents();
      
      setState(() {});
    } catch (e) {
      print('Error updating events: $e');
    }
  }

  void _showHolidayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Holiday'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.ac_unit, color: Colors.blue),
              title: const Text('Winter Holiday'),
              subtitle: const Text('Add a week of winter holiday'),
              onTap: () {
                Navigator.pop(context);
                _showWinterHolidayDateDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny, color: Colors.orange),
              title: const Text('Summer Holiday'),
              subtitle: const Text('Add two weeks of summer holiday'),
              onTap: () {
                Navigator.pop(context);
                _showSummerHolidayDateDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.event, color: Colors.green),
              title: const Text('Other Holiday'),
              subtitle: const Text('Add a single day holiday'),
              onTap: () {
                Navigator.pop(context);
                _showOtherHolidayDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showOtherHolidayDialog() {
    DateTime selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Holiday Date',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (date) {
                        selectedDate = date;
                      },
                    ),
                  ),
                ),
              ),
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final holiday = Holiday(
                          id: 'other_${selectedDate.millisecondsSinceEpoch}',
                          startDate: selectedDate,
                          endDate: selectedDate,
                          type: 'other',
                        );
                        
                        // Add the holiday
                        await HolidayService.addHoliday(holiday);
                        
                        // Update the holidays list
                        setState(() {
                          _holidays.add(holiday);
                        });
                        
                        // Close the dialog
                        Navigator.of(context).pop();
                        
                        // Show success message
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Holiday added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Add Holiday'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addHoliday(Holiday holiday) {
    setState(() {
      _holidays.add(holiday);
    });
    _saveHolidays();
  }

  void _removeHoliday(Holiday holiday) {
    setState(() {
      _holidays.removeWhere((h) => h.id == holiday.id);
    });
    _saveHolidays();
  }

  void _saveHolidays() {
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      final holidaysJson = _holidays.map((h) => h.toJson()).toList();
      prefs.setString('holidays', jsonEncode(holidaysJson));
    });
  }

  void _loadHolidays() {
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      final holidaysJson = prefs.getString('holidays');
      if (holidaysJson != null) {
        final List<dynamic> decoded = jsonDecode(holidaysJson);
        setState(() {
          _holidays = decoded.map((json) => Holiday.fromJson(json)).toList();
        });
      }
    });
  }

  void _showContactsPage() { // Add this method
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ContactsPage(),
      ),
    );
  }
}
