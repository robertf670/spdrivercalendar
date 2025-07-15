import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'dart:math' as math;
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';

import 'package:spdrivercalendar/services/rest_days_service.dart'; // Added import
import 'package:spdrivercalendar/features/contacts/contacts_page.dart'; // Add this line
import 'package:spdrivercalendar/core/services/cache_service.dart'; // Added import
import 'package:spdrivercalendar/features/notes/screens/all_notes_screen.dart'; // Import the new screen
// Add import for feedback screen (will be created later)
// ignore: unused_import
import 'package:spdrivercalendar/features/feedback/screens/feedback_screen.dart';
import 'package:spdrivercalendar/features/bills/screens/bills_screen.dart'; // Import the Bills screen
import 'package:spdrivercalendar/features/payscale/screens/payscale_screen.dart'; // Import the Payscale screen
import 'package:uuid/uuid.dart';
import 'package:spdrivercalendar/services/update_service.dart';
import 'package:spdrivercalendar/core/widgets/enhanced_update_dialog.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';
import '../../../widgets/live_updates_banner.dart';
import '../../../screens/live_updates_details_screen.dart';
import '../../../services/live_updates_service.dart';
import '../../../models/live_update.dart';
import '../../../services/bus_tracking_service.dart';

// Add this new widget class before the CalendarScreen class
class _StableLiveUpdatesBanner extends StatefulWidget {
  final VoidCallback onTap;

  const _StableLiveUpdatesBanner({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  _StableLiveUpdatesBannerState createState() => _StableLiveUpdatesBannerState();
}

class _StableLiveUpdatesBannerState extends State<_StableLiveUpdatesBanner> {
  @override
  Widget build(BuildContext context) {
    return LiveUpdatesBanner(
      onTap: widget.onTap,
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final ValueNotifier<bool> isDarkModeNotifier;

  const CalendarScreen(this.isDarkModeNotifier, {Key? key}) : super(key: key);

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  DateTime? _startDate;
  int _startWeek = 0;
  int _selectedYear = DateTime.now().year;
  List<BankHoliday>? _bankHolidays;
  List<Holiday> _holidays = [];
  late AnimationController _animationController;
  bool _hasCheckedForUpdatesOnStartup = false;
  final Map<String, bool> _busTrackingLoading = {};
  
  late Map<String, ShiftInfo> _shiftInfoMap;

  // Add holiday color constant
  static const Color holidayColor = Color(0xFF00BCD4); // Teal color for holidays

  void _initializeShiftColors() {
    final colors = ColorCustomizationService.getShiftColors();
    _shiftInfoMap = {
      'E': ShiftInfo('Early', colors['E']!),
      'L': ShiftInfo('Late', colors['L']!),
      'M': ShiftInfo('Middle', colors['M']!),
      'R': ShiftInfo('Rest', colors['R']!),
    };
  }

  void refreshShiftColors() {
    _initializeShiftColors();
    setState(() {});
  }

  /// Track a bus using bustimes.org
  Future<void> _trackBus(String busNumber) async {
    final trackingKey = 'tracking_$busNumber';
    
    if (_busTrackingLoading[trackingKey] == true) return; // Already tracking
    
    setState(() {
      _busTrackingLoading[trackingKey] = true;
    });

    try {
      final success = await BusTrackingService.trackBus(busNumber);
      
      if (mounted) {
        setState(() {
          _busTrackingLoading[trackingKey] = false;
        });

        // Show appropriate message based on success
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening tracking for bus $busNumber'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bus $busNumber not found in the tracking system'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busTrackingLoading[trackingKey] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error tracking bus $busNumber'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _initializeShiftColors();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    WidgetsBinding.instance.addObserver(this);
    
    // Register for color change notifications
    ColorCustomizationService.setColorChangeCallback(refreshShiftColors);
    
    // Initialize with current month's events with error handling
    _initializeCurrentMonth().catchError((error) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading calendar data. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Schedule automatic update check after calendar loads
    _scheduleAutomaticUpdateCheck();
  }

  Future<void> _scheduleAutomaticUpdateCheck() async {
    // Check for updates immediately when calendar loads - no delay
    // await Future.delayed(const Duration(seconds: 2)); // REMOVED: No delay for instant detection
    
    if (mounted && !_hasCheckedForUpdatesOnStartup) {
      _hasCheckedForUpdatesOnStartup = true;
      await _checkForAutomaticUpdates();
    }
  }

  Future<void> _checkForAutomaticUpdates() async {
    try {

      final updateInfo = await UpdateService.checkForUpdate(forceCheck: true);
      
      if (updateInfo != null && updateInfo.hasUpdate && mounted) {

        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => EnhancedUpdateDialog(updateInfo: updateInfo),
        );
      } else {

      }
    } catch (e) {
      // Silently handle update check failures - don't interrupt user experience
      // Log error for debugging if needed in development
      if (kDebugMode) {
        debugPrint('Auto-update check failed: $e');
      }
    }
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
    final startWeek = await StorageService.getInt(AppConstants.startWeekKey);
    
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
                        
                        final navigator = Navigator.of(context);
                        await _saveSettings();
                        navigator.pop();
                        
                        // Force a rebuild to show the updated calendar
                        if (mounted) {
                          setState(() {});
                        }
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
    // Clear color change callback
    ColorCustomizationService.clearColorChangeCallback();
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
    
    // Debug: Log event retrieval for troubleshooting
    if (kDebugMode && _selectedDay != null && isSameDay(_selectedDay!, day)) {
      debugPrint('CalendarScreen: Getting events for selected day ${day.toIso8601String()}: ${events.length} events found');
      for (final event in events) {
        debugPrint('  - Event: ${event.title} (ID: ${event.id})');
        if (event.title.startsWith('SP') && event.assignedDuties != null) {
          debugPrint('    Assigned duties: ${event.assignedDuties}');
          debugPrint('    Bus assignments: ${event.busAssignments}');
        }
      }
    }
    
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add disclaimer about duty information FIRST
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'The duty information in this app is taken from the bills provided in the depot. There may be mistakes at times.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('What type of event would you like to add?'),
            ],
          ),
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
            TextButton( // Added Overtime button
              child: const Text('Overtime'),
              onPressed: () {
                Navigator.of(context).pop();
                _promptForOvertimeHalfType(); // Call the function to show overtime options
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
              
              // Handle different zones differently
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
                      // For regular work shifts, include ALL duties (including workouts)
                      combinedShifts.add(parts[0]);
                    }
                  }
                } catch (e) {
          // Debug statement removed
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
                        // For regular work shifts, include ALL duties (including workouts)
                        combinedShifts.add(parts[0]);
                      }
                    }
                  } catch (e) {
          // Debug statement removed
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
              } else if (selectedZone == 'Bus Check') { 
                try {
                  final csv = await rootBundle.loadString('assets/buscheck.csv');
                  final lines = csv.split('\n');
                  shiftNumbers = [];
                  final seenShifts = <String>{};
                  String currentDayType = ''; 

                  // Determine day type string for CSV matching
                  if (dayOfWeek == 'Saturday') {
                    currentDayType = 'SAT';
                  } else if (dayOfWeek == 'Sunday') {
                    currentDayType = 'SUN';
                  } else { // Monday - Friday
                    currentDayType = 'MF'; 
                  }

                  // Skip the header line
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
          // Debug statement removed
                }
              } else if (selectedZone == 'Jamestown Road') {
                // Only allow Monday-Friday for Jamestown Road shifts
                if (dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday') {
                  shiftNumbers = [];
                } else {
                  try {
                    final csv = await rootBundle.loadString('assets/JAMESTOWN_DUTIES.csv');
                    final lines = csv.split('\n');
                    shiftNumbers = [];
                    final seenShifts = <String>{};

                    // Skip the header line
                    for (int i = 1; i < lines.length; i++) {
                      final line = lines[i].trim().replaceAll('\r', '');
                      if (line.isEmpty) continue;
                      final parts = line.split(',');
                      // Expecting format: shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,route
                      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
                        final shift = parts[0].trim();
                        
                        // Add unique shifts only
                        if (!seenShifts.contains(shift) && shift != "shift") {
                          seenShifts.add(shift);
                          shiftNumbers.add(shift);
                        }
                      }
                    }
                  } catch (e) {
                    shiftNumbers = [];
          // Debug statement removed
                  }
                }
              } else {
                // Regular zone shifts
                final filename = RosterService.getShiftFilename(zoneNumber, dayOfWeekForFilename, shiftDate);
                
                try {
                  final csv = await rootBundle.loadString('assets/$filename');
                  final lines = csv.split('\n');
                  shiftNumbers = [];
                  final seenShifts = <String>{};
                  
                  // Skip the header line
                  for (int i = 1; i < lines.length; i++) {
                    final line = lines[i].trim();
                    if (line.isEmpty) continue;
                    final parts = line.split(',');
                    if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
                      final shift = parts[0].trim();
                      
                      // For regular work shifts, include ALL duties (including workouts)
                      if (!seenShifts.contains(shift) && shift != "shift") {
                        seenShifts.add(shift);
                        shiftNumbers.add(shift);
                      }
                    }
                  }
                } catch (e) {
                  shiftNumbers = [];
          // Debug statement removed
                }
              }
              
              // If no selected shift number yet but shifts are available, select the first one
              if (selectedShiftNumber.isEmpty && shiftNumbers.isNotEmpty) {
                selectedShiftNumber = shiftNumbers[0];
              }
            } catch (e) {
          // Debug statement removed
              shiftNumbers = [];
            } finally {
            setState(() {
              isLoading = false;
            });
            }
          }
          
          // Load shift numbers initially
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
                  items: [
                    'Zone 1',
                    'Zone 3',
                    'Zone 4',
                    'Spare',
                    'Uni/Euro',
                    'Bus Check',
                    'Jamestown Road',
                  ].map((zone) {
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
                      } else if (selectedZone == 'Jamestown Road') {
                        title = selectedShiftNumber; // Use the shift code (e.g., 811/01)
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
                      } else if (selectedZone == 'Jamestown Road') {
                        // For Jamestown Road, load from CSV
                        shiftTimes = await _getShiftTimes(selectedZone, selectedShiftNumber, shiftDate);
                      } else {
                        // For other zones, load from CSV
                        shiftTimes = await _getShiftTimes(selectedZone, selectedShiftNumber, shiftDate);
                      }
                      
                      // Handle potential null shiftTimes (error loading CSV etc.)
                      if (shiftTimes == null) {
                         // Could not retrieve shift times
                         if (mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Error retrieving shift times. Please try again.')),
                          );
                         }
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
                      if (mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      
                      // Sync to Google if enabled (before any other async operations)
                      if (mounted) {
                        _checkAndSyncToGoogleCalendar(event, context);
                      }
                      
                      // Force UI refresh immediately after adding an event
                      if (mounted) {
                        // Preload the current month's events to ensure we have the latest data
                        await EventService.preloadMonth(_focusedDay);
                        
                        // Update state to show the new event immediately
                        setState(() {});
                        
                        // Force complete refresh using the same mechanism as spare duties
                        _editEvent(Event(
                          id: 'refresh_trigger',
                          title: '',
                          startDate: _selectedDay ?? DateTime.now(),
                          startTime: const TimeOfDay(hour: 0, minute: 0),
                          endDate: _selectedDay ?? DateTime.now(),
                          endTime: const TimeOfDay(hour: 0, minute: 0),
                          busAssignments: {},
                        ));
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
  Future<Map<String, dynamic>?> _getShiftTimes(String zone, String shiftNumber, DateTime shiftDate, {bool isOvertimeShift = false}) async { // Return type changed to nullable
          // Getting shift times

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
    } else if (zone == 'Jamestown Road') {
      csvPath = 'assets/JAMESTOWN_DUTIES.csv';
      // Jamestown Road only works Monday-Friday
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

    // Loading CSV files for zone

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
          // Debug statement removed
                        
                        // Include all duties for _getShiftTimes (filtering handled in dialog loading)
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
          // Debug statement removed
                          }
                        } else {
          // Debug statement removed
                        }
                    }
                }
            } catch (e) {
          // Debug statement removed
                // Continue to next file if one fails
            }
         }
          // Debug statement removed
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
          // Debug statement removed
              final startTime = _parseTimeOfDay(parts[2].trim());
              final endTime = _parseTimeOfDay(parts[3].trim());

              if (startTime != null && endTime != null) {
                 final isNextDay = endTime.hour < startTime.hour || 
                                   (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
          // Debug statement removed
                 return {
                   'startTime': startTime,
                   'endTime': endTime,
                   'isNextDay': isNextDay,
                 };
              } else {
          // Debug statement removed
              }
            }
          }
        }
        // === Handle Jamestown Road CSV format ===
        else if (zone == 'Jamestown Road') {
          // Expecting format: shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,route
          if (parts.length >= 17) {
            final csvShiftCode = parts[0].trim();
            
            if (csvShiftCode == shiftNumber) {
          // Debug statement removed
              // For overtime shifts, use start time (depart time) instead of report time
              final startTime = isOvertimeShift 
                  ? _parseTimeOfDay(parts[3].trim()) // Depart time for overtime
                  : _parseTimeOfDay(parts[2].trim()); // Report time for regular shifts
              final endTime = _parseTimeOfDay(parts[10].trim()); // Finish time

              if (startTime != null && endTime != null) {
                 final isNextDay = endTime.hour < startTime.hour || 
                                   (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
          // Debug statement removed
                 return {
                   'startTime': startTime,
                   'endTime': endTime,
                   'isNextDay': isNextDay,
                 };
              } else {
          // Debug statement removed
              }
            }
          }
        }
        // === Handle Regular Zone CSV format ===
        else {
          // Expecting PZ format (index 0 is shift, 2 is report, 3 is depart, 12 is signOff)
          if (parts.length >= 13) { 
             final csvShiftCode = parts[0].trim();
             // No need to normalize PZ codes if shiftNumber is passed correctly (e.g. PZ1/01)
             if (csvShiftCode == shiftNumber) {
          // Debug statement removed
                
                // For overtime shifts, use start time (depart time) instead of report time
                final startTime = isOvertimeShift 
                    ? _parseTimeOfDay(parts[3].trim()) // Depart time for overtime
                    : _parseTimeOfDay(parts[2].trim()); // Report time for regular shifts
                final endTime = _parseTimeOfDay(parts[12].trim()); // SignOff time

                if (startTime != null && endTime != null) {
                    final isNextDay = endTime.hour < startTime.hour || 
                                      (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
          // Debug statement removed
                    return {
                      'startTime': startTime,
                      'endTime': endTime,
                      'isNextDay': isNextDay,
                    };
                      } else {
          // Debug statement removed
                }
             }
          }
        }
      }
    } catch (e) {
              // Error loading or parsing CSV file
       return null; // Return null on error
    }

    // No match found or error occurred
          // Debug statement removed
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
          // Debug statement removed
    }
    return null;
  }

  // Helper to check settings and sync to Google Calendar if enabled
  Future<void> _checkAndSyncToGoogleCalendar(Event event, BuildContext? context) async {
    // Return early if context is null or widget is not mounted
    if (context == null || !mounted) return;
    
    // Capture context dependencies before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Check if Google Calendar sync is enabled
    final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
    final isSignedIn = await GoogleCalendarService.isSignedIn();
    
    if (syncEnabled && isSignedIn) {
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
        
        // Check if it's a rest day using RosterService
        final String shiftType = getShiftForDate(event.startDate); // Use existing screen method
        final bool isRest = shiftType == 'R';
        
        // Build description with all available information
        List<String> descriptionParts = [];
        
        // Add break times if available (and not a workout)
        if (breakTime != null && !breakTime.toLowerCase().contains('workout') && breakTime.isNotEmpty) {
          descriptionParts.add('Break Times: $breakTime');
        }
        
        // Add rest day indicator if applicable
        if (isRest) {
          descriptionParts.add('(Working on Rest Day)');
        }
        
        // Combine all parts into final description
        final description = descriptionParts.join('\n');
        
        // Handle case where description might still be empty
        final finalDescription = description.isEmpty ? null : description;
        
        // Add to Google Calendar (check mounted again before async operation)
        if (!mounted) return;
        final success = await CalendarTestHelper.addWorkShiftToCalendar(
          context: context,
          title: event.title,
          startTime: startDateTime,
          endTime: endDateTime,
          description: finalDescription, // Use the updated description
        );
        
        // Use captured messenger to show result (check mounted after async)
        if (success && mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Shift added to Google Calendar')),
          );
        }
      } catch (e) {
        // Don't show error - the local event was added successfully
      }
    }
  }

  void _editEvent(Event event) {
    // If this is a refresh trigger (with any suffix), force a complete refresh
    if (event.id == 'refresh_trigger' || event.id.startsWith('refresh_trigger_')) {
      // Force reload events for the current selected day
      if (_selectedDay != null) {
        EventService.preloadMonth(_selectedDay!).then((_) {
          if (mounted) {
            setState(() {
              // The UI will automatically refresh since getEventsForDay is called in build
            });
          }
        });
      } else {
        setState(() {});
      }
      return;
    }
    
    // If this is an updated spare event (has assigned duties or had them), refresh the day's events
    if (event.title.startsWith('SP') && (event.assignedDuties != null || event.title.contains('SP'))) {
      // Force refresh of the current day's events
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
              Column(
                children: [
                  // View Board button (Zone 4 only) - separate row, centered
                  if (event.title.contains('PZ4/')) ...[
                                         Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         ElevatedButton.icon(
                           onPressed: () async {
                            // Extract duty number from the title (format: PZ4/15 -> 415, PZ4/1X -> 451)
                            final dutyMatch = RegExp(r'PZ4/(\d+X?)').firstMatch(event.title);
                            if (dutyMatch != null) {
                              String dutyNumber = dutyMatch.group(1)!;
                              
                              // Convert PZ4/15 to duty 415, PZ4/1X to duty 451, PZ4/13X to duty 463
                              if (dutyNumber.endsWith('X')) {
                                // X represents 50 + the number before it
                                final numberPart = dutyNumber.substring(0, dutyNumber.length - 1);
                                final baseNumber = int.parse(numberPart);
                                dutyNumber = (50 + baseNumber).toString();
                              }
                              dutyNumber = '4$dutyNumber';
                              
                              // Close the edit dialog first
                              Navigator.of(context).pop();
                              
                              // Parse and show the board data
                              if (mounted) {
                                final boardData = await _parseDutyFromBoard(dutyNumber, event.startDate);
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: math.min(
                                            MediaQuery.of(context).size.width * 0.95,
                                            600, // Maximum width for large screens/tablets
                                          ),
                                          maxHeight: MediaQuery.of(context).size.height * 0.9,
                                        ),
                                        child: AlertDialog(
                                      title: Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Duty $dutyNumber'),
                                                Text(
                                                  DateFormat('EEEE, MMM d').format(event.startDate),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.normal,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                                                                                                                  Text(
                                                  'Information on these boards may not be accurate. The boards files sometimes have errors. This View Boards feature is currently in testing.',
                                                  style: TextStyle(
                                                    fontSize: math.max(10, MediaQuery.of(context).textScaler.scale(10)),
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.orange[700],
                                                  ),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        height: math.min(
                                          MediaQuery.of(context).size.height * 0.7,
                                          MediaQuery.of(context).size.height - 200, // Ensure minimum space for title/buttons
                                        ),
                                        child: boardData.isNotEmpty 
                                          ? Column(
                                              children: [
                                                // Summary header

                                                // Scrollable content
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      children: boardData.asMap().entries.map((entry) {
                                                        final index = entry.key;
                                                        final section = entry.value;
                                                        
                                                        return Container(
                                                          margin: const EdgeInsets.only(bottom: 16),
                                                          child: Card(
                                                            elevation: 2,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                // Section header
                                                                Container(
                                                                  width: double.infinity,
                                                                  padding: const EdgeInsets.all(16),
                                                                  decoration: const BoxDecoration(
                                                                    color: AppTheme.primaryColor,
                                                                    borderRadius: BorderRadius.only(
                                                                      topLeft: Radius.circular(12),
                                                                      topRight: Radius.circular(12),
                                                                    ),
                                                                  ),
                                                                  child: Row(
                                                                    children: [
                                                                      Container(
                                                                        padding: const EdgeInsets.all(6),
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.white.withValues(alpha: 0.2),
                                                                          borderRadius: BorderRadius.circular(6),
                                                                        ),
                                                                        child: Text(
                                                                          '${index + 1}',
                                                                          style: const TextStyle(
                                                                            color: Colors.white,
                                                                            fontWeight: FontWeight.bold,
                                                                            fontSize: 14,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(width: 12),
                                                                      Expanded(
                                                                        child: Text(
                                                                          section['header']!,
                                                                          style: const TextStyle(
                                                                            color: Colors.white,
                                                                            fontWeight: FontWeight.bold,
                                                                            fontSize: 14,
                                                                          ),
                                                                          maxLines: 2,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                // Movements
                                                                Container(
                                                                  width: double.infinity,
                                                                  padding: const EdgeInsets.all(16),
                                                                  child: Column(
                                                                    children: section['movements']!.map<Widget>((movement) {
                                                                      final isRoute = movement.contains('Route');
                                                                      final isSPL = movement.contains('SPL');
                                                                      final isGarage = movement.contains('Garage');
                                                                      
                                                                      IconData icon;
                                                                      Color iconColor;
                                                                      
                                                                      if (isGarage || isSPL) {
                                                                        icon = Icons.home;
                                                                        iconColor = Colors.orange;
                                                                      } else if (isRoute) {
                                                                        icon = Icons.directions_bus;
                                                                        iconColor = Colors.green;
                                                                      } else {
                                                                        icon = Icons.location_on;
                                                                        iconColor = Colors.blue;
                                                                      }
                                                                      
                                                                      return Container(
                                                                        margin: const EdgeInsets.only(bottom: 8),
                                                                        padding: const EdgeInsets.all(12),
                                                                        decoration: BoxDecoration(
                                                                          color: iconColor.withValues(alpha: 0.05),
                                                                          borderRadius: BorderRadius.circular(8),
                                                                          border: Border.all(
                                                                            color: iconColor.withValues(alpha: 0.1),
                                                                          ),
                                                                        ),
                                                                        child: Row(
                                                                          children: [
                                                                            Icon(
                                                                              icon,
                                                                              color: iconColor,
                                                                              size: 16,
                                                                            ),
                                                                            const SizedBox(width: 12),
                                                                            Expanded(
                                                                              child: Text(
                                                                                movement,
                                                                                style: const TextStyle(
                                                                                  fontSize: 13,
                                                                                  height: 1.3,
                                                                                ),
                                                                                softWrap: true,
                                                                                overflow: TextOverflow.visible,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                  ),
                                                                ),
                                                                // Handover information
                                                                if (section['handover'] != null)
                                                                  Container(
                                                                    width: double.infinity,
                                                                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                                                    padding: const EdgeInsets.all(12),
                                                                    decoration: BoxDecoration(
                                                                      gradient: LinearGradient(
                                                                        colors: [
                                                                          Colors.blue.withValues(alpha: 0.1),
                                                                          Colors.blue.withValues(alpha: 0.05),
                                                                        ],
                                                                      ),
                                                                      borderRadius: BorderRadius.circular(8),
                                                                      border: Border.all(
                                                                        color: Colors.blue.withValues(alpha: 0.2),
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          section['handover']!.contains('Finish Duty')
                                                                            ? Icons.flag
                                                                            : Icons.swap_horiz,
                                                                          color: Colors.blue,
                                                                          size: 16,
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        Expanded(
                                                                          child: Text(
                                                                            section['handover']!,
                                                                            style: const TextStyle(
                                                                              fontSize: 12,
                                                                              fontStyle: FontStyle.italic,
                                                                              color: Colors.blue,
                                                                            ),
                                                                            softWrap: true,
                                                                            overflow: TextOverflow.visible,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.search_off,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(height: 16),
                                                  Text(
                                                    'No running board data found for this duty.',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.view_list, size: 18),
                          label: const Text('View Board'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  
                  // Notes and Break Status buttons - always centered together
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Close the current dialog first
                          Navigator.of(context).pop();
                          // Show the notes dialog
                          _showNotesDialog(event);
                        },
                        child: const Text('Notes'),
                      ),
                      const SizedBox(width: 16),
                      // Add Break Status button for eligible duties
                      if (event.isEligibleForOvertimeTracking) 
                        TextButton(
                          onPressed: () {
                            // Close the current dialog first
                            Navigator.of(context).pop();
                            // Show break status dialog
                            _showBreakStatusDialog(event);
                          },
                          child: const Text('Break Status'),
                        ),
                    ],
                  ),
                ],
              ),
              // Add a divider before the bus selection section
              if ((event.isWorkShift && !event.title.startsWith('BusCheck')) || _spareShiftHasFullDuties(event)) ...[
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
                                        (isWorkout || event.title.contains('(OT)')) ? 'Assigned Bus: ${event.firstHalfBus}' : 'First Half: ${event.firstHalfBus}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    // Track button for first half bus
                                    IconButton(
                                      icon: _busTrackingLoading['tracking_${event.firstHalfBus}'] == true
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.location_on, size: 18, color: Colors.blue),
                                      onPressed: _busTrackingLoading['tracking_${event.firstHalfBus}'] == true
                                          ? null
                                          : () => _trackBus(event.firstHalfBus!),
                                      tooltip: 'Track ${event.firstHalfBus}',
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
                                          busAssignments: event.busAssignments,
                                          notes: event.notes,
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
                                          busAssignments: event.busAssignments, // CRITICAL: Preserve bus assignments
                                          firstHalfBus: null, // Remove first half bus
                                          secondHalfBus: event.secondHalfBus,
                                          notes: event.notes,
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
                                        (isWorkout || event.title.contains('(OT)')) ? 'Assigned Bus: ${event.secondHalfBus}' : 'Second Half: ${event.secondHalfBus}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    // Track button for second half bus
                                    IconButton(
                                      icon: _busTrackingLoading['tracking_${event.secondHalfBus}'] == true
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Icon(Icons.location_on, size: 18, color: Colors.blue),
                                      onPressed: _busTrackingLoading['tracking_${event.secondHalfBus}'] == true
                                          ? null
                                          : () => _trackBus(event.secondHalfBus!),
                                      tooltip: 'Track ${event.secondHalfBus}',
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
                                          busAssignments: event.busAssignments,
                                          notes: event.notes,
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
                                          busAssignments: event.busAssignments, // CRITICAL: Preserve bus assignments
                                          firstHalfBus: event.firstHalfBus,
                                          secondHalfBus: null, // Remove second half bus
                                          notes: event.notes, // Add this line
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
                          final isOvertimeShift = event.title.contains('(OT)');
                          final isWorkoutOrOvertime = isWorkout || isOvertimeShift;
                          final isSpareWithFullDuties = _spareShiftHasFullDuties(event);
                          
                          if (isWorkoutOrOvertime) {
                            // Single button for workout and overtime shifts - only show if no bus is assigned
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
                                      busAssignments: event.busAssignments, // CRITICAL: Preserve bus assignments
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
                            // Two buttons for regular shifts OR spare shifts with full duties
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
                                          busAssignments: event.busAssignments,
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
                                            busAssignments: event.busAssignments, // CRITICAL: Preserve bus assignments
                                            firstHalfBus: result,
                                            secondHalfBus: event.secondHalfBus,
                                            notes: event.notes, // Add this line
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
                                          busAssignments: event.busAssignments,
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
                                            busAssignments: event.busAssignments, // CRITICAL: Preserve bus assignments
                                            firstHalfBus: event.firstHalfBus,
                                            secondHalfBus: result,
                                            notes: event.notes, // Add this line
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
              // Cancel and Delete buttons at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Delete button (only for non-spare duty events)
                  // Real spare duties start with "SP" and use their own dialog with delete button
                  // Exception: spare shifts with full duties should use regular delete logic
                  if (!(event.isWorkShift && event.title.startsWith('SP')) || _spareShiftHasFullDuties(event))
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
                            await CalendarTestHelper.deleteEventFromCalendar(
                              context: context,
                              title: event.title,
                              eventStartTime: startDateTime,
                            );
                          } catch (e) {
          // Debug statement removed
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
                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Add the duty parsing function ---
  // Helper function to extract time from duty header for sorting
  String? _extractTimeFromHeader(String header) {
    // Extract time from headers like:
    // "Running Board X (Bus Y) - Starts at 08:22"
    // "Running Board X (Bus Y) - Takes over at PSQE 15:15"
    
    final startsMatch = RegExp(r'Starts at (\d{2}:\d{2})').firstMatch(header);
    if (startsMatch != null) {
      return startsMatch.group(1);
    }
    
    final takesOverMatch = RegExp(r'Takes over at .* (\d{2}:\d{2})').firstMatch(header);
    if (takesOverMatch != null) {
      return takesOverMatch.group(1);
    }
    
    return null;
  }

  Future<List<Map<String, dynamic>>> _parseDutyFromBoard(String dutyNumber, DateTime eventDate) async {
    try {
      // Determine which board file to use based on the day of the week
      String boardFileName;
      final dayOfWeek = RosterService.getDayOfWeek(eventDate);
      final bankHoliday = ShiftService.getBankHoliday(eventDate, ShiftService.bankHolidays);
      

      
              if (dayOfWeek.toLowerCase() == 'sunday' || bankHoliday != null) {
          boardFileName = 'Zone4SunBoards.txt';
        } else if (dayOfWeek.toLowerCase() == 'saturday') {
          boardFileName = 'Zone4SatBoards.txt';
        } else {
          // Monday-Friday
          boardFileName = 'Zone4M-FBoards.txt';
        }
      
      late String boardContent;
      try {
        boardContent = await rootBundle.loadString('assets/$boardFileName');
      } catch (e) {
          // Debug statement removed
        // Try to load as bytes and handle different encodings
        try {
          final bytes = await rootBundle.load('assets/$boardFileName');
          final byteData = bytes.buffer.asUint8List();
          
          // Check for UTF-16 BOM (Byte Order Mark)
          if (byteData.length >= 2 && byteData[0] == 0xFF && byteData[1] == 0xFE) {
            // UTF-16 LE (Little Endian)
          // Debug statement removed
            final utf16Bytes = byteData.sublist(2); // Skip BOM
            final codeUnits = <int>[];
            for (int i = 0; i < utf16Bytes.length; i += 2) {
              if (i + 1 < utf16Bytes.length) {
                int codeUnit = utf16Bytes[i] | (utf16Bytes[i + 1] << 8);
                codeUnits.add(codeUnit);
              }
            }
            boardContent = String.fromCharCodes(codeUnits);
          } else if (byteData.length >= 2 && byteData[0] == 0xFE && byteData[1] == 0xFF) {
            // UTF-16 BE (Big Endian)
          // Debug statement removed
            final utf16Bytes = byteData.sublist(2); // Skip BOM
            final codeUnits = <int>[];
            for (int i = 0; i < utf16Bytes.length; i += 2) {
              if (i + 1 < utf16Bytes.length) {
                int codeUnit = (utf16Bytes[i] << 8) | utf16Bytes[i + 1];
                codeUnits.add(codeUnit);
              }
            }
            boardContent = String.fromCharCodes(codeUnits);
          } else {
            // Fallback to simple byte conversion for other encodings
            boardContent = String.fromCharCodes(byteData);
          }
          // Debug statement removed
        } catch (e2) {
          // Debug statement removed
          return [];
        }
      }
      final lines = boardContent.split('\n');
      
      List<Map<String, dynamic>> dutyData = [];
      String? currentRunningBoard;
      String? currentBus;
      bool inDutySection = false;
      List<String> currentMovements = [];
      String? currentHeader;
      String? handoverInfo;
      
          // Debug statement removed
          // Debug statement removed
       
       // Debug: Show first few lines to see if content is corrupted
          // Debug statement removed
       for (int i = 0; i < math.min(10, lines.length); i++) {
          // Debug statement removed
       }
       
       // First, let's see what duties are actually in the file
       final foundDuties = <String>[];
       for (final line in lines) {
         if (line.trim().startsWith('Duty ')) {
           final dutyMatch = RegExp(r'Duty (\d+) ').firstMatch(line.trim());
           if (dutyMatch != null) {
             foundDuties.add(dutyMatch.group(1)!);
           }
         }
       }
       // Duties found in file
       
       for (int i = 0; i < lines.length; i++) {
         final line = lines[i].trim();
         
         // Track current running board and bus
         if (line.startsWith('Running Board ')) {
           final match = RegExp(r'Running Board (\d+) \(Bus (\d+)\)').firstMatch(line);
           if (match != null) {
             currentRunningBoard = match.group(1);
             currentBus = match.group(2);
           }
         }
         
         // Check if this line starts our duty
         if (line.startsWith('Duty $dutyNumber ')) {
          // Debug statement removed
          // Save previous duty section if we were in one
          if (inDutySection && currentHeader != null) {
            dutyData.add({
              'header': currentHeader,
              'movements': List<String>.from(currentMovements),
              'handover': handoverInfo,
            });
          }
          
          // Start new duty section
          inDutySection = true;
          currentMovements.clear();
          handoverInfo = null;
          
          // Extract the duty info (starts/takes over)
          if (line.contains('starts ')) {
            final timeMatch = RegExp(r'starts (\d{2}:\d{2})').firstMatch(line);
            final startTime = timeMatch?.group(1) ?? 'unknown';
            currentHeader = 'Running Board $currentRunningBoard (Bus $currentBus) - Starts at $startTime';
          } else if (line.contains('takes over at ')) {
            final locationMatch = RegExp(r'takes over at (.*?) (\d{2}:\d{2})').firstMatch(line);
            final location = locationMatch?.group(1) ?? 'unknown location';
            final time = locationMatch?.group(2) ?? 'unknown time';
            currentHeader = 'Running Board $currentRunningBoard (Bus $currentBus) - Takes over at $location $time';
          }
        }
        // Check if we're leaving our duty (next duty starts or we hit a handover)
        else if (inDutySection) {
          if (line.startsWith('Duty ') && !line.startsWith('Duty $dutyNumber')) {
            // We've moved to a different duty, save current section
            if (currentHeader != null) {
              dutyData.add({
                'header': currentHeader,
                'movements': List<String>.from(currentMovements),
                'handover': handoverInfo,
              });
            }
            inDutySection = false;
          } else if (line.startsWith('[') && line.endsWith(']')) {
            // This is handover information
            handoverInfo = line.substring(1, line.length - 1); // Remove brackets
            
            // If this is the end of our duty (Finish Duty or handover to another bus)
            if (line.contains('Finish Duty') || line.contains('Duty $dutyNumber takes')) {
              if (currentHeader != null) {
                dutyData.add({
                  'header': currentHeader,
                  'movements': List<String>.from(currentMovements),
                  'handover': handoverInfo,
                });
              }
              inDutySection = false;
            }
          } else if (line.startsWith('- ')) {
            // This is a movement line
            currentMovements.add(line.substring(2)); // Remove "- " prefix
          }
        }
      }
      
      // Handle case where duty section was at the end of file
      if (inDutySection && currentHeader != null) {
        dutyData.add({
          'header': currentHeader,
          'movements': List<String>.from(currentMovements),
          'handover': handoverInfo,
        });
      }
      
      // Sort duty data chronologically by start time
      dutyData.sort((a, b) {
        final timeA = _extractTimeFromHeader(a['header'] as String);
        final timeB = _extractTimeFromHeader(b['header'] as String);
        
        // If we can't parse times, maintain original order
        if (timeA == null || timeB == null) return 0;
        
        return timeA.compareTo(timeB);
      });
      
      return dutyData;
    } catch (e) {
          // Debug statement removed
      return [];
    }
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
            final screenHeight = MediaQuery.of(context).size.height;
            return SizedBox(
              width: screenWidth * 0.9,  // Increased from 0.8 to 0.9 for wider dialog
              height: screenHeight * 0.4, // Added height constraint for taller dialog
              // 3. Add Padding around TextField
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: TextField(
                    controller: notesController,
                    maxLines: null,  // Must be null when expands is true
                    minLines: null,  // Must be null when expands is true
                    expands: true,   // Expand to fill available space
                    textAlignVertical: TextAlignVertical.top, // Start text at top
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
                  busAssignments: event.busAssignments,
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

  // --- Add the new _showBreakStatusDialog function below ---
  void _showBreakStatusDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Break Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.hasLateBreak) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Status:', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          event.tookFullBreak 
                              ? Icons.free_breakfast
                              : Icons.monetization_on,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.tookFullBreak 
                              ? 'Full Break Taken'
                              : 'Overtime (${event.overtimeDuration} mins)', 
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
            ],
            const Text(
              'Select an option for late break:',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          // Add Remove button if break status exists
          if (event.hasLateBreak)
            TextButton(
              onPressed: () async {
                // Save the old event for update
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
                  busAssignments: event.busAssignments,
                  notes: event.notes,
                  hasLateBreak: event.hasLateBreak,
                  tookFullBreak: event.tookFullBreak,
                  overtimeDuration: event.overtimeDuration,
                );
                
                // Reset break status
                event.hasLateBreak = false;
                event.tookFullBreak = false;
                event.overtimeDuration = null;
                
                // Save the updated event
                await EventService.updateEvent(oldEvent, event);
                
                // Close the dialog
                Navigator.of(context).pop();
                
                // Update the UI
                setState(() {});
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Break status removed'),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // Force refresh of the event cards
                _editEvent(Event(
                  id: 'refresh_trigger',
                  title: '',
                  startDate: DateTime.now(),
                  startTime: const TimeOfDay(hour: 0, minute: 0),
                  endDate: DateTime.now(),
                  endTime: const TimeOfDay(hour: 0, minute: 0),
                  busAssignments: {},
                ));
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () async {
              // Save the old event for update
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
                notes: event.notes,
                hasLateBreak: event.hasLateBreak,
                tookFullBreak: event.tookFullBreak,
                overtimeDuration: event.overtimeDuration,
              );
              
              // Update event with Full Break option
              event.hasLateBreak = true;
              event.tookFullBreak = true;
              event.overtimeDuration = null;
              
              // Save the updated event
              await EventService.updateEvent(oldEvent, event);
              
              // Close the dialog
              Navigator.of(context).pop();
              
              // Update the UI
              setState(() {});
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Full Break status saved'),
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Force refresh of the event cards
              _editEvent(Event(
                id: 'refresh_trigger',
                title: '',
                startDate: DateTime.now(),
                startTime: const TimeOfDay(hour: 0, minute: 0),
                endDate: DateTime.now(),
                endTime: const TimeOfDay(hour: 0, minute: 0),
                busAssignments: {},
              ));
            },
            child: const Text('Full Break'),
          ),
          TextButton(
            onPressed: () {
              // Close current dialog and show overtime selection dialog
              Navigator.of(context).pop();
              _showOvertimeSelectionDialog(event);
            },
            child: const Text('Overtime'),
          ),
        ],
      ),
    );
  }

  // Show dialog for overtime duration selection
  void _showOvertimeSelectionDialog(Event event) {
    int selectedDuration = event.overtimeDuration ?? 60; // Default to 60 mins
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.orange),
              SizedBox(width: 8),
              Text('Select Overtime'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select overtime duration:',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              // Dropdown for overtime duration
              DropdownButtonFormField<int>(
                value: selectedDuration,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(),
                ),
                items: [10, 20, 30, 40, 50, 60].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value mins'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedDuration = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Quick 1 Hour button
              Center(
                child: TextButton(
                  onPressed: () async {
                    // Save the old event for update
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
                      busAssignments: event.busAssignments, // CRITICAL: Preserve bus assignments
                      firstHalfBus: event.firstHalfBus,
                      secondHalfBus: event.secondHalfBus,
                      notes: event.notes,
                      hasLateBreak: event.hasLateBreak,
                      tookFullBreak: event.tookFullBreak,
                      overtimeDuration: event.overtimeDuration,
                    );
                    
                    // Set to 1 hour overtime
                    event.hasLateBreak = true;
                    event.tookFullBreak = false;
                    event.overtimeDuration = 60; // Always 1 hour (60 mins)
                    
                    // Save the updated event
                    await EventService.updateEvent(oldEvent, event);
                    
                    // Close the dialog
                    Navigator.of(context).pop();
                    
                    // Update the UI
                    this.setState(() {});
                    
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Overtime (1 hour) saved'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    // Force refresh of the event cards
                    _editEvent(Event(
                      id: 'refresh_trigger',
                      title: '',
                      startDate: DateTime.now(),
                      startTime: const TimeOfDay(hour: 0, minute: 0),
                      endDate: DateTime.now(),
                      endTime: const TimeOfDay(hour: 0, minute: 0),
                      busAssignments: {},
                    ));
                  },
                  child: const Text('1 Hour (Common)'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Save the old event for update
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
                  busAssignments: event.busAssignments, // CRITICAL: Preserve bus assignments
                  firstHalfBus: event.firstHalfBus,
                  secondHalfBus: event.secondHalfBus,
                  notes: event.notes,
                  hasLateBreak: event.hasLateBreak,
                  tookFullBreak: event.tookFullBreak,
                  overtimeDuration: event.overtimeDuration,
                );
                
                // Update event with Overtime option
                event.hasLateBreak = true;
                event.tookFullBreak = false;
                event.overtimeDuration = selectedDuration;
                
                // Save the updated event
                await EventService.updateEvent(oldEvent, event);
                
                // Close the dialog
                Navigator.of(context).pop();
                
                // Update the UI
                setState(() {});
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Overtime ($selectedDuration mins) saved'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                // Force refresh of the event cards
                _editEvent(Event(
                  id: 'refresh_trigger',
                  title: '',
                  startDate: DateTime.now(),
                  startTime: const TimeOfDay(hour: 0, minute: 0),
                  endDate: DateTime.now(),
                  endTime: const TimeOfDay(hour: 0, minute: 0),
                  busAssignments: {},
                ));
              },
              child: const Text('Save'),
            ),
          ],
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
                value: 'bills',
                child: Text('Bills'),
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
                value: 'payscale', // Added payscale value
                child: Text('Pay Scale'), // Added payscale label
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
              } else if (value == 'bills') {
                _showBillsPage();
              } else if (value == 'settings') {
                _showSettingsPage();
              } else if (value == 'add_holidays') {
                _showAddHolidaysDialog();
              } else if (value == 'contacts') {
                _showContactsPage();
              } else if (value == 'notes') { // Added condition for notes
                _navigateToAllNotesScreen(); // Call the new navigation method
              } else if (value == 'payscale') { // Added condition for payscale
                _showPayscalePage(); // Call the new navigation method
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<LiveUpdate>>(
        stream: LiveUpdatesService.getActiveUpdatesStream(),
        builder: (context, bannerSnapshot) {
          // Check if there are active updates
          final updates = bannerSnapshot.data ?? [];
          final hasActiveUpdates = updates.any((update) => update.isActive);
          
          return Stack(
            children: [
              // Main content with dynamic padding based on banner presence
              Padding(
                padding: EdgeInsets.only(top: hasActiveUpdates ? 90 : 0),
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
                            // Consider wrapping this inner Column/ScrollView in SafeArea if needed for bottom intrusions
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Live Updates Banner - only show when there are active updates
              if (hasActiveUpdates)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _StaticLiveUpdatesBanner(),
                ),
            ],
          );
        },
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
          onDaySelected: (selectedDay, focusedDay) async {
            // Check if we're returning to a day that might have missing events
            if (_selectedDay != null && selectedDay != _selectedDay) {
              // Force reload events for the selected day to ensure data is current
              try {
                await EventService.preloadMonth(selectedDay);
                
                // CRITICAL FIX: Additional validation for spare duty data integrity during navigation
                final selectedDayEvents = EventService.getEventsForDay(selectedDay);
                for (final event in selectedDayEvents) {
                  if (event.title.startsWith('SP') && event.assignedDuties != null && event.assignedDuties!.isNotEmpty) {
                    debugPrint('Navigation check - Spare duty: ${event.title} has duties: ${event.assignedDuties} and buses: ${event.busAssignments}');
                  }
                }
              } catch (e) {
                debugPrint('Warning: Failed to preload month for selected day: $e');
              }
            }
            
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
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5), // Use theme color
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
                                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2)
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
              ? holidayColor.withValues(alpha: 0.3)
              : shiftInfo?.color.withValues(alpha: 0.3),
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
        // Use Stack for more compact layout
        child: Stack(
          children: [
            // Main content centered
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Important: minimize space
                children: [
                  Text(
                    '${date.day}',
                    style: const TextStyle(fontSize: 14), // Slightly smaller
                  ),
                  if (shift.isNotEmpty && !isHoliday)
                    Text(
                      shift,
                      style: const TextStyle(
                        fontSize: 10, // Smaller font
                        fontWeight: FontWeight.bold,
                        height: 1.0, // Reduce line height
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  if (isHoliday)
                    Text(
                      'H',
                      style: const TextStyle(
                        fontSize: 10, // Smaller font
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0, // Reduce line height
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                ],
              ),
            ),
            // Event indicator positioned in bottom-right corner
            if (hasEvents)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 6, // Smaller dot
                  height: 6, // Smaller dot
                  decoration: BoxDecoration(
                    color: isHoliday 
                        ? holidayColor 
                        : (shiftInfo?.color ?? Theme.of(context).primaryColor),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
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
                  return EventCard(
                    event: event,
                    shiftType: getShiftForDate(event.startDate),
                    shiftInfoMap: _shiftInfoMap,
                    isBankHoliday: getBankHoliday(event.startDate) != null,
                    isRestDay: getShiftForDate(event.startDate) == 'R',
                    onEdit: _editEvent, // Use _editEvent for all types, EventCard handles spare logic
                    onShowNotes: _showNotesDialog, // Pass the function here
                  );
                }).toList(),
              ),
      ],
    );
  }

  void _showStatisticsPage() {
    // Fetch all loaded events directly from the service and convert string keys to DateTime keys
    final allEventsWithStringKeys = EventService.allLoadedEvents;
    
    // Convert string keys back to DateTime keys for StatisticsScreen
    final Map<DateTime, List<Event>> allEvents = {};
    for (final entry in allEventsWithStringKeys.entries) {
      final dateKey = DateTime.parse(entry.key);
      allEvents[dateKey] = entry.value;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatisticsScreen(
          events: allEvents, // Pass the converted events
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
                                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5), // Use theme color
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
                                          color: Colors.black.withValues(alpha: 0.05),
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
                                        style: TextStyle( // Remove const since we use Theme.of(context)
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
                              color: Colors.black.withValues(alpha: 0.05),
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
                              color: Colors.black.withValues(alpha: 0.05),
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
    ); // Removed the erroneous .then block
  }



  // Method to navigate to Bills page
  void _showBillsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BillsScreen()), // Navigate to BillsScreen
    );
  }

  // --- ADD NEW FUNCTION TO NAVIGATE TO PAYSCALE SCREEN ---
  void _showPayscalePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PayscaleScreen()),
    );
  }
  // --- END NEW PAYSCALE FUNCTION ---



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
          // Debug statement removed
    }
    
    // Clear old cache entries periodically with error handling
    // try {
    //   EventService.clearOldCache(); // REMOVED: This was causing issues with loading old months
    // } catch (e) {
    //   print('Error clearing cache: $e');
    // }
  }

  // Method to prompt user for overtime half type (A or B)
  void _promptForOvertimeHalfType() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Overtime Half'),
          content: const Text('Is this for the first or second half of a shift?'),
          actions: [
            TextButton(
              child: const Text('First Half'),
              onPressed: () {
                Navigator.of(context).pop();
                _showOvertimeDutyDetailsDialogInternal('A');
              },
            ),
            TextButton(
              child: const Text('Second Half'),
              onPressed: () {
                Navigator.of(context).pop();
                _showOvertimeDutyDetailsDialogInternal('B');
              },
            ),
          ],
        );
      },
    );
  }

  // Method to show overtime duty selection dialog with filtered duties by half type
  void _showOvertimeDutyDetailsDialogInternal(String overtimeHalfType) {
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
              
              // Handle different zones differently
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
                      // For regular work shifts, include ALL duties (including workouts)
                      combinedShifts.add(parts[0]);
                    }
                  }
                } catch (e) {
          // Debug statement removed
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
                        // For regular work shifts, include ALL duties (including workouts)
                        combinedShifts.add(parts[0]);
                      }
                    }
                  } catch (e) {
          // Debug statement removed
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
              } else if (selectedZone == 'Bus Check') { 
                try {
                  final csv = await rootBundle.loadString('assets/buscheck.csv');
                  final lines = csv.split('\n');
                  shiftNumbers = [];
                  final seenShifts = <String>{};
                  String currentDayType = ''; 

                  // Determine day type string for CSV matching
                  if (dayOfWeek == 'Saturday') {
                    currentDayType = 'SAT';
                  } else if (dayOfWeek == 'Sunday') {
                    currentDayType = 'SUN';
                  } else { // Monday - Friday
                    currentDayType = 'MF'; 
                  }

                  // Skip the header line
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
          // Debug statement removed
                }
              } else {
                // Regular zone shifts (Zone 1, Zone 3, Zone 4)
                final filename = RosterService.getShiftFilename(zoneNumber, dayOfWeekForFilename, shiftDate);
                
                try {
                  final csv = await rootBundle.loadString('assets/$filename');
                  final lines = csv.split('\n');
                  shiftNumbers = [];
                  final seenShifts = <String>{};
                  
                  // Skip the header line
                  for (int i = 1; i < lines.length; i++) {
                    final line = lines[i].trim();
                    if (line.isEmpty) continue;
                    final parts = line.split(',');
                    if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
                      final shift = parts[0].trim();
                      
                      // For overtime shifts, exclude workout duties
                      // Check if this is a workout duty by examining the break time column
                      if (parts.length >= 6) {
                        final startBreak = parts[5].trim().toLowerCase();
                        if (startBreak == 'workout' || startBreak == 'nan') {
                          continue; // Skip workout duties for overtime
                        }
                      }
                      
                      // For regular work shifts, include ALL duties (including workouts)
                      if (!seenShifts.contains(shift) && shift != "shift") {
                        seenShifts.add(shift);
                        shiftNumbers.add(shift);
                      }
                    }
                  }
                } catch (e) {
                  shiftNumbers = [];
          // Debug statement removed
                }
              }
              
              // If no selected shift number yet but shifts are available, select the first one
              if (selectedShiftNumber.isEmpty && shiftNumbers.isNotEmpty) {
                selectedShiftNumber = shiftNumbers[0];
              }
            } catch (e) {
          // Debug statement removed
              shiftNumbers = [];
            } finally {
            setState(() {
              isLoading = false;
            });
            }
          }

          // Load shift numbers initially
          if (isLoading) {
            loadShiftNumbers();
          }

          return AlertDialog(
            title: Text('Add Overtime Duty for ${DateFormat('dd/MM/yyyy').format(shiftDate)}'),
            content: SingleChildScrollView( 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Zone:'),
                    const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedZone,
                    isExpanded: true,
                    items: [
                      'Zone 1',
                      'Zone 3',
                      'Zone 4',
                      'Uni/Euro',
                    ].map((zone) {
                      return DropdownMenuItem(
                        value: zone,
                        child: Text(zone),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedZone = value;
                          selectedShiftNumber = '';
                        });
                        loadShiftNumbers();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Shift Number:'),
                  const SizedBox(height: 8),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : shiftNumbers.isEmpty
                          ? const Text('No shifts available for selected zone and date.')
                          : DropdownButton<String>(
                              value: selectedShiftNumber.isEmpty && shiftNumbers.isNotEmpty ? shiftNumbers[0] : selectedShiftNumber,
                              isExpanded: true,
                              items: shiftNumbers.map((shift) {
                                return DropdownMenuItem(
                                  value: shift,
                                  child: Text(overtimeHalfType.isNotEmpty 
                                      ? '$shift$overtimeHalfType' // Add A/B suffix for display
                                      : shift),
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
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                onPressed: shiftNumbers.isEmpty || isLoading
                    ? null
                    : () async {
                        final title = '$selectedShiftNumber$overtimeHalfType (OT)';
                        
                        // Get the shift times
                        Map<String, dynamic>? shiftTimes;
                        if (selectedZone == 'Spare') {
                          // For Spare shifts, parse time from the selectedShiftNumber which is in format "HH:MM"
                          final parts = selectedShiftNumber.split(':');
                          final hour = int.parse(parts[0]);
                          final minute = int.parse(parts[1]);
                          
                          // Default spare shift to 4 hours
                          final startTime = TimeOfDay(hour: hour, minute: minute);
                          final endHour = (hour + 4) % 24; // Wrap around at 24 hours
                          final endTime = TimeOfDay(hour: endHour, minute: minute);
                          
                          shiftTimes = {
                            'startTime': startTime,
                            'endTime': endTime,
                          };
                            } else {
                          // For regular shifts, look up times from CSV
                          shiftTimes = await _getShiftTimes(
                            selectedZone.replaceAll('Zone ', ''),
                            selectedShiftNumber,
                            shiftDate,
                            isOvertimeShift: true, // Pass overtime flag
                          );
                        }
                        
                        if (shiftTimes != null && mounted) {
                          final startTime = shiftTimes['startTime'] as TimeOfDay;
                          TimeOfDay endTime = shiftTimes['endTime'] as TimeOfDay;
                          
                          // Calculate actual start and end times based on overtime half type
                          final shiftDuration = (endTime.hour * 60 + endTime.minute) - 
                                              (startTime.hour * 60 + startTime.minute);
                          
                          TimeOfDay adjustedStartTime;
                          TimeOfDay adjustedEndTime;
                          
                          // Get the day of the week
                          final dayOfWeek = RosterService.getDayOfWeek(shiftDate);

                          // Try to get break times from CSV
                          final csvFilename = selectedZone == 'Uni/Euro' 
                              ? 'UNI_7DAYs.csv'  // UNI shifts - first try 7DAYs
                              : RosterService.getShiftFilename(selectedZone.replaceAll('Zone ', ''), 
                                  dayOfWeek == 'Saturday' ? 'SAT' : 
                                  dayOfWeek == 'Sunday' ? 'SUN' : 'M-F', 
                                  shiftDate);
                          
                          // Variables to hold break times if found
                          TimeOfDay? breakStartTime;
                          TimeOfDay? breakEndTime;
                          
                          try {
                            final csv = await rootBundle.loadString('assets/$csvFilename');
                            final lines = csv.split('\n');
                            
                            // Find the shift in the CSV file
                            for (final line in lines) {
                              if (line.trim().isEmpty) continue;
                              final parts = line.split(',');
                              
                              // Standard PZ files have shift code at index 0
                              // UNI files also have shift code at index 0
                              if (parts.isNotEmpty && parts[0].trim() == selectedShiftNumber) {
                                
                                // Different CSV structures for PZ vs UNI files
                                if (selectedZone == 'Uni/Euro') {
                                  // UNI files: ShiftCode,StartTime,BreakStart,BreakEnd,FinishTime
                                  if (parts.length >= 5) {
                                    final breakStartStr = parts[2].trim();
                                    final breakEndStr = parts[3].trim();
                                    
                                    if (breakStartStr.toLowerCase() != 'nan' && breakEndStr.toLowerCase() != 'nan') {
                                      breakStartTime = _parseTimeOfDay(breakStartStr);
                                      breakEndTime = _parseTimeOfDay(breakEndStr);
                                    }
                                  }
                                } else {
                                  // PZ files: Column 5 is breakStart, column 8 is breakEnd
                                  if (parts.length >= 9) {
                                    final breakStartStr = parts[5].trim();
                                    final breakEndStr = parts[8].trim();
                                    
                                    if (breakStartStr.toLowerCase() != 'nan' && 
                                        breakStartStr.toLowerCase() != 'workout' &&
                                        breakEndStr.toLowerCase() != 'nan' && 
                                        breakEndStr.toLowerCase() != 'workout') {
                                      breakStartTime = _parseTimeOfDay(breakStartStr);
                                      breakEndTime = _parseTimeOfDay(breakEndStr);
                                    }
                                  }
                                }
                                break;
                              }
                            }
                            
                            // For UNI/EURO, if not found in 7DAYs.csv and it's a weekday, check M-F.csv
                            if (selectedZone == 'Uni/Euro' && breakStartTime == null && 
                                dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {
                              final csvMF = await rootBundle.loadString('assets/UNI_M-F.csv');
                              final linesMF = csvMF.split('\n');
                              
                              for (final line in linesMF) {
                                if (line.trim().isEmpty) continue;
                                final parts = line.split(',');
                                
                                if (parts.isNotEmpty && parts[0].trim() == selectedShiftNumber) {
                                  if (parts.length >= 5) {
                                    final breakStartStr = parts[2].trim();
                                    final breakEndStr = parts[3].trim();
                                    
                                    if (breakStartStr.toLowerCase() != 'nan' && breakEndStr.toLowerCase() != 'nan') {
                                      breakStartTime = _parseTimeOfDay(breakStartStr);
                                      breakEndTime = _parseTimeOfDay(breakEndStr);
                                    }
                                  }
                                  break;
                                }
                              }
                            }
                          } catch (e) {
          // Debug statement removed
                          }
                          
                          // Adjust times based on first half (A) or second half (B)
                          if (overtimeHalfType == 'A') { 
                            // First half - use start time and end at break start time if available
                            adjustedStartTime = startTime;
                            
                            if (breakStartTime != null) {
                              // Use actual break start time
                              adjustedEndTime = breakStartTime;
                            } else {
                              // Fall back to midpoint calculation
                              final halfDurationMinutes = shiftDuration ~/ 2;
                              final endHour = (startTime.hour + (halfDurationMinutes ~/ 60)) % 24;
                              final endMinute = (startTime.minute + (halfDurationMinutes % 60)) % 60;
                              adjustedEndTime = TimeOfDay(hour: endHour, minute: endMinute);
                            }
                          } else {
                            // Second half - start at break end time if available and use end time
                            if (breakEndTime != null) {
                              // Use actual break end time
                              adjustedStartTime = breakEndTime;
                            } else {
                              // Fall back to midpoint calculation
                              final halfDurationMinutes = shiftDuration ~/ 2;
                              final startHour = (startTime.hour + (halfDurationMinutes ~/ 60)) % 24;
                              final startMinute = (startTime.minute + (halfDurationMinutes % 60)) % 60;
                              adjustedStartTime = TimeOfDay(hour: startHour, minute: startMinute);
                            }
                            adjustedEndTime = endTime;
                          }
                          
                          // Create the overtime event
                          final event = Event(
                            id: const Uuid().v4(),
                            title: title,
                            startDate: shiftDate,
                            startTime: adjustedStartTime,
                            endDate: shiftDate,
                            endTime: adjustedEndTime,
                            workTime: Duration(
                              hours: (adjustedEndTime.hour - adjustedStartTime.hour) % 24,
                              minutes: (adjustedEndTime.minute - adjustedStartTime.minute) % 60,
                            ),
                          );
                          
                          try {
                            // Add the event
                            await EventService.addEvent(event);
                            
                            // Check if the widget is still mounted
                            if (mounted) {
                              // Close the dialog first
                              Navigator.of(context).pop();
                              
                              // Show a loading indicator while we refresh
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Adding overtime duty...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              
                              // Force reload events for current month
                              await EventService.preloadMonth(_focusedDay);
                              
                              // Force rebuild
                              setState(() {
                                // Trigger a rebuild with explicit re-selection of day
                                _selectedDay = null;
                              });
                              
                              // Small delay
                              await Future.delayed(const Duration(milliseconds: 100));
                              
                              // Set selected day back to event date and rebuild again
                              setState(() {
                                _selectedDay = event.startDate;
                              });
                              
                              // Show confirmation after everything is done
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Overtime duty $title added'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              
                              // The trick: Manually call _editEvent with a special refresh event
                              // This will trigger the event list to rebuild again
                              _editEvent(Event(
                                id: 'refresh_trigger',
                                title: '',
                                startDate: DateTime.now(),
                                startTime: const TimeOfDay(hour: 0, minute: 0),
                                endDate: DateTime.now(),
                                endTime: const TimeOfDay(hour: 0, minute: 0),
                                busAssignments: {},
                              ));
                            }
                          } catch (e) {
          // Debug statement removed
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding overtime: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                child: const Text('Add Overtime Shift'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to check if spare shift has full duties (should use firstHalfBus/secondHalfBus)
  bool _spareShiftHasFullDuties(Event event) {
    if (!event.title.startsWith('SP') || 
        event.assignedDuties == null || 
        event.assignedDuties!.isEmpty) {
      return false;
    }
    
    // Check if any duty is a full duty (doesn't end with A or B)
    for (String duty in event.assignedDuties!) {
      String dutyCode = duty.startsWith('UNI:') ? duty.substring(4) : duty;
      if (!dutyCode.endsWith('A') && !dutyCode.endsWith('B')) {
        return true; // Found a full duty
      }
    }
    return false;
  }
}

// Static banner widget that doesn't rebuild
class _StaticLiveUpdatesBanner extends StatelessWidget {
  const _StaticLiveUpdatesBanner();

  @override
  Widget build(BuildContext context) {
    return LiveUpdatesBanner(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LiveUpdatesDetailsScreen(),
          ),
        );
      },
    );
  }
}
