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
import 'package:spdrivercalendar/core/services/cache_service.dart'; // Added import
import 'package:spdrivercalendar/features/notes/screens/all_notes_screen.dart'; // Import the new screen

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
  int _selectedYear = DateTime.now().year; // Add this line
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
    super.initState();
    _selectedDay = DateTime.now();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize with current month's events with error handling
    _initializeCurrentMonth().catchError((error) {
      print('Error initializing current month: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading calendar data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _initializeCurrentMonth() async {
    try {
      final cacheService = CacheService();
      
      // Run independent data loading in parallel with error handling
      final results = await Future.wait([
        RestDaysService.initialize(),
        _loadBankHolidays(cacheService),
        _loadHolidaysWithCache(cacheService),
        _loadSettings(),
      ], eagerError: true);

      if (mounted) {
        setState(() {
          _bankHolidays = results[1] as List<BankHoliday>;
          _holidays = results[2] as List<Holiday>;
        });
      }

      // Preload current month's events
      await EventService.preloadMonth(DateTime.now());
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<List<BankHoliday>> _loadBankHolidays(CacheService cacheService) async {
    const cacheKey = 'bank_holidays';
    
    // Try to get from cache first
    final cached = cacheService.get<List<BankHoliday>>(cacheKey);
    if (cached != null) return cached;
    
    // If not in cache, load from service
    final holidays = await RosterService.loadBankHolidays();
    
    // Cache the results for 24 hours
    cacheService.set(cacheKey, holidays, expiration: const Duration(hours: 24));
    
    return holidays;
  }

  Future<List<Holiday>> _loadHolidaysWithCache(CacheService cacheService) async {
    const cacheKey = 'holidays';
    
    // Try to get from cache first
    final cached = cacheService.get<List<Holiday>>(cacheKey);
    if (cached != null) return cached;
    
    // If not in cache, load from service
    final holidays = await HolidayService.getHolidays();
    
    // Cache the results for 24 hours
    cacheService.set(cacheKey, holidays, expiration: const Duration(hours: 24));
    
    return holidays;
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

  // Define the missing method
  void _resetRestDays() {
    _showFirstRunDialog(); // Show the dialog to re-select rest days
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
              
              // Convert full day name to abbreviated format for file loading
              String dayOfWeekForFilename;
              if (dayOfWeek == 'Saturday') {
                dayOfWeekForFilename = 'SAT';
              } else if (dayOfWeek == 'Sunday') {
                dayOfWeekForFilename = 'SUN';
              } else {
                dayOfWeekForFilename = 'M-F';
              }
              
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
              } else if (selectedZone == 'Bus Check') { // ADDED: Handle Bus Check zone
                try {
                  final csv = await rootBundle.loadString('assets/buscheck.csv');
                  final lines = csv.split('\n');
                  shiftNumbers = [];
                  final seenShifts = <String>{};
                  String currentDayType = ''; // Map RosterService output to CSV values

                  // Determine day type string for CSV matching
                  // RosterService treats Bank Holidays as Sunday
                  if (dayOfWeek == 'Saturday') {
                    currentDayType = 'SAT';
                  } else if (dayOfWeek == 'Sunday') {
                    currentDayType = 'SUN';
                  } else { // Monday - Friday
                    currentDayType = 'MF'; 
                  }

                  // Skip the header line (first line)
                  for (int i = 1; i < lines.length; i++) {
                    final line = lines[i].trim().replaceAll('\r', '');
                    if (line.isEmpty) continue;
                    final parts = line.split(',');
                    // Expecting format: duty,day,start,finish
                    if (parts.length >= 2) {
                      final shiftName = parts[0].trim();
                      final shiftDayType = parts[1].trim();

                      // Add shift if day type matches and it's not already added
                      if (shiftDayType == currentDayType && shiftName.isNotEmpty && !seenShifts.contains(shiftName)) {
                        seenShifts.add(shiftName);
                        shiftNumbers.add(shiftName);
                      }
                    }
                  }
                } catch (e) {
                  shiftNumbers = [];
                  print('Error loading shifts for Bus Check: $e');
                }
              } else {
                // Regular zone shifts - preserve CSV file order
                final filename = RosterService.getShiftFilename(zoneNumber, dayOfWeekForFilename, shiftDate);
                
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
                  items: ['Zone 1', 'Zone 3', 'Zone 4', 'Spare', 'Uni/Euro', 'Bus Check'].map((zone) {
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
                      } else if (selectedZone == 'Bus Check') { // ADDED: Set title for Bus Check
                        title = selectedShiftNumber; // Use the selected duty name (e.g., BusCheck1)
                      } else {
                        // Regular PZ shifts
                        title = selectedShiftNumber; // Title is the shift code (e.g., PZ1/01)
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
                      
                      // Handle potential null shiftTimes (error loading CSV etc.)
                      if (shiftTimes == null) {
                         print('Error: Could not retrieve shift times for $selectedZone - $selectedShiftNumber');
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Error retrieving shift times. Please try again.')),
                          );
                         return; // Stop execution if times are null
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
                        // Preload the current month's events to ensure we have the latest data
                        await EventService.preloadMonth(_focusedDay);
                        
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
  Future<Map<String, dynamic>?> _getShiftTimes(String zone, String shiftNumber, DateTime shiftDate) async { // Return type changed to nullable
    print('Getting shift times for zone: $zone, shift: $shiftNumber, date: $shiftDate');

    // RosterService handles Bank Holidays internally by returning 'Sunday'
    final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
    final zoneNumber = zone.replaceAll("Zone ", "");
    String csvPath;
    String currentDayType = ''; // Day type code used in the specific CSV

    // Convert full day name to abbreviated format for file loading
    String dayOfWeekForFilename;
    if (dayOfWeek == 'Saturday') {
      dayOfWeekForFilename = 'SAT';
    } else if (dayOfWeek == 'Sunday') {
      dayOfWeekForFilename = 'SUN';
    } else {
      dayOfWeekForFilename = 'M-F';
    }

    // Determine the correct CSV path and day type string based on zone
    if (zone == 'Bus Check') {
      csvPath = 'assets/buscheck.csv';
      // Map RosterService output to BusCheck CSV day codes
      if (dayOfWeek == 'Saturday') {
        currentDayType = 'SAT';
      } else if (dayOfWeek == 'Sunday') {
        currentDayType = 'SUN';
      } else { // Monday - Friday
        currentDayType = 'MF'; 
      }
    } else if (zone == 'Uni/Euro') {
      // Uni/Euro logic requires checking multiple files based on day type.
      // We'll handle this directly within the loop for Uni/Euro below.
      // Setting a dummy path here, won't be used directly.
      csvPath = 'assets/UNI_7DAYs.csv'; 
    } else {
      // Regular Zones (1, 3, 4)
      csvPath = 'assets/${RosterService.getShiftFilename(zoneNumber, dayOfWeekForFilename, shiftDate)}';
      // For PZ shifts, we don't need currentDayType as we match shift code directly
    }

    print('Loading CSV(s) for $zone: $csvPath (and potentially others for Uni/Euro)');

    try {
       // --- Handle Uni/Euro Separately (Needs multiple file checks) --- 
       if (zone == 'Uni/Euro') {
         bool isWeekend = dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday';
         List<String> filesToTry = ['assets/UNI_7DAYs.csv'];
         if (!isWeekend) {
             filesToTry.add('assets/UNI_M-F.csv');
         }

         for (final filePath in filesToTry) {
            try {
                final csv = await rootBundle.loadString(filePath);
                final lines = csv.split('\n');
                for (final line in lines) {
                    if (line.trim().isEmpty) continue;
                    final parts = line.split(',');
                    if (parts.length >= 5 && parts[0].trim() == shiftNumber) {
                        print('Found Uni/Euro shift in $filePath');
                        final startTimeRaw = parts[1].trim();
                        final endTimeRaw = parts[4].trim();
                        
                        if (startTimeRaw.isNotEmpty && endTimeRaw.isNotEmpty) {
                          final startTime = _parseTimeOfDay(startTimeRaw);
                          final endTime = _parseTimeOfDay(endTimeRaw);
                          
                          if (startTime != null && endTime != null) {
                              final isNextDay = endTime.hour < startTime.hour || 
                                                (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
                              return {
                                  'startTime': startTime,
                                  'endTime': endTime,
                                  'isNextDay': isNextDay,
                              };
                          } else {
                             print('Error parsing Uni/Euro times: $startTimeRaw, $endTimeRaw');
                          }
                        } else {
                           print('Empty Uni/Euro times found for $shiftNumber in $filePath');
                        }
                    }
                }
            } catch (e) {
                print("Error reading or parsing $filePath: $e");
                // Continue to next file if one fails
            }
         }
         print('Uni/Euro shift $shiftNumber not found in applicable files.');
         return null; // Not found after checking relevant files
       }

       // --- Handle BusCheck and Regular Zones (Single file check) --- 
      final csv = await rootBundle.loadString(csvPath);
      final lines = csv.split('\n');

      // Skip header row
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim().replaceAll('\r', '');
        if (line.isEmpty) continue;

        final parts = line.split(',');

        // === Handle Bus Check CSV format ===
        if (zone == 'Bus Check') {
           // Expecting format: duty,day,start,finish
          if (parts.length >= 4) {
            final csvShiftCode = parts[0].trim();
            final csvDayType = parts[1].trim();
            
            if (csvShiftCode == shiftNumber && csvDayType == currentDayType) {
              print('Found matching Bus Check shift');
              final startTime = _parseTimeOfDay(parts[2].trim());
              final endTime = _parseTimeOfDay(parts[3].trim());

              if (startTime != null && endTime != null) {
                 final isNextDay = endTime.hour < startTime.hour || 
                                   (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
                 print('Parsed Bus Check times - Start: ${startTime.hour}:${startTime.minute}, End: ${endTime.hour}:${endTime.minute}, Next Day: $isNextDay');
                 return {
                   'startTime': startTime,
                   'endTime': endTime,
                   'isNextDay': isNextDay,
                 };
              } else {
                 print('Error parsing Bus Check times for $shiftNumber: ${parts[2]}, ${parts[3]}');
              }
            }
          }
        }
        // === Handle Regular Zone CSV format ===
        else {
          // Expecting PZ format (index 0 is shift, 2 is report, 12 is signOff)
          if (parts.length >= 13) { 
             final csvShiftCode = parts[0].trim();
             // No need to normalize PZ codes if shiftNumber is passed correctly (e.g. PZ1/01)
             if (csvShiftCode == shiftNumber) {
                print('Found matching PZ shift code');
                final startTime = _parseTimeOfDay(parts[2].trim()); // Report time
                final endTime = _parseTimeOfDay(parts[12].trim()); // SignOff time

                if (startTime != null && endTime != null) {
                    final isNextDay = endTime.hour < startTime.hour || 
                                      (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
                    print('Parsed PZ times - Start: ${startTime.hour}:${startTime.minute}, End: ${endTime.hour}:${endTime.minute}, Next Day: $isNextDay');
                    return {
                      'startTime': startTime,
                      'endTime': endTime,
                      'isNextDay': isNextDay,
                    };
                } else {
                   print('Error parsing PZ times for $shiftNumber: ${parts[2]}, ${parts[12]}');
                }
             }
          }
        }
      }
    } catch (e) {
      print('Error loading or parsing CSV file ($csvPath): $e');
       return null; // Return null on error
    }

    // No match found or error occurred
    print('No matching shift found or error occurred for $zone / $shiftNumber, returning null');
    return null; // Return null if no match found
  }
  
  // Helper function to parse HH:MM strings into TimeOfDay
  TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      print("Error parsing time string '$timeString': $e");
    }
    return null;
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

    // --- Format Title for Dialog ---
    String displayTitle = event.title;
    if (event.title.startsWith('BusCheck')) {
      final match = RegExp(r'^BusCheck(\d+)$').firstMatch(event.title);
      if (match != null && match.groupCount >= 1) {
        final numberPart = match.group(1);
        if (numberPart != null) {
           displayTitle = 'Bus Check $numberPart';
        }
      }
    }
    if (displayTitle.isEmpty) displayTitle = 'Untitled Event';
    // --- End Format Title ---

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
                displayTitle, // Use formatted title
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
                            dutyNumber = '35$dutyNumber';
                          } else {
                            // For two-digit numbers (01-10), prepend 3 to make it 301-310
                            dutyNumber = '3$dutyNumber';
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
                    onPressed: () {
                      // Close the current dialog first
                      Navigator.of(context).pop();
                      // Show the notes dialog
                      _showNotesDialog(event);
                    },
                    child: const Text('Notes'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      // First close the dialog to make the UI responsive
                      Navigator.of(context).pop();

                      // Capture ScaffoldMessenger BEFORE the async gap
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      
                      // Show a loading indicator that can be dismissed
                      const snackBar = SnackBar(
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
                            SizedBox(width: 12),
                            Text('Deleting event...'),
                          ],
                        ),
                        duration: Duration(seconds: 3),
                      );
                      
                      // Show the loading snackbar using the captured messenger
                      scaffoldMessenger.showSnackBar(snackBar);
                      
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
                          // Pass the captured context IF NEEDED by the helper, otherwise remove it.
                          // Assuming CalendarTestHelper might need context, but check its implementation.
                          // If it doesn't, remove context argument below.
                          await CalendarTestHelper.deleteEventFromCalendar(
                            context: context, // CHECK IF NEEDED
                            title: event.title,
                            eventStartTime: startDateTime,
                          );
                        } catch (e) {
                          print('Error deleting from Google Calendar: $e');
                          // Don't show error - the local event was deleted successfully
                        }
                      }
                      
                      // PRELOAD month data after deletion
                      if (_selectedDay != null) {
                        await EventService.preloadMonth(_selectedDay!);
                      }

                      // Check if widget is still mounted AFTER async operations
                      if (mounted) {
                        // Update the UI state immediately after local deletion
                        setState(() {});
                        
                        // Hide the loading indicator using the captured messenger
                        scaffoldMessenger.hideCurrentSnackBar();
                        
                        // Show confirmation of successful local deletion using the captured messenger
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Event deleted'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Add a divider before the bus selection section
              if (event.isWorkShift && !event.title.startsWith('BusCheck')) ...[
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_bus, size: 20, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text(
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
                                child: const SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
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
                                      child: const SizedBox(
                                        width: double.infinity,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
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
                                      child: const SizedBox(
                                        width: double.infinity,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
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
              // Add Divider before Cancel
              const Divider(height: 1, thickness: 1),
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

  // --- Add the new _showNotesDialog function below ---
  void _showNotesDialog(Event event) {
    // Controller for the notes text field
    final notesController = TextEditingController(text: event.notes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // 1. Add Icon to Title
        title: const Row(
          children: [
            Icon(Icons.notes_rounded, color: AppTheme.primaryColor), 
            SizedBox(width: 8),
            Text('Notes'),
          ],
        ),
        // 2. Adjust Content Padding
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0), 
        content: StatefulBuilder( // Keep StatefulBuilder for controller management
          builder: (BuildContext context, StateSetter setState) {
            final screenWidth = MediaQuery.of(context).size.width;
            return SizedBox(
              width: screenWidth * 0.8, 
              // 3. Add Padding around TextField
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: notesController,
                  maxLines: 5, 
                  minLines: 3, 
                  decoration: InputDecoration(
                    hintText: 'Add notes here...',
                    border: const OutlineInputBorder(),
                    // Optional: Add a subtle fill color
                    fillColor: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey.shade800 
                              : Colors.grey.shade100,
                    filled: true,
                  ),
                  onChanged: (text) {
                    // No need to call setState here unless you need UI updates on text change
                  },
                ),
              ),
            );
          },
        ),
        // 4. Adjust Actions Padding
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          // Style Clear button as TextButton and make it red
          TextButton(
            onPressed: () {
              notesController.clear();
            },
            // Add style to set text color to red
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, 
            ),
            child: const Text('Clear'),
          ),
          // Style Save button as ElevatedButton
          ElevatedButton(
            onPressed: () async {
              // Get the updated notes
              final updatedNotes = notesController.text.trim();
              
              if (updatedNotes != (event.notes ?? '')) {
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
                  isHoliday: event.isHoliday,
                  holidayType: event.holidayType,
                  notes: event.notes,
                );

                event.notes = updatedNotes.isEmpty ? null : updatedNotes;
                
                await EventService.updateEvent(oldEvent, event);
                
                setState(() {});
              }
              
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
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
                value: 'notes', // Added notes value
                child: Text('Notes'), // Added notes label
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
              } else if (value == 'contacts') {
                _showContactsPage();
              } else if (value == 'notes') { // Added condition for notes
                _navigateToAllNotesScreen(); // Call the new navigation method
              }
            },
          ),
        ],
      ),
      body: Column( // Removed SafeArea wrapper
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
                  // Consider wrapping this inner Column/ScrollView in SafeArea if needed for bottom intrusions
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
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
          onPageChanged: _onPageChanged,
          eventLoader: getEventsForDay,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: true,
            markersMaxCount: 0,
            markersAnchor: 1.0,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, _) {
              return _buildCalendarDay(date, isToday: false, isOutsideDay: false);
            },
            todayBuilder: (context, date, _) {
              return _buildCalendarDay(date, isToday: true, isOutsideDay: false);
            },
            // Add outsideBuilder to handle days outside the current month
            outsideBuilder: (context, date, _) {
              return _buildCalendarDay(date, isToday: false, isOutsideDay: true);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Month',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime.now();
                              _selectedDay = DateTime.now();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Current Month'),
                        ),
                      ],
                    ),
                  ),
                  // Year selector
                  Container(
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          iconSize: 20,
                          onPressed: () {
                            setModalState(() {
                              _selectedYear = _selectedYear - 1;
                            });
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            '$_selectedYear',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          iconSize: 20,
                          onPressed: () {
                            setModalState(() {
                              _selectedYear = _selectedYear + 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Month grid
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        childAspectRatio: 1.5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final date = DateTime(_selectedYear, month);
                        final isSelected = _focusedDay.year == _selectedYear && 
                                         _focusedDay.month == month;
                        final isCurrentMonth = date.year == DateTime.now().year &&
                                             date.month == DateTime.now().month;
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _focusedDay = date;
                                _selectedDay = date;
                              });
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : isCurrentMonth
                                        ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
                                        : null,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCurrentMonth && !isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  DateFormat('MMM').format(date),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : isCurrentMonth
                                            ? Theme.of(context).colorScheme.primary
                                            : null,
                                    fontSize: 12,
                                    fontWeight: isSelected || isCurrentMonth ? FontWeight.bold : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Bottom padding for safe area
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarDay(DateTime date, {required bool isToday, required bool isOutsideDay}) {
    final shift = _startDate != null ? getShiftForDate(date) : '';
    final shiftInfo = _shiftInfoMap[shift];
    final hasEvents = getEventsForDay(date).isNotEmpty;
    final bankHoliday = getBankHoliday(date);
    final isBankHoliday = bankHoliday != null;
    final isHoliday = _holidays.any((h) => h.containsDate(date));

    // Wrap the content in Opacity if it's an outside day
    return Opacity(
      opacity: isOutsideDay ? 0.4 : 1.0, // Changed from 0.6 to 0.4 for more transparency
      child: Container(
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
        // Wrap the Column with Center
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}'),
              if (shift.isNotEmpty && !isHoliday)
                // Replace FittedBox with simple Text
                Text(
                  shift,
                  style: const TextStyle(
                    fontSize: 11, // Keep the small font size
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1, // Prevent wrapping
                  overflow: TextOverflow.clip, // Clip if somehow too long
                ),
              if (isHoliday)
                // Replace FittedBox with simple Text
                Text(
                  'H',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Consider using theme color here
                  ),
                  maxLines: 1, // Prevent wrapping
                  overflow: TextOverflow.clip, // Clip if somehow too long
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
        ),
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
                children: events.map((event) {
                  // Determine if the shift is spare
                  final isSpareShift = event.title.startsWith('SP');
                  
                  return EventCard(
                    event: event,
                    shiftType: getShiftForDate(event.startDate),
                    shiftInfoMap: _shiftInfoMap,
                    isBankHoliday: getBankHoliday(event.startDate) != null,
                    isRestDay: getShiftForDate(event.startDate) == 'R',
                    // MODIFIED: Use specific delete function for spare shifts
                    onEdit: isSpareShift ? _deleteSpareEvent : _editEvent,
                    onShowNotes: _showNotesDialog, // Pass the function here
                  );
                }).toList(),
              ),
      ],
    );
  }

  void _showStatisticsPage() {
    // Fetch all loaded events directly from the service
    final allEvents = EventService.allLoadedEvents;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatisticsScreen(
          events: allEvents, // Pass the fetched events
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen( // Ensure this points to SettingsScreen
          resetRestDaysCallback: _resetRestDays,
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
                                color: Theme.of(context).colorScheme.surface.withOpacity(0.5), // Use theme color
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).dividerColor), // Use theme divider color
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
                                      color: Theme.of(context).cardColor, // Use theme card color
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).dividerColor, // Use theme divider color
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
                                        style: TextStyle( // Remove const
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.titleMedium?.color // Use theme text color
                                        ),
                                      ),
                                      subtitle: Text(
                                        holiday.startDate == holiday.endDate
                                            ? DateFormat('MMM d').format(holiday.startDate)
                                            : '${DateFormat('MMM d').format(holiday.startDate)} - ${DateFormat('MMM d').format(holiday.endDate)}',
                                        style: TextStyle( // Add style for subtitle
                                          color: Theme.of(context).textTheme.bodySmall?.color // Use theme text color
                                        ),
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
    // Instead of loading all events at once, we'll just preload the current month
    await EventService.preloadMonth(_focusedDay);
    setState(() {});
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

  // New method to navigate to the Notes screen
  void _navigateToAllNotesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllNotesScreen()),
    );
  }

  // --- ADD NEW FUNCTION TO HANDLE SPARE EVENT DELETION ---
  Future<void> _deleteSpareEvent(Event event) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spare Event?'),
        content: Text('Are you sure you want to delete the spare event "${event.title}" on ${DateFormat('dd/MM/yyyy').format(event.startDate)}?'),
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

    if (shouldDelete == true && mounted) {
      // Capture ScaffoldMessenger BEFORE the async gap
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // Show loading indicator
      const snackBar = SnackBar(
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
            SizedBox(width: 12),
            Text('Deleting event...'),
          ],
        ),
        duration: Duration(seconds: 3), // Adjust as needed
      );
      scaffoldMessenger.showSnackBar(snackBar);

      try {
        // Delete from local storage
        await EventService.deleteEvent(event);

        // Optionally delete from Google Calendar if sync enabled
        final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
        final isSignedIn = await GoogleCalendarService.isSignedIn();
        if (syncEnabled && isSignedIn) {
          try {
            final startDateTime = DateTime(
              event.startDate.year, event.startDate.month, event.startDate.day,
              event.startTime.hour, event.startTime.minute,
            );
            // Assuming CalendarTestHelper might need context, but check its implementation.
            // If it doesn't, remove context argument below.
            await CalendarTestHelper.deleteEventFromCalendar(
              context: context, // CHECK IF NEEDED
              title: event.title,
              eventStartTime: startDateTime,
            );
          } catch (e) {
            print('Error deleting spare event from Google Calendar: $e');
            // Optionally show a less intrusive error if Google sync fails
          }
        }
        
        // PRELOAD month data after deletion
        if (_selectedDay != null) {
          await EventService.preloadMonth(_selectedDay!);
        }

        // Check if widget is still mounted AFTER async operations
        if (mounted) {
          // Update UI
          setState(() {});
          scaffoldMessenger.hideCurrentSnackBar(); // Hide loading
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Spare event deleted'), duration: Duration(seconds: 2)),
          );
        }
      } catch (e) {
        print('Error deleting spare event: $e');
        // Check if mounted before showing error snackbar
        if (mounted) {
          scaffoldMessenger.hideCurrentSnackBar(); // Hide loading
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to delete event: $e'), duration: Duration(seconds: 3)),
          );
        }
      }
    }
  }
  // --- END NEW FUNCTION ---

  // Add this method to handle calendar page changes
  void _onPageChanged(DateTime focusedDay) {
    if (!mounted) return; // Prevent setState after dispose
    
    setState(() {
      _focusedDay = focusedDay;
    });
    
    // Preload the new month's events with error handling
    try {
      EventService.preloadMonth(focusedDay);
    } catch (e) {
      print('Error preloading month: $e');
    }
    
    // Clear old cache entries periodically with error handling
    try {
      EventService.clearOldCache();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
