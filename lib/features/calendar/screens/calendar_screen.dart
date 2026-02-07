import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:spdrivercalendar/services/bus_tracking_service.dart';
import 'package:spdrivercalendar/features/calendar/widgets/event_card.dart';
import 'package:spdrivercalendar/features/calendar/widgets/shift_details_card.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/add_event_dialog.dart';
import 'package:spdrivercalendar/features/statistics/screens/statistics_screen.dart';
import 'package:spdrivercalendar/features/settings/screens/settings_screen.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:flutter/services.dart'; // For rootBundle
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
import 'package:spdrivercalendar/features/timing_points/screens/timing_points_screen.dart'; // Import the Timing Points screen
import 'package:spdrivercalendar/features/calendar/screens/week_view_screen.dart'; // Import the Week View screen
import 'package:spdrivercalendar/features/calendar/screens/year_view_screen.dart'; // Import the Year View screen
import 'package:spdrivercalendar/features/search/screens/search_screen.dart'; // Import the Search screen
import 'package:uuid/uuid.dart';
import 'package:spdrivercalendar/services/update_service.dart';
import 'package:spdrivercalendar/core/widgets/enhanced_update_dialog.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';
import '../../../widgets/live_updates_banner.dart';
import '../../../screens/live_updates_details_screen.dart';
import '../../../services/live_updates_service.dart';
import '../../../models/live_update.dart';
import '../../../services/universal_board_service.dart';
import '../../../models/universal_board.dart';
import '../../../services/days_in_lieu_service.dart';
import '../../../services/annual_leave_service.dart';
import '../../../services/self_certified_sick_days_service.dart';
import '../dialogs/days_in_lieu_setup_dialog.dart';
import '../dialogs/annual_leave_setup_dialog.dart';

// Add this new widget class before the CalendarScreen class
class _StableLiveUpdatesBanner extends StatefulWidget {
  final VoidCallback onTap;

  const _StableLiveUpdatesBanner({
    required this.onTap,
  });

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

  const CalendarScreen(this.isDarkModeNotifier, {super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  DateTime? _startDate;
  int _startWeek = 0;
  List<BankHoliday>? _bankHolidays;
  List<Holiday> _holidays = [];
  late AnimationController _animationController;
  bool _hasCheckedForUpdatesOnStartup = false;
  final Map<String, bool> _busTrackingLoading = {};
  final ScrollController _scrollController = ScrollController();
  
  late Map<String, ShiftInfo> _shiftInfoMap;
  
  // Marked In settings
  bool _markedInEnabled = false;
  String _markedInStatus = 'Shift';
  
  // Display settings
  bool _showDutyCodesOnCalendar = true; // Default to true (ON)
  bool _animatedSelectedDay = true; // Default to true (ON) - animated border

  // Holiday section expanded state (year -> expanded)
  final Map<int, bool> _holidayYearExpanded = {};

  // Add holiday color constant
  static const Color holidayColor = Color(0xFF00BCD4); // Teal color for holidays

  void _initializeShiftColors() {
    final colors = ColorCustomizationService.getShiftColors();
    _shiftInfoMap = {
      'E': ShiftInfo('Early', colors['E']!),
      'L': ShiftInfo('Late', colors['L']!),
      'M': ShiftInfo('Middle', colors['M']!),
      'R': ShiftInfo('Rest', colors['R']!),
      'W': ShiftInfo('Work', colors['W']!), // Use Work color from customization service
      'WFO': ShiftInfo('Work For Others', colors['WFO']!), // Work For Others color
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
    _loadMarkedInSettings();
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
    
    // Check if user needs to set days in lieu balance
    _checkDaysInLieuSetup();
  }

  Future<void> _checkDaysInLieuSetup() async {
    // Wait a bit for the screen to fully load
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final hasSetDaysInLieu = await DaysInLieuService.hasSetInitialBalance();
    final hasSetAnnualLeave = await AnnualLeaveService.hasSetInitialBalance();
    
    if (!hasSetDaysInLieu && mounted) {
      // Show the days in lieu setup dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DaysInLieuSetupDialog(),
      );
    }
    
    // Wait a bit before showing annual leave dialog
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!hasSetAnnualLeave && mounted) {
      // Show the annual leave setup dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnnualLeaveSetupDialog(),
      );
    }
  }

  Future<void> _loadMarkedInSettings() async {
    if (!mounted) return;
    
    final markedInEnabled = await StorageService.getBool(AppConstants.markedInEnabledKey);
    final markedInStatus = await StorageService.getString(AppConstants.markedInStatusKey) ?? '';
    
    // Determine if marked-in is actually enabled (enabled flag must be true AND status must not be empty)
    final newMarkedInEnabled = markedInEnabled && markedInStatus.isNotEmpty;
    final newMarkedInStatus = markedInStatus.isEmpty ? 'Spare' : markedInStatus;
    final newShowDutyCodes = await StorageService.getBool(AppConstants.showDutyCodesOnCalendarKey, defaultValue: true);
    final newAnimatedSelectedDay = await StorageService.getBool(AppConstants.animatedSelectedDayKey, defaultValue: true);
    
    // Always update state to ensure calendar rebuilds with latest settings
    if (mounted) {
      final needsUpdate = _markedInEnabled != newMarkedInEnabled || 
                         _markedInStatus != newMarkedInStatus ||
                         _showDutyCodesOnCalendar != newShowDutyCodes ||
                         _animatedSelectedDay != newAnimatedSelectedDay;
      _markedInEnabled = newMarkedInEnabled;
      _markedInStatus = newMarkedInStatus;
      _showDutyCodesOnCalendar = newShowDutyCodes;
      _animatedSelectedDay = newAnimatedSelectedDay;
      
      if (needsUpdate) {
        setState(() {});
      }
    }
  }

  Future<void> _scheduleAutomaticUpdateCheck() async {
    // Check for updates immediately when calendar loads - no delay
    
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
    const cacheKey = 'holidays_list_cache'; // Changed to avoid conflict with StorageService cache
    
    // Try to get from cache first
    final cached = cacheService.get<List<Holiday>>(cacheKey);
    if (cached != null) return cached;
    
    // If not in cache, load from service
    final holidays = await HolidayService.getHolidays();
    
    // Cache the results for 24 hours
    cacheService.set(cacheKey, holidays, expiration: const Duration(hours: 24));
    
    return holidays;
  }

  // Reload holidays from storage (bypasses cache)
  Future<void> _reloadHolidays() async {
    try {
      // CRITICAL FIX: Explicitly invalidate the calendar's cache before reloading
      const cacheKey = 'holidays_list_cache'; // Changed to match the new cache key
      final cacheService = CacheService();
      cacheService.remove(cacheKey);
      
      // Also clear StorageService cache to ensure fresh data
      StorageService.clearCacheForKey('holidays');
      
      final holidays = await HolidayService.getHolidays();
      if (mounted) {
        setState(() {
          _holidays = holidays;
        });
      }
    } catch (e) {
      // Handle error gracefully - but log it for debugging
      debugPrint('Error reloading holidays: $e');
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload marked in settings when screen becomes visible again
    // This is called when navigating back to the screen
    _loadMarkedInSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload marked in settings when app comes back to foreground
      _loadMarkedInSettings();
    }
  }
  
  // Calculate the shift for a given date
  String getShiftForDate(DateTime date) {
    if (_startDate == null) return '';
    
    // Check if marked in is enabled
    if (_markedInEnabled) {
      // M-F marked in logic: W on Mon-Fri, R on Sat-Sun
      // Bank holidays are REST days for M-F
      if (_markedInStatus == 'M-F') {
        // Check if this is a bank holiday
        final bankHoliday = getBankHoliday(date);
        if (bankHoliday != null) {
          // If M-F marked in is enabled, bank holidays are always R (Rest)
          return 'R';
        }
        
        // weekday: 1=Monday, 2=Tuesday, ..., 6=Saturday, 7=Sunday
        final weekday = date.weekday;
        if (weekday >= 1 && weekday <= 5) {
          return 'W'; // Work days Mon-Fri
        } else {
          return 'R'; // Rest days Sat-Sun
        }
      }
      
      // Shift marked in: use normal roster calculation
      // (Zone selection is stored but doesn't affect shift calculation here)
      if (_markedInStatus == 'Shift') {
        return RosterService.getShiftForDate(date, _startDate!, _startWeek);
      }
    }
    
    // Default or normal roster calculation
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
          String holidayTitle;
          switch (holiday.type) {
            case 'winter':
              holidayTitle = 'Winter Holiday';
              break;
            case 'summer':
              holidayTitle = 'Summer Holiday';
              break;
            case 'unpaid_leave':
              holidayTitle = 'Unpaid Leave';
              break;
            case 'day_in_lieu':
              holidayTitle = 'Day In Lieu';
              break;
            case 'other':
            default:
              holidayTitle = 'Other Holiday';
          }
          
          final holidayEvent = Event(
            id: 'holiday_${holiday.id}_${day.millisecondsSinceEpoch}',
            title: holidayTitle,
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
            // Only show Work For Others button on rest days
            if (getShiftForDate(_selectedDay ?? DateTime.now()) == 'R')
              TextButton(
                child: const Text('Work For Others'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showWorkForOthersDialog();
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
  void _showWorkShiftDialog() async {
    final now = DateTime.now();
    final shiftDate = _selectedDay ?? now;
    
    // Check if user is M-F marked in and if it's a weekday
    bool isMFMarkedIn = false;
    // Check if user is marked-in on Shift status and get their zone
    bool isShiftMarkedIn = false;
    String markedInZone = '';
    
    try {
      final markedInEnabled = await StorageService.getBool(AppConstants.markedInEnabledKey);
      final markedInStatus = await StorageService.getString(AppConstants.markedInStatusKey) ?? '';
      isMFMarkedIn = markedInEnabled && markedInStatus == 'M-F';
      
      // Check if marked-in on Shift status
      if (markedInEnabled && markedInStatus == 'Shift') {
        isShiftMarkedIn = true;
        markedInZone = await StorageService.getString(AppConstants.markedInZoneKey) ?? 'Zone 1';
      }
    } catch (e) {
      // If we can't check, default to false
      isMFMarkedIn = false;
      isShiftMarkedIn = false;
      markedInZone = '';
    }
    
    // Check if widget is still mounted after async operations
    if (!mounted) return;
    
    // Show dialog with loading state initially
    showDialog(
      context: context,
      builder: (dialogContext) {
        String selectedZone = 'Zone 1';
        String selectedShiftNumber = '';
        List<String> shiftNumbers = [];
        bool isLoading = true;
        // For M-F Uni/Euro repeat feature
        bool repeatUniEuroThisWeek = false;
        Map<int, bool> uniEuroSelectedDays = {
          0: false, // Sunday
          1: false, // Monday
          2: false, // Tuesday
          3: false, // Wednesday
          4: false, // Thursday
          5: false, // Friday
          6: false, // Saturday
        };
        Map<int, bool> uniEuroDisabledDays = {
          0: false, // Sunday
          1: false, // Monday
          2: false, // Tuesday
          3: false, // Wednesday
          4: false, // Thursday
          5: false, // Friday
          6: false, // Saturday
        };
        // For marked-in zone repeat feature
        bool repeatDutyThisWeek = false;
        Map<int, bool> selectedDays = {
          0: false, // Sunday
          1: false, // Monday
          2: false, // Tuesday
          3: false, // Wednesday
          4: false, // Thursday
          5: false, // Friday
          6: false, // Saturday
        };
        Map<int, bool> disabledDays = {
          0: false, // Sunday
          1: false, // Monday
          2: false, // Tuesday
          3: false, // Wednesday
          4: false, // Thursday
          5: false, // Friday
          6: false, // Saturday
        };
        
        return StatefulBuilder(
          builder: (context, setState) {
          // Function to load shift numbers for selected zone
          void loadShiftNumbers() async {
            // Skip loading for 22B/01 as it's a fixed duty
            if (selectedZone == '22B/01') {
              setState(() {
                shiftNumbers = [];
                selectedShiftNumber = '';
                isLoading = false;
              });
              return;
            }
            
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
                  
                  // Skip header line and load duty codes
                  for (var i = 1; i < lines.length; i++) {
                    if (lines[i].trim().isEmpty) continue;
                    final parts = lines[i].split(',');
                    if (parts.isNotEmpty) {
                      // For regular work shifts, include ALL duties (including workouts)
                      combinedShifts.add(parts[0]);
                    }
                  }
                } catch (e) {
                  // Silently handle CSV parsing errors - file may not exist or be malformed
                }
                
                // On weekdays, also load from UNI_M-F.csv
                if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {
                  try {
                    final csv = await rootBundle.loadString('assets/UNI_M-F.csv');
                    final lines = csv.split('\n');
                    
                    // Skip header line and load duty codes
                    for (var i = 1; i < lines.length; i++) {
                      if (lines[i].trim().isEmpty) continue;
                      final parts = lines[i].split(',');
                      if (parts.isNotEmpty) {
                        // For regular work shifts, include ALL duties (including workouts)
                        combinedShifts.add(parts[0]);
                      }
                    }
                  } catch (e) {
                    // Silently handle CSV parsing errors - file may not exist or be malformed
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
                  }
                }
              } else if (selectedZone == 'Training') {
                // Load Training shifts from training_duties.csv
                // Exclude EA Type Training shifts (they are overtime-only)
                try {
                  final csv = await rootBundle.loadString('assets/training_duties.csv');
                  final lines = csv.split('\n');
                  shiftNumbers = [];
                  final seenShifts = <String>{};
                  
                  // Skip header line and collect all shift codes
                  for (int i = 1; i < lines.length; i++) {
                    final line = lines[i].trim().replaceAll('\r', '');
                    if (line.isEmpty) continue;
                    final parts = line.split(',');
                    if (parts.isNotEmpty) {
                      final shift = parts[0].trim();
                      // Exclude EA Type Training shifts (overtime-only)
                      if (shift.contains('EA Type Training')) {
                        continue;
                      }
                      if (shift.isNotEmpty && !seenShifts.contains(shift)) {
                        shiftNumbers.add(shift);
                        seenShifts.add(shift);
                      }
                    }
                  }
                } catch (e) {
                  shiftNumbers = [];
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
                }
              }
              
              // If no selected shift number yet but shifts are available, select the first one
              if (selectedShiftNumber.isEmpty && shiftNumbers.isNotEmpty) {
                selectedShiftNumber = shiftNumbers[0];
              }
            } catch (e) {
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const Text('Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedZone,
                  isExpanded: true,
                  items: () {
                    final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
                    List<String> zones = [
                      'Zone 1',
                      'Zone 3',
                      'Zone 4',
                    ];
                    
                    // Add 22B/01 right after Zone 4 for Sundays only
                    if (dayOfWeek == 'Sunday') {
                      zones.add('22B/01');
                    }
                    
                    // Add remaining zones
                    zones.addAll([
                      'Spare',
                      'Uni/Euro',
                      'Bus Check',
                    ]);
                    
                    // Add Jamestown Road only for Mon-Fri
                    if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {
                      zones.add('Jamestown Road');
                    }
                    
                    // Add Training only for Mon-Sat (not Sunday)
                    if (dayOfWeek != 'Sunday') {
                      zones.add('Training');
                    }
                    
                    return zones;
                  }().map((zone) {
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
                // Handle 22B/01 special case - no shift selection needed
                selectedZone == '22B/01'
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                      child: const Text(
                        'Fixed Duty - No shift selection required',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : isLoading
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
                // Show checkbox for M-F marked in users selecting Uni/Euro (not on weekends)
                Builder(
                  builder: (context) {
                    final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
                    final isWeekend = dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday';
                    final shouldShowRepeatCheckbox = isMFMarkedIn && selectedZone == 'Uni/Euro' && !isWeekend;
                    if (shouldShowRepeatCheckbox) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: repeatUniEuroThisWeek,
                                onChanged: (value) async {
                                  setState(() {
                                    repeatUniEuroThisWeek = value ?? false;
                                  });
                                  
                                  if (repeatUniEuroThisWeek) {
                                    // When checking, check which weekdays already have work shifts
                                    // Get the start of the week (Sunday)
                                    final weekday = shiftDate.weekday; // 1=Monday, 7=Sunday
                                    final daysToSunday = weekday == 7 ? 0 : weekday;
                                    final weekStart = shiftDate.subtract(Duration(days: daysToSunday));
                                    
                                    // Check each weekday (Monday-Friday, indices 1-5) for existing work shifts
                                    final newDisabledDays = <int, bool>{};
                                    for (int dayIndex = 1; dayIndex <= 5; dayIndex++) {
                                      final targetDate = weekStart.add(Duration(days: dayIndex));
                                      final existingEvents = EventService.getEventsForDay(targetDate);
                                      
                                      // Check if there's a work shift (non-holiday event) on this day
                                      final hasWorkShift = existingEvents.any((e) => !e.isHoliday);
                                      newDisabledDays[dayIndex] = hasWorkShift;
                                    }
                                    
                                    setState(() {
                                      uniEuroDisabledDays = newDisabledDays;
                                      
                                      // Automatically select the current day if it's not disabled (only for weekdays)
                                      if (weekday >= 1 && weekday <= 5) {
                                        if (!(uniEuroDisabledDays[weekday] ?? false)) {
                                          uniEuroSelectedDays[weekday] = true;
                                        }
                                      }
                                    });
                                  } else {
                                    // If unchecking, clear all selected days and disabled days
                                    setState(() {
                                      uniEuroSelectedDays = {
                                        0: false, 1: false, 2: false, 3: false,
                                        4: false, 5: false, 6: false,
                                      };
                                      uniEuroDisabledDays = {
                                        0: false, 1: false, 2: false, 3: false,
                                        4: false, 5: false, 6: false,
                                      };
                                    });
                                  }
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Would you like to repeat this shift this week?',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          if (repeatUniEuroThisWeek) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildDayToggle(context, setState, 1, 'M', uniEuroSelectedDays[1] ?? false, uniEuroSelectedDays, uniEuroDisabledDays[1] ?? false),
                                _buildDayToggle(context, setState, 2, 'T', uniEuroSelectedDays[2] ?? false, uniEuroSelectedDays, uniEuroDisabledDays[2] ?? false),
                                _buildDayToggle(context, setState, 3, 'W', uniEuroSelectedDays[3] ?? false, uniEuroSelectedDays, uniEuroDisabledDays[3] ?? false),
                                _buildDayToggle(context, setState, 4, 'T', uniEuroSelectedDays[4] ?? false, uniEuroSelectedDays, uniEuroDisabledDays[4] ?? false),
                                _buildDayToggle(context, setState, 5, 'F', uniEuroSelectedDays[5] ?? false, uniEuroSelectedDays, uniEuroDisabledDays[5] ?? false),
                              ],
                            ),
                          ],
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Show checkbox for marked-in Shift users when zone matches (not on weekends)
                Builder(
                  builder: (context) {
                    final dayOfWeek = RosterService.getDayOfWeek(shiftDate);
                    final isWeekend = dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday';
                    final shouldShowRepeatCheckbox = isShiftMarkedIn && 
                        (selectedZone == 'Zone 1' || selectedZone == 'Zone 3' || selectedZone == 'Zone 4') &&
                        selectedZone == markedInZone &&
                        !isWeekend;
                    if (shouldShowRepeatCheckbox) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: repeatDutyThisWeek,
                                onChanged: (value) async {
                                  setState(() {
                                    repeatDutyThisWeek = value ?? false;
                                  });
                                  
                                  if (repeatDutyThisWeek) {
                                    // When checking, check which weekdays already have work shifts
                                    // Get the start of the week (Sunday)
                                    final weekday = shiftDate.weekday; // 1=Monday, 7=Sunday
                                    final daysToSunday = weekday == 7 ? 0 : weekday;
                                    final weekStart = shiftDate.subtract(Duration(days: daysToSunday));
                                    
                                    // Check each weekday (Monday-Friday, indices 1-5) for existing work shifts
                                    final newDisabledDays = <int, bool>{};
                                    for (int dayIndex = 1; dayIndex <= 5; dayIndex++) {
                                      final targetDate = weekStart.add(Duration(days: dayIndex));
                                      final existingEvents = EventService.getEventsForDay(targetDate);
                                      
                                      // Check if there's a work shift (non-holiday event) on this day
                                      final hasWorkShift = existingEvents.any((e) => !e.isHoliday);
                                      newDisabledDays[dayIndex] = hasWorkShift;
                                    }
                                    
                                    setState(() {
                                      disabledDays = newDisabledDays;
                                      
                                      // Automatically select the current day if it's not disabled (only for weekdays)
                                      if (weekday >= 1 && weekday <= 5) {
                                        if (!(disabledDays[weekday] ?? false)) {
                                          selectedDays[weekday] = true;
                                        }
                                      }
                                    });
                                  } else {
                                    // If unchecking, clear all selected days and disabled days
                                    setState(() {
                                      selectedDays = {
                                        0: false, 1: false, 2: false, 3: false,
                                        4: false, 5: false, 6: false,
                                      };
                                      disabledDays = {
                                        0: false, 1: false, 2: false, 3: false,
                                        4: false, 5: false, 6: false,
                                      };
                                    });
                                  }
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Would you like to repeat this duty this week?',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          if (repeatDutyThisWeek) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildDayToggle(context, setState, 1, 'M', selectedDays[1] ?? false, selectedDays, disabledDays[1] ?? false),
                                _buildDayToggle(context, setState, 2, 'T', selectedDays[2] ?? false, selectedDays, disabledDays[2] ?? false),
                                _buildDayToggle(context, setState, 3, 'W', selectedDays[3] ?? false, selectedDays, disabledDays[3] ?? false),
                                _buildDayToggle(context, setState, 4, 'T', selectedDays[4] ?? false, selectedDays, disabledDays[4] ?? false),
                                _buildDayToggle(context, setState, 5, 'F', selectedDays[5] ?? false, selectedDays, disabledDays[5] ?? false),
                              ],
                            ),
                          ],
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading || (selectedZone != '22B/01' && (shiftNumbers.isEmpty || selectedShiftNumber.isEmpty))
                  ? null  // Disable button if loading or no shifts available (except for 22B/01)
                  : () async {
                      // Create title based on zone and shift
                      String title = '';
                      // For 22B/01 Sunday duty
                      if (selectedZone == '22B/01') {
                        title = '22B/01';
                      } else if (selectedZone == 'Spare') {
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
                      } else if (selectedZone == 'Training') {
                        title = selectedShiftNumber; // Use the training code (e.g., CPC)
                      } else {
                        // Regular PZ shifts
                        title = selectedShiftNumber; // Title is the shift code (e.g., PZ1/01)
                      }
                      
                      // Load shift times based on zone
                      Map<String, dynamic>? shiftTimes;
                      
                      if (selectedZone == '22B/01') {
                        // Fixed times for 22B/01: 04:30 start, 8h 38m duration (same as spare duties)
                        shiftTimes = {
                          'startTime': const TimeOfDay(hour: 4, minute: 30),
                          'endTime': const TimeOfDay(hour: 13, minute: 8), // 04:30 + 8h 38m = 13:08
                        };
                      } else if (selectedZone == 'Spare') {
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
                      } else if (selectedZone == 'Training') {
                        // For Training, load from training_duties.csv
                        shiftTimes = await _getShiftTimes(selectedZone, selectedShiftNumber, shiftDate);
                      } else {
                        // For other zones, load from CSV
                        shiftTimes = await _getShiftTimes(selectedZone, selectedShiftNumber, shiftDate);
                      }
                      
                      // Handle potential null shiftTimes (error loading CSV etc.)
                      if (shiftTimes == null) {
                         // Could not retrieve shift times
                         if (!mounted) return;
                         ScaffoldMessenger.of(dialogContext).showSnackBar(
                           const SnackBar(content: Text('Error retrieving shift times. Please try again.')),
                         );
                         return; // Stop execution if times are null
                      }
                      
                      // Create the event with non-null assurances, including break times, work time, and routes
                      final event = Event(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        startDate: shiftDate,
                        startTime: shiftTimes['startTime']!,
                        endDate: shiftTimes['isNextDay'] == true
                            ? shiftDate.add(const Duration(days: 1))  // Next day
                            : shiftDate,
                        endTime: shiftTimes['endTime']!,
                        breakStartTime: shiftTimes['breakStartTime'] as TimeOfDay?,
                        breakEndTime: shiftTimes['breakEndTime'] as TimeOfDay?,
                        workTime: shiftTimes['workTime'] as Duration?,
                        routes: shiftTimes['routes'] as List<String>?,
                      );
                      
                      // Add event and close dialog
                      await EventService.addEvent(event);
                      
                      // If repeat Uni/Euro this week is checked for M-F marked-in users, create events for selected days
                      if (repeatUniEuroThisWeek && isMFMarkedIn && selectedZone == 'Uni/Euro') {
                        // Get the start of the week (Sunday)
                        final weekday = shiftDate.weekday; // 1=Monday, 7=Sunday
                        // Calculate days to subtract to get to Sunday (weekday 7)
                        final daysToSunday = weekday == 7 ? 0 : weekday;
                        final weekStart = shiftDate.subtract(Duration(days: daysToSunday));
                        
                        // Loop through weekdays only (Monday-Friday, indices 1-5)
                        for (int dayIndex = 1; dayIndex <= 5; dayIndex++) {
                          // Skip if this day is not selected
                          if (!(uniEuroSelectedDays[dayIndex] ?? false)) {
                            continue;
                          }
                          
                          final targetDate = weekStart.add(Duration(days: dayIndex));
                          
                          // Skip if it's the same day (already handled above)
                          if (targetDate.year == shiftDate.year &&
                              targetDate.month == shiftDate.month &&
                              targetDate.day == shiftDate.day) {
                            continue;
                          }
                          
                          // Check if an event with the same title already exists on this day
                          final existingEvents = EventService.getEventsForDay(targetDate);
                          final duplicateExists = existingEvents.any((e) => e.title == title);
                          
                          if (duplicateExists) {
                            // Skip this day - event already exists
                            continue;
                          }
                          
                          // Check if there's a bank holiday on this day
                          final bankHoliday = ShiftService.getBankHoliday(targetDate, ShiftService.bankHolidays);
                          if (bankHoliday != null) {
                            continue; // Skip bank holidays
                          }
                          
                          // Get shift times for this day (may differ for different days)
                          Map<String, dynamic>? targetShiftTimes;
                          if (selectedZone == 'Uni/Euro') {
                            targetShiftTimes = await _getShiftTimes(selectedZone, selectedShiftNumber, targetDate);
                          }
                          
                          // Use the same shift times if available, otherwise use original
                          final finalShiftTimes = targetShiftTimes ?? shiftTimes;
                          
                          // Create event for this day
                          final weekEvent = Event(
                            id: '${title}_${targetDate.millisecondsSinceEpoch}',
                            title: title,
                            startDate: targetDate,
                            startTime: finalShiftTimes['startTime']!,
                            endDate: finalShiftTimes['isNextDay'] == true
                                ? targetDate.add(const Duration(days: 1))
                                : targetDate,
                            endTime: finalShiftTimes['endTime']!,
                            breakStartTime: finalShiftTimes['breakStartTime'] as TimeOfDay?,
                            breakEndTime: finalShiftTimes['breakEndTime'] as TimeOfDay?,
                            workTime: finalShiftTimes['workTime'] as Duration?,
                            routes: finalShiftTimes['routes'] as List<String>?,
                          );
                          
                          await EventService.addEvent(weekEvent);
                          
                          // Sync to Google if enabled
                          if (!mounted) return;
                          _checkAndSyncToGoogleCalendar(weekEvent, context);
                        }
                      }
                      
                      // If repeat duty this week is checked for marked-in zone users, create events for selected days
                      if (repeatDutyThisWeek && isShiftMarkedIn && 
                          (selectedZone == 'Zone 1' || selectedZone == 'Zone 3' || selectedZone == 'Zone 4') &&
                          selectedZone == markedInZone) {
                        // Get the start of the week (Sunday)
                        final weekday = shiftDate.weekday; // 1=Monday, 7=Sunday
                        // Calculate days to subtract to get to Sunday (weekday 7)
                        final daysToSunday = weekday == 7 ? 0 : weekday;
                        final weekStart = shiftDate.subtract(Duration(days: daysToSunday));
                        
                        // Loop through weekdays only (Monday-Friday, indices 1-5)
                        for (int dayIndex = 1; dayIndex <= 5; dayIndex++) {
                          // Skip if this day is not selected
                          if (!(selectedDays[dayIndex] ?? false)) {
                            continue;
                          }
                          
                          final targetDate = weekStart.add(Duration(days: dayIndex));
                          
                          // Skip if it's the same day (already handled above)
                          if (targetDate.year == shiftDate.year &&
                              targetDate.month == shiftDate.month &&
                              targetDate.day == shiftDate.day) {
                            continue;
                          }
                          
                          // Check if an event with the same title already exists on this day
                          final existingEvents = EventService.getEventsForDay(targetDate);
                          final duplicateExists = existingEvents.any((e) => e.title == title);
                          
                          if (duplicateExists) {
                            // Skip this day - event already exists
                            continue;
                          }
                          
                          // Get shift times for this day (may differ for different days)
                          Map<String, dynamic>? targetShiftTimes;
                          if (selectedZone == 'Zone 1' || selectedZone == 'Zone 3' || selectedZone == 'Zone 4') {
                            targetShiftTimes = await _getShiftTimes(selectedZone, selectedShiftNumber, targetDate);
                          }
                          
                          // Use the same shift times if available, otherwise use original
                          final finalShiftTimes = targetShiftTimes ?? shiftTimes;
                          
                          // Create event for this day
                          final repeatEvent = Event(
                            id: '${title}_${targetDate.millisecondsSinceEpoch}',
                            title: title,
                            startDate: targetDate,
                            startTime: finalShiftTimes['startTime']!,
                            endDate: finalShiftTimes['isNextDay'] == true
                                ? targetDate.add(const Duration(days: 1))
                                : targetDate,
                            endTime: finalShiftTimes['endTime']!,
                            breakStartTime: finalShiftTimes['breakStartTime'] as TimeOfDay?,
                            breakEndTime: finalShiftTimes['breakEndTime'] as TimeOfDay?,
                            workTime: finalShiftTimes['workTime'] as Duration?,
                            routes: finalShiftTimes['routes'] as List<String>?,
                          );
                          
                          await EventService.addEvent(repeatEvent);
                          
                          // Sync to Google if enabled
                          if (!mounted) return;
                          _checkAndSyncToGoogleCalendar(repeatEvent, context);
                        }
                      }
                      
                      if (!mounted) return;
                      Navigator.of(dialogContext).pop();
                      
                      // Sync to Google if enabled (before any other async operations)
                      if (!mounted) return;
                      _checkAndSyncToGoogleCalendar(event, context);
                      
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
        );
      },
    );
  }

  // Show dialog to select and add a Work For Others shift (only on rest days)
  void _showWorkForOthersDialog() {
    final now = DateTime.now();
    final shiftDate = _selectedDay ?? now;
    
    // Validate that this is a rest day
    final String shiftType = getShiftForDate(shiftDate);
    if (shiftType != 'R') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work For Others can only be added on rest days.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
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
              
              // Handle different zones
              if (selectedZone == 'Uni/Euro') {
                // Uni/Euro shifts - use both files on weekdays, only 7DAYs on weekends
                List<String> combinedShifts = [];
                
                // Always load from UNI_7DAYs.csv first
                try {
                  final csv = await rootBundle.loadString('assets/UNI_7DAYs.csv');
                  final lines = csv.split('\n');
                  
                  // Skip header line and load duty codes
                  for (var i = 1; i < lines.length; i++) {
                    if (lines[i].trim().isEmpty) continue;
                    final parts = lines[i].split(',');
                    if (parts.isNotEmpty) {
                      combinedShifts.add(parts[0]);
                    }
                  }
                } catch (e) {
                  // Silently handle CSV parsing errors
                }
                
                // On weekdays, also load from UNI_M-F.csv
                if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {
                  try {
                    final csv = await rootBundle.loadString('assets/UNI_M-F.csv');
                    final lines = csv.split('\n');
                    
                    // Skip header line and load duty codes
                    for (var i = 1; i < lines.length; i++) {
                      if (lines[i].trim().isEmpty) continue;
                      final parts = lines[i].split(',');
                      if (parts.isNotEmpty) {
                        combinedShifts.add(parts[0]);
                      }
                    }
                  } catch (e) {
                    // Silently handle CSV parsing errors
                  }
                }
                
                // Keep only unique shifts while preserving order
                shiftNumbers = [];
                final seenShifts = <String>{};
                for (final shift in combinedShifts) {
                  if (!seenShifts.contains(shift)) {
                    seenShifts.add(shift);
                    shiftNumbers.add(shift);
                  }
                }
              } else {
                // Regular zone shifts (Zone 1, 3, 4)
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
                      
                      if (!seenShifts.contains(shift) && shift != "shift") {
                        seenShifts.add(shift);
                        shiftNumbers.add(shift);
                      }
                    }
                  }
                } catch (e) {
                  shiftNumbers = [];
                }
              }
              
              // If no selected shift number yet but shifts are available, select the first one
              if (selectedShiftNumber.isEmpty && shiftNumbers.isNotEmpty) {
                selectedShiftNumber = shiftNumbers[0];
              }
            } catch (e) {
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
            title: Text('Add Work For Others for ${DateFormat('EEE, MMM d').format(shiftDate)}'),
            content: SingleChildScrollView(
              child: Column(
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
                  const Text('Shift Number:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        // Validate rest day again before saving
                        final String currentShiftType = getShiftForDate(shiftDate);
                        if (currentShiftType != 'R') {
                          if (!mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Work For Others can only be added on rest days.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        // Format title as "PZ1/12" or "807/20" etc. (no WFO suffix - badge provides identification)
                        String title = selectedShiftNumber;
                        // Ensure proper format - if it doesn't start with PZ, add it for zones
                        if (selectedZone != 'Uni/Euro' && !title.startsWith('PZ')) {
                          final zoneNum = selectedZone.replaceAll('Zone ', '');
                          title = 'PZ$zoneNum/$title';
                        }
                        // Don't add WFO to title - the badge is enough for identification
                        
                        // Get shift times
                        Map<String, dynamic>? shiftTimes;
                        if (selectedZone == 'Uni/Euro') {
                          shiftTimes = await _getShiftTimes(selectedZone, selectedShiftNumber, shiftDate);
                        } else {
                          shiftTimes = await _getShiftTimes(selectedZone.replaceAll('Zone ', ''), selectedShiftNumber, shiftDate);
                        }
                        
                        // Handle potential null shiftTimes
                        if (shiftTimes == null) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Error retrieving shift times. Please try again.')),
                          );
                          return;
                        }
                        
                        // Create the event with isWorkForOthers = true
                        final event = Event(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          startDate: shiftDate,
                          startTime: shiftTimes['startTime']!,
                          endDate: shiftTimes['isNextDay'] == true
                              ? shiftDate.add(const Duration(days: 1))
                              : shiftDate,
                          endTime: shiftTimes['endTime']!,
                          breakStartTime: shiftTimes['breakStartTime'] as TimeOfDay?,
                          breakEndTime: shiftTimes['breakEndTime'] as TimeOfDay?,
                          workTime: shiftTimes['workTime'] as Duration?,
                          routes: shiftTimes['routes'] as List<String>?,
                          isWorkForOthers: true,
                        );
                        
                        // Add event and close dialog
                        await EventService.addEvent(event);
                        if (!mounted) return;
                        Navigator.of(dialogContext).pop();
                        
                        // Sync to Google if enabled
                        if (!mounted) return;
                        _checkAndSyncToGoogleCalendar(event, context);
                        
                        // Force UI refresh
                        if (mounted) {
                          await EventService.preloadMonth(_focusedDay);
                          setState(() {});
                          
                          // Force complete refresh
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
    } else if (zone == 'Training') {
      csvPath = 'assets/training_duties.csv';
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
                bool headerSkippedGetShift = false;
                for (final line in lines) {
                    if (line.trim().isEmpty) continue;
                    
                    // Skip header row
                    if (!headerSkippedGetShift) {
                      headerSkippedGetShift = true;
                      continue;
                    }
                    
                    final parts = line.split(',');
                    if (parts.length >= 15 && parts[0].trim() == shiftNumber) {
                        
                        // New 17-column format: shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,routes
                        final startTimeRaw = parts.length > 2 ? parts[2].trim() : '';
                        final endTimeRaw = parts.length > 10 ? parts[10].trim() : '';
                        
                        if (startTimeRaw.isNotEmpty && endTimeRaw.isNotEmpty) {
                          final startTime = _parseTimeOfDay(startTimeRaw);
                          final endTime = _parseTimeOfDay(endTimeRaw);
                          
                          if (startTime != null && endTime != null) {
                              final isNextDay = endTime.hour < startTime.hour || 
                                                (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
                              
                              // Extract break times
                              // UNI format: shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,routes
                              // So startbreak is column 5, finishbreak is column 8
                              TimeOfDay? breakStart;
                              TimeOfDay? breakEnd;
                              final uniStartBreak = parts.length > 5 ? parts[5].trim() : '';
                              final uniFinishBreak = parts.length > 8 ? parts[8].trim() : '';
                              
                              final isWorkout = uniStartBreak.toLowerCase() == 'nan' || 
                                               uniStartBreak.toLowerCase() == 'workout' ||
                                               uniStartBreak.isEmpty ||
                                               uniFinishBreak.toLowerCase() == 'nan' ||
                                               uniFinishBreak.toLowerCase() == 'workout' ||
                                               uniFinishBreak.isEmpty ||
                                               uniStartBreak == uniFinishBreak;
                              
                              if (!isWorkout) {
                                breakStart = _parseTimeOfDay(uniStartBreak);
                                breakEnd = _parseTimeOfDay(uniFinishBreak);
                              }
                              
                              // Extract work time (column 14)
                              Duration? workTime;
                              final workTimeStr = parts.length > 14 ? parts[14].trim() : '';
                              if (workTimeStr.isNotEmpty && workTimeStr.toLowerCase() != 'nan') {
                                final timeParts = workTimeStr.split(':');
                                if (timeParts.length >= 2) {
                                  final hours = int.tryParse(timeParts[0]);
                                  final minutes = int.tryParse(timeParts[1]);
                                  if (hours != null && minutes != null) {
                                    workTime = Duration(hours: hours, minutes: minutes);
                                  }
                                }
                              }
                              
                              // Extract routes (column 16)
                              List<String> routes = [];
                              final routesStr = parts.length > 16 ? parts[16].trim() : '';
                              if (routesStr.isNotEmpty && routesStr.toLowerCase() != 'nan') {
                                routes.add(routesStr);
                              }
                              
                              return {
                                  'startTime': startTime,
                                  'endTime': endTime,
                                  'isNextDay': isNextDay,
                                  'breakStartTime': breakStart,
                                  'breakEndTime': breakEnd,
                                  'workTime': workTime,
                                  'routes': routes,
                              };
                          } else {
                          }
                        } else {
                        }
                    }
                }
            } catch (e) {
                // Continue to next file if one fails
            }
         }
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
              final startTime = _parseTimeOfDay(parts[2].trim());
              final endTime = _parseTimeOfDay(parts[3].trim());

              if (startTime != null && endTime != null) {
                 final isNextDay = endTime.hour < startTime.hour || 
                                   (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
                 return {
                   'startTime': startTime,
                   'endTime': endTime,
                   'isNextDay': isNextDay,
                 };
              } else {
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
              // For overtime shifts, use start time (depart time) instead of report time
              final startTime = isOvertimeShift 
                  ? _parseTimeOfDay(parts[3].trim()) // Depart time for overtime
                  : _parseTimeOfDay(parts[2].trim()); // Report time for regular shifts
              final endTime = _parseTimeOfDay(parts[10].trim()); // Finish time

              if (startTime != null && endTime != null) {
                 final isNextDay = endTime.hour < startTime.hour || 
                                   (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
                 
                 // Extract break times
                 TimeOfDay? breakStart;
                 TimeOfDay? breakEnd;
                 final startBreakStr = parts.length > 5 ? parts[5].trim() : '';
                 final finishBreakStr = parts.length > 8 ? parts[8].trim() : '';
                 
                 final isWorkout = startBreakStr.toLowerCase() == 'nan' || 
                                  startBreakStr.toLowerCase() == 'workout' ||
                                  startBreakStr.isEmpty ||
                                  finishBreakStr.toLowerCase() == 'nan' ||
                                  finishBreakStr.toLowerCase() == 'workout' ||
                                  finishBreakStr.isEmpty ||
                                  startBreakStr == finishBreakStr;
                 
                 if (!isWorkout) {
                   breakStart = _parseTimeOfDay(startBreakStr);
                   breakEnd = _parseTimeOfDay(finishBreakStr);
                 }
                 
                 // Extract work time
                 Duration? workTime;
                 final workTimeStr = parts.length > 14 ? parts[14].trim() : '';
                 if (workTimeStr.isNotEmpty && workTimeStr.toLowerCase() != 'nan') {
                   final timeParts = workTimeStr.split(':');
                   if (timeParts.length >= 2) {
                     final hours = int.tryParse(timeParts[0]);
                     final minutes = int.tryParse(timeParts[1]);
                     if (hours != null && minutes != null) {
                       workTime = Duration(hours: hours, minutes: minutes);
                     }
                   }
                 }
                 
                 // Extract route (column 16)
                 List<String> routes = [];
                 final routeStr = parts.length > 16 ? parts[16].trim() : '';
                 if (routeStr.isNotEmpty && routeStr.toLowerCase() != 'nan') {
                   routes.add(routeStr);
                 }
                 
                 return {
                   'startTime': startTime,
                   'endTime': endTime,
                   'isNextDay': isNextDay,
                   'breakStartTime': breakStart,
                   'breakEndTime': breakEnd,
                   'workTime': workTime,
                   'routes': routes,
                 };
              } else {
              }
            }
          }
        }
        // === Handle Training CSV format ===
        else if (zone == 'Training') {
          // Expecting format: shift,starttime,endtime,startlocation,endlocation
          if (parts.length >= 5) {
            final csvShiftCode = parts[0].trim();
            
            if (csvShiftCode == shiftNumber) {
              final startTime = _parseTimeOfDay(parts[1].trim()); // Start time
              final endTime = _parseTimeOfDay(parts[2].trim()); // End time

              if (startTime != null && endTime != null) {
                final isNextDay = endTime.hour < startTime.hour || 
                                  (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
                return {
                  'startTime': startTime,
                  'endTime': endTime,
                  'isNextDay': isNextDay,
                };
              }
            }
          }
        }
        // === Handle Regular Zone CSV format ===
        else {
          // Expecting PZ format (index 0 is shift, 2 is report, 3 is depart, 5 is startbreak, 8 is finishbreak, 12 is signOff, 14 is work)
          if (parts.length >= 15) { 
             final csvShiftCode = parts[0].trim();
             // No need to normalize PZ codes if shiftNumber is passed correctly (e.g. PZ1/01)
             if (csvShiftCode == shiftNumber) {
                
                // For overtime shifts, use start time (depart time) instead of report time
                final startTime = isOvertimeShift 
                    ? _parseTimeOfDay(parts[3].trim()) // Depart time for overtime
                    : _parseTimeOfDay(parts[2].trim()); // Report time for regular shifts
                final endTime = _parseTimeOfDay(parts[12].trim()); // SignOff time

                if (startTime != null && endTime != null) {
                    final isNextDay = endTime.hour < startTime.hour || 
                                      (endTime.hour == startTime.hour && endTime.minute < startTime.minute);
                    
                    // Extract break times (columns 5 and 8)
                    TimeOfDay? breakStart;
                    TimeOfDay? breakEnd;
                    final startBreakStr = parts.length > 5 ? parts[5].trim() : '';
                    final finishBreakStr = parts.length > 8 ? parts[8].trim() : '';
                    
                    // Check if it's a workout (break times are 'nan' or 'workout')
                    final isWorkout = startBreakStr.toLowerCase() == 'nan' || 
                                     startBreakStr.toLowerCase() == 'workout' ||
                                     startBreakStr.isEmpty ||
                                     finishBreakStr.toLowerCase() == 'nan' ||
                                     finishBreakStr.toLowerCase() == 'workout' ||
                                     finishBreakStr.isEmpty;
                    
                    if (!isWorkout) {
                      breakStart = _parseTimeOfDay(startBreakStr);
                      breakEnd = _parseTimeOfDay(finishBreakStr);
                    }
                    
                    // Extract work time (column 14)
                    Duration? workTime;
                    final workTimeStr = parts.length > 14 ? parts[14].trim() : '';
                    if (workTimeStr.isNotEmpty && workTimeStr.toLowerCase() != 'nan') {
                      final timeParts = workTimeStr.split(':');
                      if (timeParts.length >= 2) {
                        final hours = int.tryParse(timeParts[0]);
                        final minutes = int.tryParse(timeParts[1]);
                        if (hours != null && minutes != null) {
                          workTime = Duration(hours: hours, minutes: minutes);
                        }
                      }
                    }
                    
                    // Extract routes from locations (columns 4, 6, 9, 11)
                    List<String> routes = [];
                    final startLocation = parts.length > 4 ? parts[4].trim() : '';
                    final breakStartLoc = parts.length > 6 ? parts[6].trim() : '';
                    final breakFinishLoc = parts.length > 9 ? parts[9].trim() : '';
                    final finishLoc = parts.length > 11 ? parts[11].trim() : '';
                    
                    // Extract route from location codes (e.g., "39A-BWALK" -> "39A")
                    String? extractRoute(String loc) {
                      if (loc.isEmpty || loc.toLowerCase() == 'nan' || loc.toUpperCase() == 'GARAGE') {
                        return null;
                      }
                      final dashIndex = loc.indexOf('-');
                      if (dashIndex > 0) {
                        String route = loc.substring(0, dashIndex);
                        // Simplify compound routes like "C1/C2" to just "C"
                        if (route.contains('/')) {
                          final match = RegExp(r'([A-Z]+)').firstMatch(route);
                          if (match != null) {
                            return match.group(1);
                          }
                        }
                        return route;
                      }
                      // For PZ4, check for route in parentheses (e.g., "PSQW-PE(9)" -> "9")
                      final parenMatch = RegExp(r'\((\d+)\)').firstMatch(loc);
                      if (parenMatch != null) {
                        return parenMatch.group(1);
                      }
                      return null;
                    }
                    
                    if (!isWorkout) {
                      // For regular shifts, get routes from break locations
                      final firstRoute = extractRoute(breakStartLoc) ?? extractRoute(startLocation);
                      final secondRoute = extractRoute(breakFinishLoc) ?? extractRoute(finishLoc);
                      if (firstRoute != null && !routes.contains(firstRoute)) routes.add(firstRoute);
                      if (secondRoute != null && !routes.contains(secondRoute)) routes.add(secondRoute);
                    } else {
                      // For workouts, get route from any location
                      final route = extractRoute(startLocation) ?? extractRoute(finishLoc) ?? extractRoute(breakStartLoc);
                      if (route != null && !routes.contains(route)) routes.add(route);
                    }
                    
                    return {
                      'startTime': startTime,
                      'endTime': endTime,
                      'isNextDay': isNextDay,
                      'breakStartTime': breakStart,
                      'breakEndTime': breakEnd,
                      'workTime': workTime,
                      'routes': routes,
                    };
                      } else {
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
      // Silently handle time parsing errors - invalid format
    }
    return null;
  }

  // Helper to sync bus assignments to Google Calendar
  Future<void> _syncBusAssignmentsToGoogleCalendar(Event event) async {
    try {
      // Check if Google Calendar sync is enabled
      final syncEnabled = await StorageService.getBool(AppConstants.syncToGoogleCalendarKey, defaultValue: false);
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      
      if (!syncEnabled || !isSignedIn) {
        return; // Skip if not enabled or not signed in
      }

      // Convert to full DateTime objects for Google Calendar search
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

      // Search for existing Google Calendar events on the same day
      final dayStart = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final existingEvents = await GoogleCalendarService.listEvents(
        startTime: dayStart.toUtc(),
        endTime: dayEnd.toUtc(),
      );

      // Find matching event by title and time
      calendar.Event? matchingEvent;
      for (final gcalEvent in existingEvents) {
        if (gcalEvent.summary == event.title &&
            gcalEvent.start?.dateTime != null &&
            gcalEvent.end?.dateTime != null) {
          
          final gcalStart = gcalEvent.start!.dateTime!.toLocal();
          final gcalEnd = gcalEvent.end!.dateTime!.toLocal();
          
          // Check if times match (within 1 minute tolerance)
          if ((gcalStart.difference(startDateTime).abs().inMinutes <= 1) &&
              (gcalEnd.difference(endDateTime).abs().inMinutes <= 1)) {
            matchingEvent = gcalEvent;
            break;
          }
        }
      }

      if (matchingEvent != null) {
        // Build updated description with bus assignments
        final updatedDescription = await _buildGoogleCalendarDescription(event);
        
        // Update the event description
        matchingEvent.description = updatedDescription;
        
        // Update the event in Google Calendar
        await GoogleCalendarService.updateEvent(
          eventId: matchingEvent.id!,
          event: matchingEvent,
        );
      }
    } catch (e) {
      // Continue silently - don't block user if sync fails
    }
  }

  // Helper to build Google Calendar description with bus assignments
  Future<String?> _buildGoogleCalendarDescription(Event event) async {
    List<String> descriptionParts = [];
    
    // Add break times if available (and not a workout)
    final breakTime = await ShiftService.getBreakTime(event);
    if (breakTime != null && !breakTime.toLowerCase().contains('workout') && breakTime.isNotEmpty) {
      descriptionParts.add('Break Times: $breakTime');
    }
    
    // Add Work For Others indicator if applicable
    if (event.isWorkForOthers) {
      descriptionParts.add('(Work For Others)');
    } else {
      // Add rest day indicator if applicable (only if not WFO)
      final String shiftType = getShiftForDate(event.startDate);
      final bool isRest = shiftType == 'R';
      if (isRest) {
        descriptionParts.add('(Working on Rest Day)');
      }
    }
    
    // Add sick day status if applicable
    if (event.sickDayType != null) {
      String sickDayLabel;
      switch (event.sickDayType) {
        case 'normal':
          sickDayLabel = 'Normal Sick Day';
          break;
        case 'self-certified':
          sickDayLabel = 'Self-Certified Sick Day';
          break;
        case 'force-majeure':
          sickDayLabel = 'Force Majeure';
          break;
        default:
          sickDayLabel = event.sickDayType!;
      }
      descriptionParts.add('📋 Sick Day: $sickDayLabel');
    }
    
    // Add bus assignment information (if enabled)
    final includeBusAssignments = await StorageService.getBool(AppConstants.includeBusAssignmentsInGoogleCalendarKey, defaultValue: true);
    
    if (includeBusAssignments) {
      final busInfo = await _formatBusAssignmentForGoogleCalendar(event);
      if (busInfo != null) {
        if (descriptionParts.isNotEmpty) {
          descriptionParts.add(''); // Add blank line separator
        }
        descriptionParts.add('Bus Assignment:');
        descriptionParts.add(busInfo);
      }
    }
    
    // Combine all parts into final description
    final description = descriptionParts.join('\n');
    return description.isEmpty ? null : description;
  }

  // Helper to format bus assignment for Google Calendar description
  Future<String?> _formatBusAssignmentForGoogleCalendar(Event event) async {
    // Check if bustimes.org links should be included
    final includeLinks = await StorageService.getBool(AppConstants.includeBustimesLinksInGoogleCalendarKey, defaultValue: true);
    
    // Check for workout shifts (single bus assignment)
    if (event.title.toLowerCase().contains('workout')) {
      // For workout shifts, check firstHalfBus or any bus assignment
      final workoutBus = event.firstHalfBus ?? 
                        (event.busAssignments?.values.isNotEmpty == true 
                         ? event.busAssignments!.values.first 
                         : null);
      if (workoutBus != null && workoutBus.isNotEmpty) {
        if (includeLinks) {
          final busUrl = await BusTrackingService.getBusUrl(workoutBus);
          if (busUrl != null) {
            return 'Bus: $workoutBus ($busUrl)';
          } else {
            return 'Bus: $workoutBus';
          }
        } else {
          return 'Bus: $workoutBus';
        }
      }
    } else {
      // For regular shifts, show first half and second half
      List<String> busParts = [];
      
      if (event.firstHalfBus != null && event.firstHalfBus!.isNotEmpty) {
        if (includeLinks) {
          final busUrl = await BusTrackingService.getBusUrl(event.firstHalfBus!);
          if (busUrl != null) {
            busParts.add('First Half: ${event.firstHalfBus} ($busUrl)');
          } else {
            busParts.add('First Half: ${event.firstHalfBus}');
          }
        } else {
          busParts.add('First Half: ${event.firstHalfBus}');
        }
      }
      
      if (event.secondHalfBus != null && event.secondHalfBus!.isNotEmpty) {
        if (includeLinks) {
          final busUrl = await BusTrackingService.getBusUrl(event.secondHalfBus!);
          if (busUrl != null) {
            busParts.add('Second Half: ${event.secondHalfBus} ($busUrl)');
          } else {
            busParts.add('Second Half: ${event.secondHalfBus}');
          }
        } else {
          busParts.add('Second Half: ${event.secondHalfBus}');
        }
      }
      
      // Also check busAssignments for spare duties with specific duty codes
      if (event.busAssignments != null && event.busAssignments!.isNotEmpty) {
        for (final entry in event.busAssignments!.entries) {
          final dutyCode = entry.key;
          final busNumber = entry.value;
          
          if (busNumber.isNotEmpty) {
            if (includeLinks) {
              final busUrl = await BusTrackingService.getBusUrl(busNumber);
              if (busUrl != null) {
                busParts.add('$dutyCode: $busNumber ($busUrl)');
              } else {
                busParts.add('$dutyCode: $busNumber');
              }
            } else {
              busParts.add('$dutyCode: $busNumber');
            }
          }
        }
      }
      
      if (busParts.isNotEmpty) {
        final result = busParts.join('\n');
        return result;
      }
    }
    
    return null; // No bus assignments to display
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

        // Variables moved to _buildGoogleCalendarDescription method
        
        // Build description with all available information including bus assignments
        final finalDescription = await _buildGoogleCalendarDescription(event);
        
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
                  // View Board button (if board exists for this shift)
                  FutureBuilder<UniversalBoard?>(
                    future: UniversalBoardService.getBoardByShift(event.title),
                    builder: (context, snapshot) {
                      final board = snapshot.data;
                      final hasBoard = board != null && board.sections.isNotEmpty;
                      
                      if (!hasBoard) {
                        return const SizedBox.shrink();
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showBoard(board);
                              },
                              icon: const Icon(Icons.description, size: 18),
                              label: const Text('View Board'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // First row - Notes and Break Status
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
                      // Add Break Status button for eligible duties
                      if (event.isEligibleForOvertimeTracking) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            // Close the current dialog first
                            Navigator.of(context).pop();
                            // Show break status dialog
                            _showBreakStatusDialog(event);
                          },
                          child: const Text('Break & Finish'),
                        ),
                      ],
                    ],
                  ),
                  // Second row - Sick Day Status (if work shift)
                  if (event.isWorkShift)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Close the current dialog first
                            Navigator.of(context).pop();
                            // Show sick day status dialog
                            _showSickDayStatusDialog(event);
                          },
                          child: const Text('Sick Day Status'),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).cardColor
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Theme.of(context).brightness == Brightness.dark
                        ? Border.all(color: Theme.of(context).dividerColor)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_bus, size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Bus Assignment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
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
                              final screenWidth = MediaQuery.of(context).size.width;
                              final isSmallScreen = screenWidth < 350;
                              final iconSize = isSmallScreen ? 16.0 : 18.0;
                              final iconPadding = isSmallScreen ? 2.0 : 4.0;
                              final textFontSize = isSmallScreen ? 12.0 : 14.0;
                              final containerPadding = isSmallScreen ? 6.0 : 8.0;
                              final checkIconSize = isSmallScreen ? 14.0 : 16.0;
                              
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: containerPadding, vertical: containerPadding * 0.75),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Theme.of(context).dividerColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, size: checkIconSize, color: Colors.green),
                                    SizedBox(width: isSmallScreen ? 4 : 8),
                                    Expanded(
                                      child: Text(
                                        event.title.contains('(OT)') ? 'Assigned Bus: ${event.firstHalfBus}' : '1: ${event.firstHalfBus}',
                                        style: TextStyle(
                                          fontSize: textFontSize,
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 2 : 4),
                                    // Group icons together tightly
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Track button for first half bus
                                        GestureDetector(
                                          onTap: _busTrackingLoading['tracking_${event.firstHalfBus}'] == true
                                              ? null
                                              : () => _trackBus(event.firstHalfBus!),
                                          child: Container(
                                            padding: EdgeInsets.all(iconPadding),
                                            child: _busTrackingLoading['tracking_${event.firstHalfBus}'] == true
                                                ? SizedBox(
                                                    width: iconSize - 2,
                                                    height: iconSize - 2,
                                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : Icon(Icons.location_on, size: iconSize, color: Colors.blue),
                                          ),
                                        ),
                                        // Change bus button (swap/recycle icon)
                                        GestureDetector(
                                          onTap: () async {
                                            // Show the bus assignment dialog
                                            final hasCurrentBus = event.firstHalfBus != null && event.firstHalfBus!.isNotEmpty;
                                        final TextEditingController controller = TextEditingController(text: event.firstHalfBus ?? '');
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(hasCurrentBus ? 'Change First Half Bus' : 'Add First Half Bus'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (hasCurrentBus)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 8.0),
                                                    child: Text(
                                                      'Current: ${event.firstHalfBus}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                                TextField(
                                                  controller: controller,
                                                  decoration: const InputDecoration(
                                                    hintText: 'Enter bus number (e.g. PA155)',
                                                    labelText: 'Bus Number',
                                                  ),
                                                  textCapitalization: TextCapitalization.characters,
                                                  autofocus: true,
                                                ),
                                              ],
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
                                                child: Text(hasCurrentBus ? 'Change' : 'Add'),
                                              ),
                                            ],
                                          ),
                                        );
                                        
                                        if (result != null) {
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
                                            additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                            firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                            secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                            additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                            notes: event.notes,
                                          );
                                          
                                          // Create updated event with all bus breakdown fields
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
                                            busAssignments: event.busAssignments,
                                            firstHalfBus: event.firstHalfBus,
                                            secondHalfBus: event.secondHalfBus,
                                            additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                            firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                            secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                            additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                            notes: event.notes,
                                          );
                                          
                                          // Use change bus method to track breakdown buses
                                          updatedEvent.changeBusForFirstHalf(result);
                                          
                                          // Save the updated event
                                          await EventService.updateEvent(oldEvent, updatedEvent);
                                          
                                          // Sync bus assignments to Google Calendar
                                          await _syncBusAssignmentsToGoogleCalendar(updatedEvent);
                                          
                                          // Refresh the UI
                                          if (!mounted) return;
                                          setState(() {});
                                          // Close the current dialog
                                          Navigator.of(context).pop();
                                          // Reopen the dialog with the updated event
                                          _editEvent(updatedEvent);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(iconPadding),
                                        child: Icon(Icons.swap_horiz, size: iconSize, color: Colors.orange),
                                      ),
                                    ),
                                      // Remove bus button
                                      GestureDetector(
                                        onTap: () async {
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
                                              additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                              firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                              secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                              additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                              notes: event.notes,
                                            );
                                            
                                            // Create a new event and use remove method to clear primary bus and breakdown history
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
                                              busAssignments: event.busAssignments,
                                              firstHalfBus: event.firstHalfBus,
                                              secondHalfBus: event.secondHalfBus,
                                              additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                              firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                              secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                              additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                              notes: event.notes,
                                            );
                                            
                                            // Use remove method to clear primary bus and breakdown history
                                            updatedEvent.removeBusForFirstHalf();
                                            
                                            // Save the updated event
                                            await EventService.updateEvent(oldEvent, updatedEvent);
                                            
                                            // Sync bus assignments to Google Calendar
                                            await _syncBusAssignmentsToGoogleCalendar(updatedEvent);
                                            
                                            // Refresh the UI
                                            if (!mounted) return;
                                            setState(() {});
                                            // Close the current dialog
                                            Navigator.of(context).pop();
                                            // Reopen the dialog with the updated event
                                            _editEvent(updatedEvent);
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(iconPadding),
                                            child: Icon(Icons.remove_circle_outline, size: iconSize, color: Colors.red),
                                          ),
                                        ),
                                      ],
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
                              final screenWidth = MediaQuery.of(context).size.width;
                              final isSmallScreen = screenWidth < 350;
                              final iconSize = isSmallScreen ? 16.0 : 18.0;
                              final iconPadding = isSmallScreen ? 2.0 : 4.0;
                              final textFontSize = isSmallScreen ? 12.0 : 14.0;
                              final containerPadding = isSmallScreen ? 6.0 : 8.0;
                              final checkIconSize = isSmallScreen ? 14.0 : 16.0;
                              
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: containerPadding, vertical: containerPadding * 0.75),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Theme.of(context).dividerColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, size: checkIconSize, color: Colors.green),
                                    SizedBox(width: isSmallScreen ? 4 : 8),
                                    Expanded(
                                      child: Text(
                                        event.title.contains('(OT)') ? 'Assigned Bus: ${event.secondHalfBus}' : '2: ${event.secondHalfBus}',
                                        style: TextStyle(
                                          fontSize: textFontSize,
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 2 : 4),
                                    // Group icons together tightly
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Track button for second half bus
                                        GestureDetector(
                                          onTap: _busTrackingLoading['tracking_${event.secondHalfBus}'] == true
                                              ? null
                                              : () => _trackBus(event.secondHalfBus!),
                                          child: Container(
                                            padding: EdgeInsets.all(iconPadding),
                                            child: _busTrackingLoading['tracking_${event.secondHalfBus}'] == true
                                                ? SizedBox(
                                                    width: iconSize - 2,
                                                    height: iconSize - 2,
                                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : Icon(Icons.location_on, size: iconSize, color: Colors.blue),
                                          ),
                                        ),
                                        // Change bus button (swap/recycle icon)
                                        GestureDetector(
                                          onTap: () async {
                                            // Show the bus assignment dialog
                                            final hasCurrentBus = event.secondHalfBus != null && event.secondHalfBus!.isNotEmpty;
                                        final TextEditingController controller = TextEditingController(text: event.secondHalfBus ?? '');
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(hasCurrentBus ? 'Change Second Half Bus' : 'Add Second Half Bus'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (hasCurrentBus)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 8.0),
                                                    child: Text(
                                                      'Current: ${event.secondHalfBus}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                                TextField(
                                                  controller: controller,
                                                  decoration: const InputDecoration(
                                                    hintText: 'Enter bus number (e.g. PA155)',
                                                    labelText: 'Bus Number',
                                                  ),
                                                  textCapitalization: TextCapitalization.characters,
                                                  autofocus: true,
                                                ),
                                              ],
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
                                                child: Text(hasCurrentBus ? 'Change' : 'Add'),
                                              ),
                                            ],
                                          ),
                                        );
                                        
                                        if (result != null) {
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
                                            additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                            firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                            secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                            additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                            notes: event.notes,
                                          );
                                          
                                          // Create updated event with all bus breakdown fields
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
                                            busAssignments: event.busAssignments,
                                            firstHalfBus: event.firstHalfBus,
                                            secondHalfBus: event.secondHalfBus,
                                            additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                            firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                            secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                            additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                            notes: event.notes,
                                          );
                                          
                                          // Use change bus method to track breakdown buses
                                          updatedEvent.changeBusForSecondHalf(result);
                                          
                                          // Save the updated event
                                          await EventService.updateEvent(oldEvent, updatedEvent);
                                          
                                          // Sync bus assignments to Google Calendar
                                          await _syncBusAssignmentsToGoogleCalendar(updatedEvent);
                                          
                                          // Refresh the UI
                                          if (!mounted) return;
                                          setState(() {});
                                          // Close the current dialog
                                          Navigator.of(context).pop();
                                          // Reopen the dialog with the updated event
                                          _editEvent(updatedEvent);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(iconPadding),
                                        child: Icon(Icons.swap_horiz, size: iconSize, color: Colors.orange),
                                      ),
                                    ),
                                    // Remove bus button
                                    GestureDetector(
                                      onTap: () async {
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
                                          additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                          firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                          secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                          additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                          notes: event.notes,
                                        );
                                        
                                        // Create a new event and use remove method to clear primary bus and breakdown history
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
                                          busAssignments: event.busAssignments,
                                          firstHalfBus: event.firstHalfBus,
                                          secondHalfBus: event.secondHalfBus,
                                          additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                          firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                          secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                          additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                          notes: event.notes,
                                        );
                                        
                                        // Use remove method to clear primary bus and breakdown history
                                        updatedEvent.removeBusForSecondHalf();
                                        
                                        // Save the updated event
                                        await EventService.updateEvent(oldEvent, updatedEvent);
                                        
                                        // Sync bus assignments to Google Calendar
                                        await _syncBusAssignmentsToGoogleCalendar(updatedEvent);
                                        
                                        // Refresh the UI
                                        if (!mounted) return;
                                        setState(() {});
                                        // Close the current dialog
                                        Navigator.of(context).pop();
                                        // Reopen the dialog with the updated event
                                        _editEvent(updatedEvent);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(iconPadding),
                                        child: Icon(Icons.remove_circle_outline, size: iconSize, color: Colors.red),
                                      ),
                                    ),
                                  ],
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
                          // Removed unused variable isSpareWithFullDuties
                          
                          if (isWorkoutOrOvertime) {
                            // Single button for workout and overtime shifts - show "Change Bus" if bus exists, "Add Bus" if not
                            return ElevatedButton(
                              onPressed: () async {
                                // Show the bus assignment dialog
                                final TextEditingController controller = TextEditingController(text: event.firstHalfBus ?? '');
                                final hasCurrentBus = event.firstHalfBus != null && event.firstHalfBus!.isNotEmpty;
                                final result = await showDialog<String>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(hasCurrentBus ? 'Change Bus' : 'Add Bus'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (hasCurrentBus)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: Text(
                                              'Current: ${event.firstHalfBus}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            hintText: 'Enter bus number (e.g. PA155)',
                                            labelText: 'Bus Number',
                                          ),
                                          textCapitalization: TextCapitalization.characters,
                                          autofocus: true,
                                        ),
                                      ],
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
                                        child: Text(hasCurrentBus ? 'Change' : 'Add'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (result != null) {
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
                                    busAssignments: event.busAssignments,
                                    firstHalfBus: event.firstHalfBus,
                                    secondHalfBus: event.secondHalfBus,
                                    additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                    firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                    secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                    additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                  );
                                  
                                  // Create updated event and use change bus method
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
                                    busAssignments: event.busAssignments,
                                    firstHalfBus: event.firstHalfBus,
                                    secondHalfBus: event.secondHalfBus,
                                    additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                    firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                    secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                    additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                  );
                                  
                                  // Use change bus method to track breakdown buses
                                  updatedEvent.changeBusForSingleShift(result);
                                  
                                  // Save the updated event
                                  await EventService.updateEvent(oldEvent, updatedEvent);
                                  
                                  // Sync bus assignments to Google Calendar
                                  await _syncBusAssignmentsToGoogleCalendar(updatedEvent);
                                  
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
                                backgroundColor: event.firstHalfBus == null ? AppTheme.primaryColor : Colors.orange,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(0, 48),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.directions_bus, size: 18),
                                    const SizedBox(width: 8),
                                    Text(event.firstHalfBus == null ? 'Add Bus' : 'Change Bus'),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            // Add bus buttons - only show when buses are not assigned
                            // Bus changes are handled via swap icons in the bus cards when buses exist
                            return Column(
                              children: [
                                if (event.firstHalfBus == null)
                                  SizedBox(
                                    width: double.infinity,
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
                                          additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                          firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                          secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                          additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                          notes: event.notes,
                                        );
                                        
                                        // Show the bus assignment dialog
                                        final TextEditingController controller = TextEditingController();
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Add First Half Bus'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: controller,
                                                  decoration: const InputDecoration(
                                                    hintText: 'Enter bus number (e.g. PA155)',
                                                    labelText: 'Bus Number',
                                                  ),
                                                  textCapitalization: TextCapitalization.characters,
                                                  autofocus: true,
                                                ),
                                              ],
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
                                          // Create updated event
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
                                            busAssignments: event.busAssignments,
                                            firstHalfBus: result,
                                            secondHalfBus: event.secondHalfBus,
                                            additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                            firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                            secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                            additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                            notes: event.notes,
                                          );
                                          
                                          // Save the updated event
                                          await EventService.updateEvent(oldEvent, updatedEvent);
                                          
                                          // Sync bus assignments to Google Calendar
                                          await _syncBusAssignmentsToGoogleCalendar(updatedEvent);
                                          
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
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.directions_bus, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Add 1st Half Bus'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (event.firstHalfBus == null && event.secondHalfBus == null)
                                  const SizedBox(height: 8),
                                if (event.secondHalfBus == null)
                                  SizedBox(
                                    width: double.infinity,
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
                                          additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                          firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                          secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                          additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                          notes: event.notes,
                                        );
                                        
                                        // Show the bus assignment dialog
                                        final TextEditingController controller = TextEditingController();
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Add Second Half Bus'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: controller,
                                                  decoration: const InputDecoration(
                                                    hintText: 'Enter bus number (e.g. PA155)',
                                                    labelText: 'Bus Number',
                                                  ),
                                                  textCapitalization: TextCapitalization.characters,
                                                  autofocus: true,
                                                ),
                                              ],
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
                                          // Create updated event
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
                                            busAssignments: event.busAssignments,
                                            firstHalfBus: event.firstHalfBus,
                                            secondHalfBus: result,
                                            additionalBusesUsed: event.additionalBusesUsed?.map((b) => b).toList(),
                                            firstHalfAdditionalBuses: event.firstHalfAdditionalBuses?.map((b) => b).toList(),
                                            secondHalfAdditionalBuses: event.secondHalfAdditionalBuses?.map((b) => b).toList(),
                                            additionalBusesByDuty: event.additionalBusesByDuty?.map((k, v) => MapEntry(k, List<String>.from(v))),
                                            notes: event.notes,
                                          );
                                          
                                          // Save the updated event
                                          await EventService.updateEvent(oldEvent, updatedEvent);
                                          
                                          // Sync bus assignments to Google Calendar
                                          await _syncBusAssignmentsToGoogleCalendar(updatedEvent);
                                          
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
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.directions_bus, size: 18),
                                            const SizedBox(width: 8),
                                            const Text('Add 2nd Half Bus'),
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
                            if (!mounted) return;
                            await CalendarTestHelper.deleteEventFromCalendar(
                              context: context,
                              title: event.title,
                              eventStartTime: startDateTime,
                            );
                          } catch (e) {
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

  void _showBoard(UniversalBoard board) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Board ${board.shift}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (board.duty != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Duty ${board.duty}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: board.sections.map((section) {
                      final sectionType = section.type;
                      final isFirstHalf = sectionType == 'firstHalf';
                      final sectionColor = isFirstHalf ? Colors.orange : Colors.blue;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section header with subtle background
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: sectionColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: sectionColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isFirstHalf ? 'First Half' : 'Second Half',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: sectionColor.shade800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Entries with subtle timeline
                            ...section.entries.asMap().entries.map((entryEntry) {
                              final entry = entryEntry.value;
                              final isLast = entryEntry.key == section.entries.length - 1;
                              
                              // Calculate if this entry has content below the action
                              final hasDetails = entry.location != null || 
                                                 entry.notes != null || 
                                                 (entry.action.toLowerCase() != 'route' && entry.route != null);
                              
                              // Check if action is Route (to combine with route badge)
                              final isRouteAction = entry.action.toLowerCase() == 'route' && entry.route != null;
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Time column - fixed width and alignment
                                    SizedBox(
                                      width: 70,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (entry.time != null)
                                            Container(
                                              width: 70,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: sectionColor.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: sectionColor.withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                entry.time!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: sectionColor.shade800,
                                                  height: 1.2,
                                                ),
                                              ),
                                            )
                                          else
                                            SizedBox(
                                              width: 70,
                                              height: 30, // Match badge height
                                            ),
                                          if (!isLast) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              width: 2,
                                              height: hasDetails ? 35 : 15,
                                              color: sectionColor.withValues(alpha: 0.2),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Content column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Action - aligned with time badge by matching height
                                          SizedBox(
                                            height: entry.time != null ? 30 : null,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: isRouteAction
                                                  ? Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          'Route ',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 16,
                                                            color: Theme.of(context).colorScheme.onSurface,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue.shade50,
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            entry.route!,
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: Colors.blue.shade700,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      entry.action,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          if (hasDetails) const SizedBox(height: 6),
                                          // Route path information - just "From [location]"
                                          if (isRouteAction && entry.location != null) ...[
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Theme.of(context)
                                                        .colorScheme.onSurface
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'From ${entry.location}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Theme.of(context)
                                                            .colorScheme.onSurface
                                                            .withValues(alpha: 0.7),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Show notes if they exist (like "via Celbridge")
                                            if (entry.notes != null) ...[
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme.onSurface
                                                          .withValues(alpha: 0.5),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        entry.notes!,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontStyle: FontStyle.italic,
                                                          color: Theme.of(context)
                                                              .colorScheme.onSurface
                                                              .withValues(alpha: 0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ] else ...[
                                            // Route badge (only if action is not "Route")
                                            if (entry.route != null) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Route ${entry.route}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            // Location (for non-Route entries)
                                            if (entry.location != null) ...[
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme.onSurface
                                                          .withValues(alpha: 0.5),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        entry.location!,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Theme.of(context)
                                                              .colorScheme.onSurface
                                                              .withValues(alpha: 0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                          // Notes (exclude Route entries as they're handled above)
                                          if (entry.notes != null && !isRouteAction) ...[
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: entry.location != null ? 4 : 2,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme.surfaceContainerHighest
                                                      .withValues(alpha: 0.5),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme.onSurface
                                                          .withValues(alpha: 0.5),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        entry.notes!,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Theme.of(context)
                                                              .colorScheme.onSurface
                                                              .withValues(alpha: 0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                
                if (!mounted) return;
                setState(() {});
              }
              
              if (!mounted) return;
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
            Text('Break & Finish Status'),
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
            if (event.hasLateFinish) ...[
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
                      'Current Late Finish Status:', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Late Finish: ${event.lateFinishDuration} mins',
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
              'Select an option:',
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
                  hasLateFinish: event.hasLateFinish,
                  lateFinishDuration: event.lateFinishDuration,
                );
                
                // Reset break status
                event.hasLateBreak = false;
                event.tookFullBreak = false;
                event.overtimeDuration = null;
                
                // Save the updated event
                await EventService.updateEvent(oldEvent, event);
                
                // Close the dialog
                if (!mounted) return;
                Navigator.of(context).pop();
                
                // Update the UI
                setState(() {});
                
                // Show confirmation
                if (!mounted) return;
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
          // Only show Full Break button if no break status is set
          if (!event.hasLateBreak)
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
                  hasLateFinish: event.hasLateFinish,
                  lateFinishDuration: event.lateFinishDuration,
                );
              
                // Update event with Full Break option
                event.hasLateBreak = true;
                event.tookFullBreak = true;
                event.overtimeDuration = null;
                
                // Save the updated event
                await EventService.updateEvent(oldEvent, event);
                
                // Close the dialog
                if (!mounted) return;
                Navigator.of(context).pop();
                
                // Update the UI
                setState(() {});
                
                // Show confirmation
                if (!mounted) return;
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
          // Only show Overtime button if no break status is set
          if (!event.hasLateBreak)
            TextButton(
              onPressed: () {
                // Close current dialog and show overtime selection dialog
                Navigator.of(context).pop();
                _showOvertimeSelectionDialog(event);
              },
              child: const Text('Overtime'),
            ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Late Finish buttons
          if (event.hasLateFinish)
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
                  hasLateFinish: event.hasLateFinish,
                  lateFinishDuration: event.lateFinishDuration,
                );
                
                // Reset late finish status
                event.hasLateFinish = false;
                event.lateFinishDuration = null;
                
                // Save the updated event
                await EventService.updateEvent(oldEvent, event);
                
                // Close the dialog
                if (!mounted) return;
                Navigator.of(context).pop();
                
                // Update the UI
                setState(() {});
                
                // Show confirmation
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Late finish status removed'),
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
              child: const Text('Remove Late Finish'),
            ),
          // Only show Late Finish button if not already set
          if (!event.hasLateFinish)
            TextButton(
              onPressed: () {
                // Close current dialog and show late finish selection dialog
                Navigator.of(context).pop();
                _showLateFinishSelectionDialog(event);
              },
              child: const Text('Late Finish'),
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
                    if (!mounted) return;
                    Navigator.of(context).pop();
                    
                    // Update the UI
                    this.setState(() {});
                    
                    // Show confirmation
                    if (!mounted) return;
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
                  hasLateFinish: event.hasLateFinish,
                  lateFinishDuration: event.lateFinishDuration,
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

  // Show dialog for late finish duration selection
  void _showLateFinishSelectionDialog(Event event) {
    int selectedDuration = event.lateFinishDuration ?? 15; // Default to 15 mins
    final TextEditingController customMinutesController = TextEditingController(
      text: event.lateFinishDuration?.toString() ?? '',
    );
    bool useCustom = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange),
              SizedBox(width: 8),
              Text('Select Late Finish'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select or enter how many minutes late you finished:',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                // Dropdown for late finish duration
                DropdownButtonFormField<int?>(
                  value: useCustom ? null : selectedDuration,
                  decoration: const InputDecoration(
                    labelText: 'Duration (Select)',
                    border: OutlineInputBorder(),
                  ),
                  items: [5, 10, 15, 20, 30, 45, 60, 90, 120].map((int value) {
                    return DropdownMenuItem<int?>(
                      value: value,
                      child: Text('$value mins'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedDuration = newValue;
                        useCustom = false;
                        customMinutesController.text = '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Or enter custom minutes:',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // Text input for custom minutes
                TextField(
                  controller: customMinutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutes',
                    hintText: 'Enter minutes',
                    border: OutlineInputBorder(),
                    suffixText: 'mins',
                  ),
                  onChanged: (String value) {
                    if (value.isNotEmpty) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          selectedDuration = parsed;
                          useCustom = true;
                        });
                      } else {
                        // Invalid input, but keep useCustom true so dropdown clears
                        setState(() {
                          useCustom = true;
                        });
                      }
                    } else {
                      setState(() {
                        useCustom = false;
                      });
                    }
                  },
                ),
              ],
            ),
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
                // Validate that we have a valid duration
                int? finalDuration;
                if (useCustom && customMinutesController.text.isNotEmpty) {
                  final parsed = int.tryParse(customMinutesController.text);
                  if (parsed != null && parsed > 0) {
                    finalDuration = parsed;
                  }
                } else if (!useCustom) {
                  finalDuration = selectedDuration;
                }
                
                if (finalDuration == null || finalDuration <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number of minutes'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                
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
                  busAssignments: event.busAssignments,
                  firstHalfBus: event.firstHalfBus,
                  secondHalfBus: event.secondHalfBus,
                  notes: event.notes,
                  hasLateBreak: event.hasLateBreak,
                  tookFullBreak: event.tookFullBreak,
                  overtimeDuration: event.overtimeDuration,
                  hasLateFinish: event.hasLateFinish,
                  lateFinishDuration: event.lateFinishDuration,
                );
                
                // Update event with Late Finish option
                event.hasLateFinish = true;
                event.lateFinishDuration = finalDuration;
                
                // Save the updated event
                await EventService.updateEvent(oldEvent, event);
                
                // Close the dialog (controller will be disposed in .then() callback)
                if (!mounted) return;
                Navigator.of(context).pop();
                
                // Update the UI
                setState(() {});
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Late finish ($finalDuration mins) saved'),
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
    ).then((_) {
      // Dispose controller after dialog is fully closed (with small delay to ensure rebuild is complete)
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          customMinutesController.dispose();
        } catch (e) {
          // Controller already disposed or error, ignore
        }
      });
    });
  }

  void _showSickDayStatusDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.medical_services, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sick Day Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.sickDayType != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
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
                          Icons.medical_services,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getSickDayTypeLabel(event.sickDayType!),
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
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
              'Select sick day type:',
              style: TextStyle(fontSize: 14),
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
          // Clear button if sick day status exists
          if (event.sickDayType != null)
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
                  sickDayType: event.sickDayType,
                );
                
                // Clear sick day status
                event.sickDayType = null;
                
                // Save the updated event
                await EventService.updateEvent(oldEvent, event);
                
                // Close the dialog
                Navigator.of(context).pop();
                
                // Update the UI
                setState(() {});
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sick day status cleared'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear'),
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
                busAssignments: event.busAssignments,
                notes: event.notes,
                hasLateBreak: event.hasLateBreak,
                tookFullBreak: event.tookFullBreak,
                overtimeDuration: event.overtimeDuration,
                sickDayType: event.sickDayType,
              );
              
              // Set as Normal Sick
              event.sickDayType = 'normal';
              
              // Save the updated event
              await EventService.updateEvent(oldEvent, event);
              
              // Close the dialog
              Navigator.of(context).pop();
              
              // Update the UI
              setState(() {});
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Normal Sick Day saved'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Normal Sick'),
          ),
          TextButton(
            onPressed: () async {
              // Check if this is already self-certified (no need to check limits)
              if (event.sickDayType == 'self-certified') {
                Navigator.of(context).pop();
                return;
              }

              // Get year and half-year info
              final year = event.startDate.year;
              final halfYear = SelfCertifiedSickDaysService.getHalfYear(event.startDate);
                final halfYearName = halfYear == 'first' ? 'First Half (Jan-Jun)' : 'Second Half (Jul-Dec)';
              
              // Check limits before allowing self-certified
              final canAddHalfYear = await SelfCertifiedSickDaysService.canAddSelfCertifiedDay(event.startDate);
              final canAddYearly = await SelfCertifiedSickDaysService.canAddSelfCertifiedDayYearly(event.startDate);
              
              if (!canAddHalfYear || !canAddYearly) {
                // Show warning dialog
                final halfYearCount = await SelfCertifiedSickDaysService.getCountForHalfYear(year, halfYear);
                final yearlyCount = await SelfCertifiedSickDaysService.getCountForYear(year);
                
                String warningMessage;
                if (!canAddHalfYear && !canAddYearly) {
                  warningMessage = 'You have already used your limit of 2 self-certified days in the $halfYearName and 4 for the year. You cannot add more self-certified days.';
                } else if (!canAddHalfYear) {
                  warningMessage = 'You have already used your limit of 2 self-certified days in the $halfYearName. You cannot add more self-certified days for this half-year.';
                } else {
                  warningMessage = 'You have already used your limit of 4 self-certified days for the year. You cannot add more self-certified days.';
                }
                
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: const Text('Self-Certified Limit Reached'),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(warningMessage),
                          const SizedBox(height: 16),
                          Text(
                            'Current usage:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('$halfYearName: $halfYearCount/2'),
                          Text('Year total: $yearlyCount/4'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
                return;
              }
              
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
                sickDayType: event.sickDayType,
              );
              
              // Set as Self-Certified
              event.sickDayType = 'self-certified';
              
              // Save the updated event
              await EventService.updateEvent(oldEvent, event);
              
              // Close the dialog
              Navigator.of(context).pop();
              
              // Update the UI
              setState(() {});
              
              // Show confirmation with remaining count
              final remainingHalfYear = await SelfCertifiedSickDaysService.getRemainingForHalfYear(year, halfYear);
              final remainingYearly = await SelfCertifiedSickDaysService.getRemainingForYear(year);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Self-Certified Sick Day saved. Remaining: $remainingHalfYear in $halfYearName, $remainingYearly for year.'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Self-Certified'),
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
                busAssignments: event.busAssignments,
                notes: event.notes,
                hasLateBreak: event.hasLateBreak,
                tookFullBreak: event.tookFullBreak,
                overtimeDuration: event.overtimeDuration,
                sickDayType: event.sickDayType,
              );
              
              // Set as Force Majeure
              event.sickDayType = 'force-majeure';
              
              // Save the updated event
              await EventService.updateEvent(oldEvent, event);
              
              // Close the dialog
              Navigator.of(context).pop();
              
              // Update the UI
              setState(() {});
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Force Majeure saved'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Force Majeure'),
          ),
        ],
      ),
    );
  }

  String _getSickDayTypeLabel(String type) {
    switch (type) {
      case 'normal':
        return 'Normal Sick Day';
      case 'self-certified':
        return 'Self-Certified Sick Day';
      case 'force-majeure':
        return 'Force Majeure';
      default:
        return type;
    }
  }

  /// Helper method to convert sick day type to display code for calendar
  /// Returns: 'S' for normal, 'SC' for self-certified, 'FM' for force-majeure
  String _getSickDayDisplayCode(String? sickDayType) {
    if (sickDayType == null) return '';
    switch (sickDayType) {
      case 'normal':
        return 'S';
      case 'self-certified':
        return 'SC';
      case 'force-majeure':
        return 'FM';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reload marked in settings immediately when build is called
    // This ensures settings are fresh when navigating back to the screen
    _loadMarkedInSettings();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          MediaQuery.of(context).size.width < 400 ? 'Calendar' : 'Spare Driver Calendar',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Shifts',
            onPressed: _showSearchScreen,
          ),
          IconButton(
            icon: const Icon(Icons.view_week),
            tooltip: 'Week View',
            onPressed: _showWeekView,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.settings),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'bills',
                child: Text('Bills'),
              ),
              PopupMenuItem(
                value: 'timing_points',
                child: Text('Timing Points'),
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
              } else if (value == 'bills') {
                _showBillsPage();
              } else if (value == 'timing_points') {
                _showTimingPointsPage();
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
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(3),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: SafeArea(
                      top: false, // Don't add top padding since we handle it with the banner
                      child: Column(
                        children: [
                          // TableCalendar is now scrollable with the rest of the content
                          _buildCalendar(),
                          // The rest of the content
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
                          // Dynamic bottom padding that adapts to device navigation bar height
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                        ],
                      ),
                    ),
                  ),
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
                    _focusedDay = _navigateToMonth(_focusedDay, -1);
                  });
                },
              ),
              GestureDetector(
                onTap: () {
                  _showYearView(_focusedDay.year);
                },
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
                    _focusedDay = _navigateToMonth(_focusedDay, 1);
                  });
                },
              ),
            ],
          ),
        ),
        // The TableCalendar with headerVisible: false to hide the default header
        // Note: TableCalendar allows vertical scrolling when used in a ScrollView
        TableCalendar(
          key: ValueKey('calendar_${_markedInEnabled}_$_markedInStatus}_${_focusedDay.year}_${_focusedDay.month}'), // Force rebuild when marked in settings change or month changes
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          headerVisible: false, // Hide default header since we're using our custom one above
          // Enable horizontal swipe gestures for month navigation
          // Vertical scrolling still works for page content
          availableGestures: AvailableGestures.horizontalSwipe,
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
                    // Spare duty validation
                  }
                }
              } catch (e) {
                // Handle preload errors gracefully
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
            // Custom builder for selected day - make it see-through with a border
            selectedBuilder: (context, date, _) {
              return _buildCalendarDay(date, isToday: false, isOutsideDay: false, isSelected: true);
            },
            markerBuilder: (context, date, events) {
              return null;
            },
          ),
        ),
      ],
    );
  }

  /// Helper method to format display text for calendar (shortens BusCheck to BUSC)
  String _formatDisplayText(String text) {
    // Shorten "BusCheck" to "BUSC" for calendar display
    if (text.startsWith('BusCheck')) {
      return text.replaceFirst('BusCheck', 'BUSC');
    }
    return text;
  }

  /// Helper method to determine what text to display on calendar day
  /// Returns: duty code for regular work shifts, spare title for spare shifts, sick day code (S/SC/FM), or shift letter (E/L/M/R)
  String _getCalendarDayDisplayText(DateTime date) {
    final events = getEventsForDay(date);
    final rosterShift = _startDate != null ? getShiftForDate(date) : '';
    
    // If duty codes display is disabled, always return shift letter
    if (!_showDutyCodesOnCalendar) {
      return rosterShift;
    }
    
    // First, check for all sick day codes (S, SC, FM) - these take priority over EVERYTHING
    for (final event in events) {
      if (event.sickDayType != null) {
        final sickDayCode = _getSickDayDisplayCode(event.sickDayType);
        if (sickDayCode.isNotEmpty) {
          return sickDayCode; // Show S, SC, or FM - takes priority over everything
        }
      }
    }
    
    // Second, check for spare shifts - always show their title (ignore assigned duties)
    for (final event in events) {
      if (event.isWorkShift && 
          (event.title.startsWith('SP') || event.title == '22B/01')) {
        return event.title; // Show spare shift title (e.g., "SP1000")
      }
    }
    
    // Third, check for regular work shifts (not spare, not OT)
    // For regular work shifts, the title IS the duty code (e.g., "PZ1/74", "1/13X", "807/20")
    // assignedDuties is only used for spare shifts
    for (final event in events) {
      if (event.isWorkShift && 
          !event.title.startsWith('SP') && 
          event.title != '22B/01' &&
          !event.title.contains('(OT)')) {
        // Check if this event has assigned duties (for spare shifts that were converted)
        final dutyCodes = event.getCurrentDutyCodes();
        if (dutyCodes.isNotEmpty) {
          // Return the first assigned duty code (formatted for display)
          return _formatDisplayText(dutyCodes.first);
        }
        // For regular work shifts, the title IS the duty code (formatted for display)
        return _formatDisplayText(event.title);
      }
    }
    
    // Fallback to roster shift letter (E/L/M/R)
    return rosterShift;
  }

  Widget _buildCalendarDay(DateTime date, {required bool isToday, required bool isOutsideDay, bool isSelected = false}) {
    final shift = _startDate != null ? getShiftForDate(date) : '';
    final shiftInfo = _shiftInfoMap[shift];
    final events = getEventsForDay(date);
    final hasEvents = events.isNotEmpty;
    final bankHoliday = getBankHoliday(date);
    final isBankHoliday = bankHoliday != null;
    final isHoliday = _holidays.any((h) => h.containsDate(date));
    final dayInLieuHoliday = _holidays.firstWhere((h) => h.containsDate(date) && h.type == 'day_in_lieu', orElse: () => Holiday(id: '', startDate: DateTime.now(), endDate: DateTime.now(), type: ''));
    final isDayInLieu = dayInLieuHoliday.id.isNotEmpty;
    final unpaidLeaveHoliday = _holidays.firstWhere((h) => h.containsDate(date) && h.type == 'unpaid_leave', orElse: () => Holiday(id: '', startDate: DateTime.now(), endDate: DateTime.now(), type: ''));
    final isUnpaidLeave = unpaidLeaveHoliday.id.isNotEmpty;
    final isSaturdayService = RosterService.isSaturdayService(date);
    
    // Check if there's a WFO event on this day
    final hasWfoEvent = events.any((event) => event.isWorkForOthers);
    final wfoColor = _shiftInfoMap['WFO']?.color;
    final dayInLieuColor = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
    
    // Check if any events have notes
    final hasNotes = events.any((event) => event.notes != null && event.notes!.trim().isNotEmpty);
    
    // Check for sick day events - priority over other colors
    final sickDayEvent = events.firstWhere(
      (event) => event.sickDayType != null,
      orElse: () => Event(
        id: '',
        title: '',
        startDate: date,
        startTime: const TimeOfDay(hour: 0, minute: 0),
        endDate: date,
        endTime: const TimeOfDay(hour: 0, minute: 0),
        isHoliday: false,
        hasLateBreak: false,
        tookFullBreak: false,
        isWorkForOthers: false,
      ),
    );
    final hasSickDay = sickDayEvent.sickDayType != null;
    final sickDayColor = hasSickDay ? ColorCustomizationService.getColorForSickType(sickDayEvent.sickDayType) : null;
    
    // Get the display text (duty code, spare title, or shift letter)
    final displayText = _getCalendarDayDisplayText(date);
    
    // Calculate responsive badge sizes
    final screenWidth = MediaQuery.of(context).size.width;
    final badgeSizes = _getCalendarBadgeSizes(screenWidth);

    final backgroundColor = hasSickDay && sickDayColor != null
        ? sickDayColor.withValues(alpha: 0.3)
        : isDayInLieu
            ? dayInLieuColor.withValues(alpha: 0.3)
            : isUnpaidLeave
                ? Colors.purple.withValues(alpha: 0.3)
                : isHoliday 
                    ? holidayColor.withValues(alpha: 0.3)
                    : hasWfoEvent && wfoColor != null
                        ? wfoColor.withValues(alpha: 0.3)
                        : shiftInfo?.color.withValues(alpha: 0.3);
    
    // Calculate base cell color (without alpha) for note icon
    final cellColor = hasSickDay && sickDayColor != null
        ? sickDayColor
        : isDayInLieu
            ? dayInLieuColor
            : isUnpaidLeave
                ? Colors.purple
                : isHoliday 
                    ? holidayColor
                    : hasWfoEvent && wfoColor != null
                        ? wfoColor
                        : (shiftInfo?.color ?? Theme.of(context).primaryColor);
    
    final cellContent = _buildDayCellContent(date, displayText, isDayInLieu, isHoliday, shift, hasEvents, hasSickDay, sickDayColor, dayInLieuColor, isUnpaidLeave, hasWfoEvent, wfoColor, shiftInfo, isSaturdayService, hasNotes, cellColor, badgeSizes, screenWidth);
    
    // Determine border color for selected days
    final selectedBorderColor = isBankHoliday ? Colors.red : Theme.of(context).colorScheme.primary;

    // Wrap the content in Opacity if it's an outside day
    return Opacity(
      opacity: isOutsideDay ? 0.4 : 1.0, // Changed from 0.6 to 0.4 for more transparency
      child: isSelected
          ? _animatedSelectedDay
              ? _AnimatedSelectedDayCell(
                  backgroundColor: backgroundColor,
                  isToday: isToday,
                  isBankHoliday: isBankHoliday,
                  borderColor: selectedBorderColor,
                  child: cellContent,
                )
              : Container(
                  margin: const EdgeInsets.all(2.0), // Reduced margin to make circle bigger
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isBankHoliday 
                        ? Colors.red.withValues(alpha: 0.7) // Less bright red
                        : const Color(0xFF1565C0), // Navy blue color
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isBankHoliday ? Colors.red : const Color(0xFF0D47A1), // Darker navy border
                      width: 2.0,
                    ),
                    // Add subtle shadow for depth
                    boxShadow: [
                      BoxShadow(
                        color: (isBankHoliday ? Colors.red : const Color(0xFF1565C0)).withValues(alpha: 0.4),
                        blurRadius: 6.0,
                        spreadRadius: 1.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildDayCellContentWithWhiteText(date, displayText, isDayInLieu, isHoliday, shift, hasEvents, hasSickDay, sickDayColor, dayInLieuColor, isUnpaidLeave, hasWfoEvent, wfoColor, shiftInfo, isSaturdayService, hasNotes, cellColor, badgeSizes, screenWidth),
                )
          : Container(
              margin: const EdgeInsets.all(4.0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor,
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
              child: cellContent,
            ),
    );
  }

  Widget _buildDayCellContentWithWhiteText(
    DateTime date,
    String displayText,
    bool isDayInLieu,
    bool isHoliday,
    String shift,
    bool hasEvents,
    bool hasSickDay,
    Color? sickDayColor,
    Color? dayInLieuColor,
    bool isUnpaidLeave,
    bool hasWfoEvent,
    Color? wfoColor,
    ShiftInfo? shiftInfo,
    bool isSaturdayService,
    bool hasNotes,
    Color cellColor,
    Map<String, double> badgeSizes,
    double screenWidth,
  ) {
    return Stack(
      children: [
        // Main content centered
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Important: minimize space
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: _getResponsiveDateFontSize(screenWidth),
                  color: Colors.white, // White text for filled circle
                ),
              ),
              // Show display text if not empty AND (not holiday OR it's a rest day)
              // This allows rest day "R" to show even when holidays are present
              if (displayText.isNotEmpty && (!isHoliday || shift == 'R')) ...[
                Builder(
                  builder: (context) {
                    return Text(
                      displayText,
                      style: TextStyle(
                        fontSize: _getResponsiveDutyFontSize(screenWidth),
                        fontWeight: FontWeight.bold,
                        height: 1.0, // Reduce line height
                        color: Colors.white, // White text for filled circle
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    );
                  },
                ),
              ],
              if (isDayInLieu)
                Text(
                  'Lieu',
                  style: TextStyle(
                    fontSize: _getResponsiveDutyFontSize(screenWidth),
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for filled circle
                    height: 1.0, // Reduce line height
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                )
              // Only show "H" for holidays when it's NOT a rest day
              else if (isHoliday && shift != 'R')
                Text(
                  'H',
                  style: TextStyle(
                    fontSize: _getResponsiveDutyFontSize(screenWidth),
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for filled circle
                    height: 1.0, // Reduce line height
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
            ],
          ),
        ),
        // Saturday service indicator positioned in top-left corner
        if (isSaturdayService)
          Positioned(
            top: badgeSizes['top']!,
            left: badgeSizes['left']!,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: badgeSizes['paddingH']!,
                vertical: badgeSizes['paddingV']!,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(badgeSizes['radius']!),
              ),
              child: Text(
                'SAT',
                style: TextStyle(
                  fontSize: badgeSizes['fontSize']!,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        // Notes indicator positioned in top-right corner
        if (hasNotes)
          Positioned(
            top: badgeSizes['top']!,
            right: badgeSizes['left']!,
            child: Icon(
              Icons.note,
              size: badgeSizes['fontSize']! * 1.5,
              color: cellColor,
            ),
          ),
        // Event indicator positioned in bottom-right corner
        // Hidden when day is selected (filled circle mode)
      ],
    );
  }

  Widget _buildDayCellContent(
    DateTime date,
    String displayText,
    bool isDayInLieu,
    bool isHoliday,
    String shift,
    bool hasEvents,
    bool hasSickDay,
    Color? sickDayColor,
    Color? dayInLieuColor,
    bool isUnpaidLeave,
    bool hasWfoEvent,
    Color? wfoColor,
    ShiftInfo? shiftInfo,
    bool isSaturdayService,
    bool hasNotes,
    Color cellColor,
    Map<String, double> badgeSizes,
    double screenWidth,
  ) {
    return Stack(
      children: [
        // Main content centered
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Important: minimize space
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: _getResponsiveDateFontSize(screenWidth),
                ),
              ),
              // Show display text if not empty AND (not holiday OR it's a rest day)
              // This allows rest day "R" to show even when holidays are present
              if (displayText.isNotEmpty && (!isHoliday || shift == 'R')) ...[
                Builder(
                  builder: (context) {
                    // Use black text for all cells for consistency and readability
                    return Text(
                      displayText,
                      style: TextStyle(
                        fontSize: _getResponsiveDutyFontSize(screenWidth),
                        fontWeight: FontWeight.bold,
                        height: 1.0, // Reduce line height
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    );
                  },
                ),
              ],
              if (isDayInLieu)
                Text(
                  'Lieu',
                  style: TextStyle(
                    fontSize: _getResponsiveDutyFontSize(screenWidth),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.0, // Reduce line height
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                )
              // Only show "H" for holidays when it's NOT a rest day
              else if (isHoliday && shift != 'R')
                Text(
                  'H',
                  style: TextStyle(
                    fontSize: _getResponsiveDutyFontSize(screenWidth),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.0, // Reduce line height
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
            ],
          ),
        ),
        // Saturday service indicator positioned in top-left corner
        if (isSaturdayService)
          Positioned(
            top: badgeSizes['top']!,
            left: badgeSizes['left']!,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: badgeSizes['paddingH']!,
                vertical: badgeSizes['paddingV']!,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(badgeSizes['radius']!),
              ),
              child: Text(
                'SAT',
                style: TextStyle(
                  fontSize: badgeSizes['fontSize']!,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        // Notes indicator positioned in top-right corner
        if (hasNotes)
          Positioned(
            top: badgeSizes['top']!,
            right: badgeSizes['left']!,
            child: Icon(
              Icons.note,
              size: badgeSizes['fontSize']! * 1.5,
              color: cellColor,
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
                color: hasSickDay && sickDayColor != null
                    ? sickDayColor
                    : isDayInLieu
                        ? dayInLieuColor
                        : isUnpaidLeave
                            ? Colors.purple
                            : isHoliday 
                                ? holidayColor 
                                : hasWfoEvent && wfoColor != null
                                    ? wfoColor
                                    : (shiftInfo?.color ?? Theme.of(context).primaryColor),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
  
  // Helper method to get responsive date font size
  double _getResponsiveDateFontSize(double screenWidth) {
    if (screenWidth < 350) {
      return 11.0; // Very small screens
    } else if (screenWidth < 450) {
      return 12.0; // Small screens
    } else if (screenWidth < 600) {
      return 12.0; // Medium screens
    } else {
      return 13.0; // Large screens (reduced from 14)
    }
  }

  // Helper method to get responsive duty code font size
  double _getResponsiveDutyFontSize(double screenWidth) {
    if (screenWidth < 350) {
      return 8.0; // Very small screens
    } else if (screenWidth < 450) {
      return 9.0; // Small screens
    } else if (screenWidth < 600) {
      return 9.5; // Medium screens
    } else {
      return 10.0; // Large screens
    }
  }

  // Helper method to calculate responsive badge sizes for calendar day
  Map<String, double> _getCalendarBadgeSizes(double screenWidth) {
    if (screenWidth < 350) {
      return {
        'fontSize': 6.0,
        'paddingH': 2.0,
        'paddingV': 0.5,
        'radius': 3.0,
        'top': 1.0,
        'left': 1.0,
      };
    } else if (screenWidth < 450) {
      return {
        'fontSize': 7.0,
        'paddingH': 3.0,
        'paddingV': 1.0,
        'radius': 4.0,
        'top': 2.0,
        'left': 2.0,
      };
    } else if (screenWidth < 600) {
      return {
        'fontSize': 8.0,
        'paddingH': 3.5,
        'paddingV': 1.0,
        'radius': 4.0,
        'top': 2.0,
        'left': 2.0,
      };
    } else if (screenWidth < 900) {
      return {
        'fontSize': 9.0,
        'paddingH': 4.0,
        'paddingV': 1.5,
        'radius': 5.0,
        'top': 3.0,
        'left': 3.0,
      };
    } else {
      return {
        'fontSize': 10.0,
        'paddingH': 5.0,
        'paddingV': 2.0,
        'radius': 5.0,
        'top': 3.0,
        'left': 3.0,
      };
    }
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
                  // Use WFO shift type if this is a Work For Others event
                  final String shiftType = event.isWorkForOthers ? 'WFO' : getShiftForDate(event.startDate);
                  return EventCard(
                    event: event,
                    shiftType: shiftType,
                    shiftInfoMap: _shiftInfoMap,
                    isBankHoliday: getBankHoliday(event.startDate) != null,
                    isRestDay: getShiftForDate(event.startDate) == 'R',
                    onEdit: _editEvent, // Use _editEvent for all types, EventCard handles spare logic
                    onShowNotes: _showNotesDialog, // Pass the function here
                    onBusAssignmentUpdate: _syncBusAssignmentsToGoogleCalendar, // Pass the bus sync callback
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
  
  void _showSettingsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          resetRestDaysCallback: _resetRestDays,
          isDarkModeNotifier: widget.isDarkModeNotifier,
        ),
      ),
    ).then((_) {
      // Reload marked in settings when returning from settings page
      _loadMarkedInSettings();
    });
  }

  // Responsive sizing helper for holidays section
  Map<String, double> _getHolidayResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Very small screens (narrow phones) - ULTRA conservative
    if (screenWidth < 350) {
      return {
        'padding': 8.0,
        'headerPadding': 10.0,
        'itemPadding': 8.0,
        'spacing': 8.0,
        'headerFontSize': 14.0,
        'subtitleFontSize': 11.0,
        'yearFontSize': 14.0,
        'itemTitleFontSize': 13.0,
        'itemSubtitleFontSize': 11.0,
        'iconSize': 18.0,
        'headerIconSize': 18.0,
        'badgeIconSize': 10.0,
        'badgeFontSize': 10.0,
        'maxHeight': screenHeight * 0.35,
        'borderRadius': 10.0,
      };
    }
    // Small phones (like older iPhones)
    else if (screenWidth < 400) {
      return {
        'padding': 10.0,
        'headerPadding': 12.0,
        'itemPadding': 9.0,
        'spacing': 10.0,
        'headerFontSize': 15.0,
        'subtitleFontSize': 11.5,
        'yearFontSize': 15.0,
        'itemTitleFontSize': 13.5,
        'itemSubtitleFontSize': 11.5,
        'iconSize': 19.0,
        'headerIconSize': 19.0,
        'badgeIconSize': 11.0,
        'badgeFontSize': 10.5,
        'maxHeight': screenHeight * 0.38,
        'borderRadius': 11.0,
      };
    }
    // Mid-range phones (like Galaxy S23)
    else if (screenWidth < 450) {
      return {
        'padding': 11.0,
        'headerPadding': 12.0,
        'itemPadding': 10.0,
        'spacing': 11.0,
        'headerFontSize': 15.5,
        'subtitleFontSize': 12.0,
        'yearFontSize': 15.5,
        'itemTitleFontSize': 14.0,
        'itemSubtitleFontSize': 12.0,
        'iconSize': 20.0,
        'headerIconSize': 20.0,
        'badgeIconSize': 11.5,
        'badgeFontSize': 11.0,
        'maxHeight': screenHeight * 0.4,
        'borderRadius': 12.0,
      };
    }
    // Regular phones
    else if (screenWidth < 600) {
      return {
        'padding': 12.0,
        'headerPadding': 12.0,
        'itemPadding': 10.0,
        'spacing': 12.0,
        'headerFontSize': 16.0,
        'subtitleFontSize': 12.0,
        'yearFontSize': 16.0,
        'itemTitleFontSize': 14.0,
        'itemSubtitleFontSize': 12.0,
        'iconSize': 20.0,
        'headerIconSize': 20.0,
        'badgeIconSize': 12.0,
        'badgeFontSize': 11.0,
        'maxHeight': screenHeight * 0.4,
        'borderRadius': 12.0,
      };
    }
    // Tablets
    else if (screenWidth < 900) {
      return {
        'padding': 14.0,
        'headerPadding': 14.0,
        'itemPadding': 12.0,
        'spacing': 14.0,
        'headerFontSize': 17.0,
        'subtitleFontSize': 13.0,
        'yearFontSize': 17.0,
        'itemTitleFontSize': 15.0,
        'itemSubtitleFontSize': 13.0,
        'iconSize': 22.0,
        'headerIconSize': 22.0,
        'badgeIconSize': 13.0,
        'badgeFontSize': 12.0,
        'maxHeight': screenHeight * 0.45,
        'borderRadius': 14.0,
      };
    }
    // Large tablets/desktop
    else {
      return {
        'padding': 16.0,
        'headerPadding': 16.0,
        'itemPadding': 14.0,
        'spacing': 16.0,
        'headerFontSize': 18.0,
        'subtitleFontSize': 14.0,
        'yearFontSize': 18.0,
        'itemTitleFontSize': 16.0,
        'itemSubtitleFontSize': 14.0,
        'iconSize': 24.0,
        'headerIconSize': 24.0,
        'badgeIconSize': 14.0,
        'badgeFontSize': 13.0,
        'maxHeight': screenHeight * 0.5,
        'borderRadius': 16.0,
      };
    }
  }

  // Build enhanced holidays section with year grouping and scrollable list
  Widget _buildHolidaysSection(BuildContext context) {
    final sizes = _getHolidayResponsiveSizes(context);
    
    // Group holidays by year
    final Map<int, List<Holiday>> holidaysByYear = {};
    for (final holiday in _holidays) {
      final year = holiday.startDate.year;
      holidaysByYear.putIfAbsent(year, () => []).add(holiday);
    }
    
    // Sort years descending (newest first)
    final sortedYears = holidaysByYear.keys.toList()..sort((a, b) => b.compareTo(a));
    
    // Sort holidays within each year by start date
    for (final year in sortedYears) {
      holidaysByYear[year]!.sort((a, b) => a.startDate.compareTo(b.startDate));
    }
    
    final totalHolidays = _holidays.length;
    final totalYears = sortedYears.length;
    
    return StatefulBuilder(
      builder: (context, setState) {
        // Initialize expanded state for new years (default to collapsed)
        for (final year in sortedYears) {
          _holidayYearExpanded.putIfAbsent(year, () => false);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with summary
            Container(
              padding: EdgeInsets.all(sizes['headerPadding']!),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? holidayColor.withValues(alpha: 0.15)
                    : holidayColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(sizes['borderRadius']!),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? holidayColor.withValues(alpha: 0.4)
                      : holidayColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(sizes['padding']!),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? holidayColor.withValues(alpha: 0.25)
                          : holidayColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.67),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: holidayColor,
                      size: sizes['headerIconSize']!,
                    ),
                  ),
                  SizedBox(width: sizes['spacing']!),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Existing Holidays',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: sizes['headerFontSize']!,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '$totalHolidays ${totalHolidays == 1 ? 'holiday' : 'holidays'} across $totalYears ${totalYears == 1 ? 'year' : 'years'}',
                          style: TextStyle(
                            fontSize: sizes['subtitleFontSize']!,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sizes['spacing']!),
            // List of holidays grouped by year (scrolls with outer dialog)
            // Using Column instead of ListView to avoid nested scrolling
            Column(
              children: List.generate(sortedYears.length, (index) {
                if (index > 0) {
                  return Column(
                    children: [
                      SizedBox(height: sizes['spacing']! * 0.67),
                      _buildYearHolidaySection(
                        context,
                        sortedYears[index],
                        holidaysByYear[sortedYears[index]]!,
                        sizes,
                        setState,
                      ),
                    ],
                  );
                }
                return _buildYearHolidaySection(
                  context,
                  sortedYears[index],
                  holidaysByYear[sortedYears[index]]!,
                  sizes,
                  setState,
                );
              }),
            ),
          ],
        );
      },
    );
  }

  // Build a single year's holiday section
  Widget _buildYearHolidaySection(
    BuildContext context,
    int year,
    List<Holiday> yearHolidays,
    Map<String, double> sizes,
    StateSetter setState,
  ) {
    final isExpanded = _holidayYearExpanded[year] ?? false;
    
    // Count holidays by type for this year
    final winterCount = yearHolidays.where((h) => h.type == 'winter').length;
    final summerCount = yearHolidays.where((h) => h.type == 'summer').length;
    final unpaidLeaveCount = yearHolidays.where((h) => h.type == 'unpaid_leave').length;
    final dayInLieuCount = yearHolidays.where((h) => h.type == 'day_in_lieu').length;
    final otherCount = yearHolidays.where((h) => h.type == 'other').length;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(sizes['borderRadius']!),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).dividerColor
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Year header (collapsible)
          InkWell(
            onTap: () {
              setState(() {
                _holidayYearExpanded[year] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(sizes['borderRadius']!),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: sizes['padding']!,
                vertical: sizes['padding']! * 0.83,
              ),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sizes['padding']! * 0.83,
                        vertical: sizes['padding']! * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? holidayColor.withValues(alpha: 0.2)
                            : holidayColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.67),
                      ),
                      child: Text(
                        year.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: sizes['yearFontSize']!,
                          color: holidayColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: sizes['spacing']!),
                  Expanded(
                    child: Wrap(
                      spacing: sizes['spacing']! * 0.5,
                      runSpacing: sizes['spacing']! * 0.5,
                      children: [
                        if (winterCount > 0)
                          _buildTypeBadge('Winter', winterCount, Colors.blue, sizes),
                        if (summerCount > 0)
                          _buildTypeBadge('Summer', summerCount, Colors.orange, sizes),
                        if (unpaidLeaveCount > 0)
                          _buildTypeBadge('Unpaid Leave', unpaidLeaveCount, Colors.purple, sizes),
                        if (dayInLieuCount > 0)
                          _buildTypeBadge('Day In Lieu', dayInLieuCount, ColorCustomizationService.getColorForShift('DAY_IN_LIEU'), sizes),
                        if (otherCount > 0)
                          _buildTypeBadge('Other', otherCount, Colors.grey, sizes),
                      ],
                    ),
                  ),
                  SizedBox(width: sizes['spacing']! * 0.5),
                  Container(
                    padding: EdgeInsets.all(sizes['padding']! * 0.33),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.5),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: sizes['iconSize']!,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Holidays list (expandable)
          if (isExpanded) ...[
            Divider(height: 1),
            ...yearHolidays.asMap().entries.map((entry) {
              final index = entry.key;
              final holiday = entry.value;
              return Column(
                children: [
                  if (index > 0) SizedBox(height: sizes['spacing']! * 0.33),
                  Padding(
                    padding: EdgeInsets.all(sizes['padding']!),
                    child: _buildHolidayItem(context, holiday, sizes),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  // Build type badge for holiday counts
  Widget _buildTypeBadge(String type, int count, Color color, Map<String, double> sizes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizes['padding']! * 0.5,
        vertical: sizes['padding']! * 0.17,
      ),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == 'Winter' ? Icons.ac_unit :
            type == 'Summer' ? Icons.wb_sunny :
            type == 'Unpaid Leave' ? Icons.money_off :
            type == 'Day In Lieu' ? Icons.event_available :
            Icons.event,
            size: sizes['badgeIconSize']!,
            color: color,
          ),
          SizedBox(width: sizes['padding']! * 0.33),
          Text(
            '$count',
            style: TextStyle(
              fontSize: sizes['badgeFontSize']!,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Build individual holiday item
  Widget _buildHolidayItem(BuildContext context, Holiday holiday, Map<String, double> sizes) {
    final dateText = holiday.startDate == holiday.endDate
        ? DateFormat('MMM d, yyyy').format(holiday.startDate)
        : '${DateFormat('MMM d, yyyy').format(holiday.startDate)} - ${DateFormat('MMM d, yyyy').format(holiday.endDate)}';
    
    final isWinter = holiday.type == 'winter';
    final isSummer = holiday.type == 'summer';
    final isUnpaidLeave = holiday.type == 'unpaid_leave';
    final isDayInLieu = holiday.type == 'day_in_lieu';
    final iconColor = isWinter 
        ? Colors.blue 
        : isSummer 
            ? Colors.orange 
            : isUnpaidLeave
                ? Colors.purple
                : isDayInLieu
                    ? ColorCustomizationService.getColorForShift('DAY_IN_LIEU')
                    : Colors.grey;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(sizes['itemPadding']!),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.67),
        border: Border.all(
          color: isDark ? Theme.of(context).dividerColor : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(sizes['padding']! * 0.8),
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.2) : iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.67),
            ),
            child: Icon(
              isWinter ? Icons.ac_unit :
              isSummer ? Icons.wb_sunny :
              isUnpaidLeave ? Icons.money_off :
              isDayInLieu ? Icons.event_available :
              Icons.event,
              color: iconColor,
              size: sizes['iconSize']!,
            ),
          ),
          SizedBox(width: sizes['spacing']!),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWinter ? 'Winter Holiday' :
                  isSummer ? 'Summer Holiday' :
                  isUnpaidLeave ? 'Unpaid Leave' :
                  isDayInLieu ? 'Day In Lieu' :
                  'Other Holiday',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: sizes['itemTitleFontSize']!,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  dateText,
                  style: TextStyle(
                    fontSize: sizes['itemSubtitleFontSize']!,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: sizes['spacing']! * 0.67),
          InkWell(
            onTap: () async {
              // Show confirmation dialog
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text('Remove Holiday'),
                    ],
                  ),
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
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Holiday removed successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  
                  // Force a rebuild of the calendar to update holiday indicators
                  _updateAllEvents();
                  
                  // Close and reopen the dialog to refresh the view
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  if (!mounted) return;
                  _showAddHolidaysDialog();
                }
              }
            },
            borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.67),
            child: Container(
              padding: EdgeInsets.all(sizes['padding']! * 0.5),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(sizes['borderRadius']! * 0.67),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: sizes['iconSize']! * 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getHolidayBalances() async {
    final annualLeaveBalance = await AnnualLeaveService.getBalance();
    final annualLeaveRemaining = await AnnualLeaveService.getRemainingDays();
    final annualLeaveUsed = await AnnualLeaveService.getUsedDays();
    final daysInLieuBalance = await DaysInLieuService.getBalance();
    final daysInLieuRemaining = await DaysInLieuService.getRemainingDays();
    final daysInLieuUsed = await DaysInLieuService.getUsedDays();
    
    return {
      'annualLeaveToday': annualLeaveBalance,
      'annualLeaveRemaining': annualLeaveRemaining,
      'annualLeaveBooked': annualLeaveUsed,
      'daysInLieuToday': daysInLieuBalance,
      'daysInLieuRemaining': daysInLieuRemaining,
      'daysInLieuBooked': daysInLieuUsed,
    };
  }

  Widget _buildBalanceItem(String label, int value, Color color, {VoidCallback? onTap}) {
    // Responsive sizing based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final labelFontSize = screenWidth < 350 ? 9.0 : screenWidth < 400 ? 9.5 : screenWidth < 600 ? 10.0 : 11.0;
    final valueFontSize = screenWidth < 350 ? 12.0 : screenWidth < 400 ? 13.0 : screenWidth < 600 ? 14.0 : 15.0;
    
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: column,
      );
    }
    
    return column;
  }

  void _showBookedHolidaysDialog(BuildContext context, String holidayType) async {
    final holidays = await HolidayService.getHolidays();
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    List<Holiday> bookedHolidays = [];
    
    if (holidayType == 'annualLeave') {
      // For Annual Leave: Show winter, summer, and other holidays that start today or in the future
      bookedHolidays = holidays.where((holiday) {
        if (holiday.type != 'winter' && holiday.type != 'summer' && holiday.type != 'other') {
          return false;
        }
        final startDateNormalized = DateTime(
          holiday.startDate.year,
          holiday.startDate.month,
          holiday.startDate.day,
        );
        return !startDateNormalized.isBefore(todayNormalized);
      }).toList();
      
      // Sort by start date
      bookedHolidays.sort((a, b) => a.startDate.compareTo(b.startDate));
    } else if (holidayType == 'daysInLieu') {
      // For Days In Lieu: Show all day_in_lieu holidays
      bookedHolidays = holidays.where((holiday) => holiday.type == 'day_in_lieu').toList();
      
      // Sort by start date
      bookedHolidays.sort((a, b) => a.startDate.compareTo(b.startDate));
    }
    
    if (bookedHolidays.isEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            holidayType == 'annualLeave' ? 'Booked Annual Leave' : 'Booked Days In Lieu',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text('No holidays booked yet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    
    if (!context.mounted) return;
    // Capture holidayType for use in callbacks
    final capturedHolidayType = holidayType;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Create a mutable list that can be updated
          final currentHolidays = <Holiday>[...bookedHolidays];
          
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width < 600 
                    ? MediaQuery.of(context).size.width * 0.95 
                    : MediaQuery.of(context).size.width < 900 
                        ? MediaQuery.of(context).size.width * 0.85 
                        : 600.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          capturedHolidayType == 'annualLeave' ? Icons.beach_access : Icons.event_available,
                          color: capturedHolidayType == 'annualLeave' 
                              ? Theme.of(context).colorScheme.primary
                              : ColorCustomizationService.getColorForShift('DAY_IN_LIEU'),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            capturedHolidayType == 'annualLeave' ? 'Booked Annual Leave' : 'Booked Days In Lieu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleLarge?.color,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          iconSize: 22,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),
                  // List of holidays
                  Flexible(
                    child: currentHolidays.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                'No holidays booked yet.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: currentHolidays.length,
                            itemBuilder: (context, index) {
                              // Return widget here
                              final holiday = currentHolidays[index];
                              final isWinter = holiday.type == 'winter';
                              final isSummer = holiday.type == 'summer';
                              final isDayInLieu = holiday.type == 'day_in_lieu';
                              
                              String holidayTypeLabel;
                              Color holidayColor;
                              IconData holidayIcon;
                              
                              if (isWinter) {
                                holidayTypeLabel = 'Winter Holiday';
                                holidayColor = Colors.blue;
                                holidayIcon = Icons.ac_unit;
                              } else if (isSummer) {
                                holidayTypeLabel = 'Summer Holiday';
                                holidayColor = Colors.orange;
                                holidayIcon = Icons.wb_sunny;
                              } else if (isDayInLieu) {
                                holidayTypeLabel = 'Day In Lieu';
                                holidayColor = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
                                holidayIcon = Icons.event_available;
                              } else {
                                holidayTypeLabel = 'Other Holiday';
                                holidayColor = Colors.grey;
                                holidayIcon = Icons.event;
                              }
                              
                              final dateText = holiday.startDate == holiday.endDate
                                  ? DateFormat('MMM d, yyyy').format(holiday.startDate)
                                  : '${DateFormat('MMM d, yyyy').format(holiday.startDate)} - ${DateFormat('MMM d, yyyy').format(holiday.endDate)}';
                              
                              final daysCount = holiday.endDate.difference(holiday.startDate).inDays + 1;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Theme.of(context).cardColor
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).dividerColor
                                          : Colors.grey.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: holidayColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            holidayIcon,
                                            color: holidayColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                holidayTypeLabel,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                dateText,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: holidayColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$daysCount ${daysCount == 1 ? 'day' : 'days'}',
                                            style: TextStyle(
                                              color: holidayColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () async {
                                            // Show confirmation dialog
                                            final shouldDelete = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Holiday'),
                                                content: Text('Are you sure you want to delete this ${holidayTypeLabel.toLowerCase()}?'),
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
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            
                                            if (shouldDelete == true && context.mounted) {
                                              try {
                                                // Remove the holiday
                                                await HolidayService.removeHoliday(holiday.id);
                                                
                                                // Reload holidays
                                                final updatedHolidays = await HolidayService.getHolidays();
                                                final today = DateTime.now();
                                                final todayNormalized = DateTime(today.year, today.month, today.day);
                                                
                                                List<Holiday> updatedBookedHolidays = [];
                                                
                                                if (capturedHolidayType == 'annualLeave') {
                                                  updatedBookedHolidays = updatedHolidays.where((h) {
                                                    if (h.type != 'winter' && h.type != 'summer' && h.type != 'other') {
                                                      return false;
                                                    }
                                                    final startDateNormalized = DateTime(
                                                      h.startDate.year,
                                                      h.startDate.month,
                                                      h.startDate.day,
                                                    );
                                                    return !startDateNormalized.isBefore(todayNormalized);
                                                  }).toList();
                                                  updatedBookedHolidays.sort((a, b) => a.startDate.compareTo(b.startDate));
                                                } else if (capturedHolidayType == 'daysInLieu') {
                                                  updatedBookedHolidays = updatedHolidays.where((h) => h.type == 'day_in_lieu').toList();
                                                  updatedBookedHolidays.sort((a, b) => a.startDate.compareTo(b.startDate));
                                                }
                                                
                                                // Update the dialog state
                                                setDialogState(() {
                                                  currentHolidays.clear();
                                                  currentHolidays.addAll(updatedBookedHolidays);
                                                });
                                                
                                                // Reload holidays in the main screen
                                                await _reloadHolidays();
                                                
                                                // Update calendar events
                                                _updateAllEvents();
                                                
                                                // Show success message
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Row(
                                                        children: [
                                                          Icon(Icons.check_circle, color: Colors.white),
                                                          SizedBox(width: 8),
                                                          Text('Holiday removed successfully'),
                                                        ],
                                                      ),
                                                      backgroundColor: Colors.green,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                                
                                                // If no holidays left, close dialog
                                                if (updatedBookedHolidays.isEmpty && context.mounted) {
                                                  Navigator.of(context).pop();
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error removing holiday: $e'),
                                                      backgroundColor: Colors.red,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red.shade400,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddHolidaysDialog() {
    final scrollController = ScrollController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width < 600 
                  ? MediaQuery.of(context).size.width * 0.95 
                  : MediaQuery.of(context).size.width < 900 
                      ? MediaQuery.of(context).size.width * 0.85 
                      : 600.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Add Holidays',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          scrollController.dispose();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                // Balance display (compact)
                FutureBuilder<Map<String, int>>(
                  future: _getHolidayBalances(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final balances = snapshot.data!;
                    final primaryColor = Theme.of(context).colorScheme.primary;
                    final dayInLieuColor = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Annual Leave
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Annual Leave',
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width < 350 ? 11.0 : MediaQuery.of(context).size.width < 600 ? 12.0 : 13.0,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildBalanceItem('Today', balances['annualLeaveToday']!, primaryColor),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 20,
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                        ),
                                        Expanded(
                                          child: _buildBalanceItem('Remaining', balances['annualLeaveRemaining']!, primaryColor),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 20,
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                        ),
                                        Expanded(
                                          child: _buildBalanceItem(
                                            'Booked', 
                                            balances['annualLeaveBooked']!, 
                                            Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                            onTap: () => _showBookedHolidaysDialog(context, 'annualLeave'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 1,
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          // Days In Lieu
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Days In Lieu',
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width < 350 ? 11.0 : MediaQuery.of(context).size.width < 600 ? 12.0 : 13.0,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildBalanceItem('Today', balances['daysInLieuToday']!, dayInLieuColor),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 20,
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                        ),
                                        Expanded(
                                          child: _buildBalanceItem('Remaining', balances['daysInLieuRemaining']!, dayInLieuColor),
                                        ),
                                        Container(
                                          width: 1,
                                          height: 20,
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                        ),
                                        Expanded(
                                          child: _buildBalanceItem(
                                            'Booked', 
                                            balances['daysInLieuBooked']!, 
                                            Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                            onTap: () => _showBookedHolidaysDialog(context, 'daysInLieu'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Add new holiday section (static at top)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Holiday',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          scrollController.dispose();
                          Navigator.of(context).pop();
                          _showSummerHolidayDateDialog();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.wb_sunny, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                'Summer Holiday',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          scrollController.dispose();
                          Navigator.of(context).pop();
                          _showWinterHolidayDateDialog();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.ac_unit, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                'Winter (1 Week)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          scrollController.dispose();
                          Navigator.of(context).pop();
                          _showOtherHolidayDialog();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.event, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                'Other Holiday',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          scrollController.dispose();
                          Navigator.of(context).pop();
                          _showUnpaidLeaveDialog();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.money_off, size: 22, color: Colors.purple),
                              const SizedBox(width: 12),
                              Text(
                                'Unpaid Leave',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          scrollController.dispose();
                          Navigator.of(context).pop();
                          _showDayInLieuDialog();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 22,
                                color: ColorCustomizationService.getColorForShift('DAY_IN_LIEU'),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Day In Lieu',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider before scrollable section
                if (_holidays.isNotEmpty) const Divider(height: 1),
                // Existing holidays section (scrollable)
                if (_holidays.isNotEmpty)
                  Flexible(
                    child: Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(3),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: _buildHolidaysSection(context),
                        ),
                      ),
                    ),
                  ),
                // Bottom divider and close button
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        scrollController.dispose();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    ).then((_) {
      // Dispose controller when dialog is closed (handles cases where dialog closes without button press)
      scrollController.dispose();
    });
  }

  // Helper method to get all Sundays for a specific year
  List<DateTime> _getSundaysForYear(int year) {
    final firstDayOfYear = DateTime(year, 1, 1);
    final lastDayOfYear = DateTime(year, 12, 31);
    
    // Find the first Sunday of the year
    var firstSunday = firstDayOfYear;
    while (firstSunday.weekday != DateTime.sunday) {
      firstSunday = firstSunday.add(const Duration(days: 1));
    }
    
    // Create a list of all Sundays in the year
    final sundays = <DateTime>[];
    var currentSunday = firstSunday;
    
    while (currentSunday.isBefore(lastDayOfYear) || currentSunday.isAtSameMomentAs(lastDayOfYear)) {
      sundays.add(currentSunday);
      currentSunday = currentSunday.add(const Duration(days: 7));
    }
    
    return sundays;
  }

  // Helper method to check if a holiday already exists for a specific date and type
  Future<bool> _hasHolidayForDate(DateTime date, String type) async {
    final holidays = await HolidayService.getHolidays();
    return holidays.any((h) => 
      h.type == type && 
      h.containsDate(date)
    );
  }

  void _showWinterHolidayDateDialog() {
    final now = DateTime.now();
    final currentYear = now.year;
    
    // Show year selection first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return FutureBuilder<Map<int, int>>(
              future: _getHolidayCountsForYears(currentYear, 'winter'),
              builder: (context, snapshot) {
                final holidayCounts = snapshot.data ?? {};
                
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue.shade900.withValues(alpha: 0.3)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.ac_unit, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Year for Winter Holiday',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Year selection grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: 5, // Current year + 4 future years
                          itemBuilder: (context, index) {
                            final year = currentYear + index;
                            final count = holidayCounts[year] ?? 0;
                            final hasHolidays = count > 0;
                            
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showWinterHolidayDateDialogForYear(year);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? (hasHolidays 
                                            ? Colors.blue.shade900.withValues(alpha: 0.3)
                                            : Theme.of(context).cardColor)
                                        : (hasHolidays 
                                            ? Colors.blue.shade50 
                                            : Colors.grey.shade50),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? (hasHolidays 
                                              ? Colors.blue.shade700 
                                              : Theme.of(context).dividerColor)
                                          : (hasHolidays 
                                              ? Colors.blue.shade200 
                                              : Colors.grey.shade300),
                                      width: hasHolidays ? 2 : 1,
                                    ),
                                    boxShadow: hasHolidays ? [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        year.toString(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Theme.of(context).textTheme.bodyLarge?.color
                                              : (hasHolidays 
                                                  ? Colors.blue.shade700 
                                                  : Colors.grey.shade700),
                                        ),
                                      ),
                                      if (hasHolidays) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.blue.shade800.withValues(alpha: 0.5)
                                                : Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$count ${count == 1 ? 'holiday' : 'holidays'}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.blue.shade300
                                                  : Colors.blue.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue.shade900.withValues(alpha: 0.3)
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline, 
                                size: 16, 
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade300
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Select a year to choose your winter holiday start date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.blue.shade300
                                        : Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Helper to get holiday counts for multiple years
  Future<Map<int, int>> _getHolidayCountsForYears(int startYear, String type) async {
    final holidays = await HolidayService.getHolidays();
    final counts = <int, int>{};
    
    for (int i = 0; i < 5; i++) {
      final year = startYear + i;
      counts[year] = holidays.where((h) => 
        h.type == type && 
        h.startDate.year == year
      ).length;
    }
    
    return counts;
  }

  // Show winter holiday date selection for a specific year
  void _showWinterHolidayDateDialogForYear(int year) {
    final sundays = _getSundaysForYear(year);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final listHeight = (screenHeight * 0.5).clamp(250.0, 400.0);
        
        return FutureBuilder<List<bool>>(
          future: Future.wait(
            sundays.map((date) => _hasHolidayForDate(date, 'winter'))
          ),
          builder: (context, snapshot) {
            final hasHolidayFlags = snapshot.data ?? List.filled(sundays.length, false);
            
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade900.withValues(alpha: 0.3)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.ac_unit, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Select Winter Holiday Start Date',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Year: $year',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showWinterHolidayDateDialog();
                    },
                    tooltip: 'Change year',
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.only(top: 8, bottom: 0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).dividerColor
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: SizedBox(
                      width: double.maxFinite,
                      height: listHeight,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sundays.length,
                        itemBuilder: (context, index) {
                          final date = sundays[index];
                          final alreadyHasHoliday = hasHolidayFlags[index];
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? (alreadyHasHoliday 
                                      ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                                      : Theme.of(context).cardColor)
                                  : (alreadyHasHoliday 
                                      ? Colors.grey.shade100 
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? (alreadyHasHoliday 
                                        ? Theme.of(context).dividerColor
                                        : Colors.blue.shade700)
                                    : (alreadyHasHoliday 
                                        ? Colors.grey.shade300 
                                        : Colors.blue.shade100),
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
                                onTap: alreadyHasHoliday ? null : () async {
                                  // Create a new holiday starting on the selected Sunday
                                  final holiday = Holiday(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    startDate: date,
                                    endDate: date.add(const Duration(days: 6)), // End on Saturday
                                    type: 'winter',
                                  );
                                  
                                  // Add the holiday
                                  await HolidayService.addHoliday(holiday);
                                  
                                  // Reload holidays from storage to ensure consistency
                                  await _reloadHolidays();
                                  
                                  // Close the dialog
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  
                                  // Show success message
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Winter holiday for $year added successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? (alreadyHasHoliday 
                                                  ? Theme.of(context).dividerColor
                                                  : Colors.blue.shade900.withValues(alpha: 0.3))
                                              : (alreadyHasHoliday 
                                                  ? Colors.grey.shade300 
                                                  : Colors.blue.shade50),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Sun',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? (alreadyHasHoliday 
                                                    ? Theme.of(context).textTheme.bodySmall?.color
                                                    : Colors.blue.shade300)
                                                : (alreadyHasHoliday 
                                                    ? Colors.grey.shade600 
                                                    : Colors.blue.shade700),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('MMM d, yyyy').format(date),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Theme.of(context).textTheme.bodyLarge?.color
                                                    : (alreadyHasHoliday 
                                                        ? Colors.grey.shade600 
                                                        : Colors.black87),
                                              ),
                                            ),
                                            if (alreadyHasHoliday)
                                              Text(
                                                'Already added',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!alreadyHasHoliday)
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.blue.shade300,
                                        )
                                      else
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.grey.shade400,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showWinterHolidayDateDialog();
                      },
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Change Year'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.shade300
                            : Colors.blue.shade700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
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

  void _showSummerHolidayDateDialog() {
    // Show duration choice first
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.orange.shade900.withValues(alpha: 0.3)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Select Duration',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showSummerHolidayYearDialog(durationWeeks: 1);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_view_week, color: Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '1 Week',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Sunday to Saturday (7 days)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    _showSummerHolidayYearDialog(durationWeeks: 2);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_view_month, color: Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '2 Weeks',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Sunday to Saturday (14 days)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSummerHolidayYearDialog({required int durationWeeks}) {
    final now = DateTime.now();
    final currentYear = now.year;
    
    // Show year selection
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return FutureBuilder<Map<int, int>>(
              future: _getHolidayCountsForYears(currentYear, 'summer'),
              builder: (context, snapshot) {
                final holidayCounts = snapshot.data ?? {};
                
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange.shade900.withValues(alpha: 0.3)
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Year for Summer Holiday',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Year selection grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: 5, // Current year + 4 future years
                          itemBuilder: (context, index) {
                            final year = currentYear + index;
                            final count = holidayCounts[year] ?? 0;
                            final hasHolidays = count > 0;
                            
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _showSummerHolidayDateDialogForYear(year, durationWeeks: durationWeeks);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? (hasHolidays 
                                            ? Colors.orange.shade900.withValues(alpha: 0.3)
                                            : Theme.of(context).cardColor)
                                        : (hasHolidays 
                                            ? Colors.orange.shade50 
                                            : Colors.grey.shade50),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? (hasHolidays 
                                              ? Colors.orange.shade700 
                                              : Theme.of(context).dividerColor)
                                          : (hasHolidays 
                                              ? Colors.orange.shade200 
                                              : Colors.grey.shade300),
                                      width: hasHolidays ? 2 : 1,
                                    ),
                                    boxShadow: hasHolidays ? [
                                      BoxShadow(
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        year.toString(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Theme.of(context).textTheme.bodyLarge?.color
                                              : (hasHolidays 
                                                  ? Colors.orange.shade700 
                                                  : Colors.grey.shade700),
                                        ),
                                      ),
                                      if (hasHolidays) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.orange.shade800.withValues(alpha: 0.5)
                                                : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '$count ${count == 1 ? 'holiday' : 'holidays'}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.orange.shade300
                                                  : Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.orange.shade900.withValues(alpha: 0.3)
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline, 
                                size: 16, 
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.orange.shade300
                                    : Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Select a year to choose your summer holiday start date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.orange.shade300
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Show summer holiday date selection for a specific year
  void _showSummerHolidayDateDialogForYear(int year, {required int durationWeeks}) {
    final sundays = _getSundaysForYear(year);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final listHeight = (screenHeight * 0.5).clamp(250.0, 400.0);
        
        return FutureBuilder<List<bool>>(
          future: Future.wait(
            sundays.map((date) => _hasHolidayForDate(date, 'summer'))
          ),
          builder: (context, snapshot) {
            final hasHolidayFlags = snapshot.data ?? List.filled(sundays.length, false);
            
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange.shade900.withValues(alpha: 0.3)
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Select Summer Holiday Start Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Year: $year • ${durationWeeks == 1 ? '1 Week' : '2 Weeks'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showSummerHolidayDateDialog();
                    },
                    tooltip: 'Change year',
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.only(top: 8, bottom: 0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).cardColor
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).dividerColor
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: SizedBox(
                      width: double.maxFinite,
                      height: listHeight,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sundays.length,
                        itemBuilder: (context, index) {
                          final date = sundays[index];
                          final alreadyHasHoliday = hasHolidayFlags[index];
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? (alreadyHasHoliday 
                                      ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                                      : Theme.of(context).cardColor)
                                  : (alreadyHasHoliday 
                                      ? Colors.grey.shade100 
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? (alreadyHasHoliday 
                                        ? Theme.of(context).dividerColor
                                        : Colors.orange.shade700)
                                    : (alreadyHasHoliday 
                                        ? Colors.grey.shade300 
                                        : Colors.orange.shade100),
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
                                onTap: alreadyHasHoliday ? null : () async {
                                  // Create a new holiday starting on the selected Sunday
                                  // Duration: 1 week = 6 days (Sun-Sat), 2 weeks = 13 days (Sun-Sat)
                                  final daysToAdd = durationWeeks == 1 ? 6 : 13;
                                  final holiday = Holiday(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    startDate: date,
                                    endDate: date.add(Duration(days: daysToAdd)),
                                    type: 'summer',
                                  );
                                  
                                  // Add the holiday
                                  await HolidayService.addHoliday(holiday);
                                  
                                  // Reload holidays from storage to ensure consistency
                                  await _reloadHolidays();
                                  
                                  // Close the dialog
                                  if (!mounted) return;
                                  Navigator.of(context).pop();
                                  
                                  // Show success message
                                  if (!mounted) return;
                                  final durationText = durationWeeks == 1 ? '1 week' : '2 weeks';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Summer holiday ($durationText) for $year added successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? (alreadyHasHoliday 
                                                  ? Theme.of(context).dividerColor
                                                  : Colors.orange.shade900.withValues(alpha: 0.3))
                                              : (alreadyHasHoliday 
                                                  ? Colors.grey.shade300 
                                                  : Colors.orange.shade50),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Sun',
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? (alreadyHasHoliday 
                                                    ? Theme.of(context).textTheme.bodySmall?.color
                                                    : Colors.orange.shade300)
                                                : (alreadyHasHoliday 
                                                    ? Colors.grey.shade600 
                                                    : Colors.orange.shade700),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('MMM d, yyyy').format(date),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Theme.of(context).textTheme.bodyLarge?.color
                                                    : (alreadyHasHoliday 
                                                        ? Colors.grey.shade600 
                                                        : Colors.black87),
                                              ),
                                            ),
                                            Text(
                                              'Ends: ${DateFormat('MMM d, yyyy').format(date.add(const Duration(days: 13)))}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                              ),
                                            ),
                                            if (alreadyHasHoliday)
                                              Text(
                                                'Already added',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (!alreadyHasHoliday)
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.orange.shade300,
                                        )
                                      else
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.grey.shade400,
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
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Scroll to see more dates',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showSummerHolidayDateDialog();
                      },
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Change Year'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange.shade300
                            : Colors.orange.shade700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
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

  // Add this new function to update all events
  Future<void> _updateAllEvents() async {
    // Instead of loading all events at once, we'll just preload the current month
    await EventService.preloadMonth(_focusedDay);
    setState(() {});
  }



  void _showOtherHolidayDialog() {
    final Set<DateTime> selectedDates = {};
    DateTime currentMonth = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                      const Expanded(
                        child: Text(
                          'Select Holiday Dates',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(currentMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildMultiSelectCalendar(
                        currentMonth: currentMonth,
                        selectedDates: selectedDates,
                        onDateTapped: (date) {
                          setState(() {
                            // Normalize date to midnight for comparison
                            final normalizedDate = DateTime(date.year, date.month, date.day);
                            if (selectedDates.contains(normalizedDate)) {
                              selectedDates.remove(normalizedDate);
                            } else {
                              selectedDates.add(normalizedDate);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (selectedDates.isNotEmpty) ...[
                  const Divider(height: 0),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${selectedDates.length} day${selectedDates.length == 1 ? '' : 's'} selected',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                        onPressed: selectedDates.isEmpty ? null : () async {
                          // Create a separate holiday for each selected date
                          final sortedDates = selectedDates.toList()..sort();
                          int successCount = 0;
                          
                          for (final date in sortedDates) {
                            try {
                              final holiday = Holiday(
                                id: 'other_${date.millisecondsSinceEpoch}',
                                startDate: date,
                                endDate: date,
                                type: 'other',
                              );
                              
                              await HolidayService.addHoliday(holiday);
                              successCount++;
                            } catch (e) {
                              // Continue with other dates even if one fails
                            }
                          }
                          
                          // Reload holidays from storage to ensure consistency
                          await _reloadHolidays();
                          
                          // Close the dialog
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          
                          // Show success message
                          if (!mounted) return;
                          final message = successCount == 1
                              ? 'Holiday added successfully'
                              : '$successCount holidays added successfully';
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Text(selectedDates.length == 1 ? 'Add Holiday' : 'Add Holidays'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMultiSelectCalendar({
    required DateTime currentMonth,
    required Set<DateTime> selectedDates,
    required Function(DateTime) onDateTapped,
  }) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7; // 0 = Sunday, 6 = Saturday
    final daysInMonth = lastDayOfMonth.day;
    
    // Get all dates in the month
    final List<DateTime> dates = [];
    for (int day = 1; day <= daysInMonth; day++) {
      dates.add(DateTime(currentMonth.year, currentMonth.month, day));
    }
    
    // Get previous month's dates for padding
    final List<DateTime> previousMonthDates = [];
    if (firstDayOfWeek > 0) {
      final previousMonth = DateTime(currentMonth.year, currentMonth.month - 1);
      final lastDayOfPreviousMonth = DateTime(previousMonth.year, previousMonth.month + 1, 0);
      for (int i = firstDayOfWeek - 1; i >= 0; i--) {
        previousMonthDates.add(DateTime(previousMonth.year, previousMonth.month, lastDayOfPreviousMonth.day - i));
      }
    }
    
    // Get next month's dates for padding
    final List<DateTime> nextMonthDates = [];
    final totalCells = previousMonthDates.length + dates.length;
    final remainingCells = 42 - totalCells; // 6 weeks * 7 days
    if (remainingCells > 0) {
      for (int day = 1; day <= remainingCells; day++) {
        nextMonthDates.add(DateTime(currentMonth.year, currentMonth.month + 1, day));
      }
    }
    
    final allDates = [...previousMonthDates, ...dates, ...nextMonthDates];
    
    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: allDates.length,
          itemBuilder: (context, index) {
            final date = allDates[index];
            final isCurrentMonth = date.month == currentMonth.month;
            final normalizedDate = DateTime(date.year, date.month, date.day);
            final isSelected = selectedDates.contains(normalizedDate);
            final isToday = normalizedDate.year == DateTime.now().year &&
                normalizedDate.month == DateTime.now().month &&
                normalizedDate.day == DateTime.now().day;
            
            final minDate = DateTime.now().subtract(const Duration(days: 365));
            final maxDate = DateTime.now().add(const Duration(days: 365));
            final isWithinRange = !date.isBefore(minDate) && !date.isAfter(maxDate);
            
            return GestureDetector(
              onTap: isWithinRange && isCurrentMonth
                  ? () => onDateTapped(date)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.green
                      : isToday
                          ? Colors.green.shade100
                          : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : !isCurrentMonth
                              ? Colors.grey.shade300
                              : !isWithinRange
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showUnpaidLeaveDialog() {
    Set<DateTime> selectedDates = {};
    DateTime currentMonth = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.money_off, color: Colors.purple),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select Unpaid Leave Dates',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(currentMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildMultiSelectCalendar(
                        currentMonth: currentMonth,
                        selectedDates: selectedDates,
                        onDateTapped: (date) {
                          setState(() {
                            // Normalize date to midnight for comparison
                            final normalizedDate = DateTime(date.year, date.month, date.day);
                            if (selectedDates.contains(normalizedDate)) {
                              selectedDates.remove(normalizedDate);
                            } else {
                              selectedDates.add(normalizedDate);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (selectedDates.isNotEmpty) ...[
                  const Divider(height: 0),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.purple.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${selectedDates.length} day${selectedDates.length == 1 ? '' : 's'} selected',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                        onPressed: selectedDates.isEmpty ? null : () async {
                          // Create a separate holiday for each selected date
                          final sortedDates = selectedDates.toList()..sort();
                          int successCount = 0;
                          
                          for (final date in sortedDates) {
                            try {
                              final holiday = Holiday(
                                id: 'unpaid_leave_${date.millisecondsSinceEpoch}',
                                startDate: date,
                                endDate: date,
                                type: 'unpaid_leave',
                              );
                              
                              await HolidayService.addHoliday(holiday);
                              successCount++;
                            } catch (e) {
                              // Continue with other dates even if one fails
                            }
                          }
                          
                          // Reload holidays from storage to ensure consistency
                          await _reloadHolidays();
                          
                          // Close the dialog
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          
                          // Force calendar rebuild to show the new unpaid leave
                          if (!mounted) return;
                          setState(() {});
                          
                          // Show success message
                          if (!mounted) return;
                          final message = successCount == 1
                              ? 'Unpaid leave added successfully'
                              : '$successCount unpaid leave days added successfully';
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.purple,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Text(selectedDates.length == 1 ? 'Add Unpaid Leave' : 'Add Unpaid Leave Days'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDayInLieuDialog() async {
    Set<DateTime> selectedDates = {};
    DateTime currentMonth = DateTime.now();
    final dayInLieuColor = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
    
    // Load balance information
    final used = await DaysInLieuService.getUsedDays();
    final remaining = await DaysInLieuService.getRemainingDays();
    final hasZeroBalance = remaining == 0;
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                          color: dayInLieuColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.event_available, color: dayInLieuColor),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Select Day In Lieu Dates',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Balance information section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Remaining',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '$remaining',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: hasZeroBalance ? Colors.orange : null,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'Used',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '$used',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Warning if balance is 0
                if (hasZeroBalance)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Warning: You have no days in lieu remaining. Make sure to add days when you earn them in Settings.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(currentMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildMultiSelectCalendar(
                        currentMonth: currentMonth,
                        selectedDates: selectedDates,
                        onDateTapped: (date) {
                          setState(() {
                            // Normalize date to midnight for comparison
                            final normalizedDate = DateTime(date.year, date.month, date.day);
                            if (selectedDates.contains(normalizedDate)) {
                              selectedDates.remove(normalizedDate);
                            } else {
                              selectedDates.add(normalizedDate);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (selectedDates.isNotEmpty) ...[
                  const Divider(height: 0),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: dayInLieuColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: dayInLieuColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${selectedDates.length} day${selectedDates.length == 1 ? '' : 's'} selected',
                              style: TextStyle(
                                color: dayInLieuColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                        onPressed: selectedDates.isEmpty ? null : () async {
                          // Create a separate holiday for each selected date
                          final sortedDates = selectedDates.toList()..sort();
                          int successCount = 0;
                          
                          for (final date in sortedDates) {
                            try {
                              final holiday = Holiday(
                                id: 'day_in_lieu_${date.millisecondsSinceEpoch}',
                                startDate: date,
                                endDate: date,
                                type: 'day_in_lieu',
                              );
                              
                              // Add the holiday
                              await HolidayService.addHoliday(holiday);
                              
                              // Auto-decrement balance for each day
                              await DaysInLieuService.onDayInLieuAdded();
                              
                              successCount++;
                            } catch (e) {
                              // Continue with other dates even if one fails
                            }
                          }
                          
                          // Reload holidays from storage to ensure consistency
                          await _reloadHolidays();
                          
                          // Close the dialog
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          
                          // Force calendar rebuild to show the new day in lieu entries
                          if (!mounted) return;
                          setState(() {});
                          
                          // Show success message
                          if (!mounted) return;
                          final message = successCount == 1
                              ? 'Day In Lieu added successfully'
                              : '$successCount days in lieu added successfully';
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: dayInLieuColor,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dayInLieuColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Text(selectedDates.length == 1 ? 'Add Day In Lieu' : 'Add Days In Lieu'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  // --- ADD NEW FUNCTION TO NAVIGATE TO TIMING POINTS SCREEN ---
  void _showTimingPointsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TimingPointsScreen()),
    );
  }
  // --- END NEW TIMING POINTS FUNCTION ---

  void _showSearchScreen() async {
    final DateTime? selectedDate = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
    
    // If a date was returned from search, navigate to that date
    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDay = selectedDate;
        _focusedDay = selectedDate;
      });
    }
  }

  void _showWeekView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WeekViewScreen(
          selectedDate: _selectedDay ?? DateTime.now(),
          shiftInfoMap: _shiftInfoMap,
          startDate: _startDate,
          startWeek: _startWeek,
          bankHolidays: _bankHolidays,
        ),
      ),
    );
  }

  void _showYearView(int year) async {
    final selectedMonth = await Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (context) => YearViewScreen(
          key: ValueKey('year_view_$year'),
          year: year,
          shiftInfoMap: _shiftInfoMap,
          startDate: _startDate,
          startWeek: _startWeek,
          holidays: _holidays,
          bankHolidays: _bankHolidays,
        ),
      ),
    );
    
    // If a month was selected, navigate to that month
    if (selectedMonth != null && mounted) {
      // Extract year and month explicitly
      final selectedYear = selectedMonth.year;
      final selectedMonthNum = selectedMonth.month;
      
      // Create a fresh date with explicit values
      final targetDate = DateTime(selectedYear, selectedMonthNum, 1);
      
      // Preload events for the selected month before updating UI
      try {
        await EventService.preloadMonth(targetDate);
      } catch (e) {
        // Handle preload errors gracefully
      }
      
      // Update the focused day and selected day - this should trigger TableCalendar to navigate
      if (mounted) {
        setState(() {
          _focusedDay = targetDate;
          _selectedDay = targetDate;
        });
        
        // Force a rebuild of the calendar by calling onPageChanged
        // This ensures TableCalendar actually navigates to the new month
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _onPageChanged(targetDate);
          }
        });
      }
    }
  }



  // Helper method to safely navigate to next/previous month
  // Clamps the day to the last valid day of the target month to prevent overflow
  DateTime _navigateToMonth(DateTime currentDate, int monthOffset) {
    int targetYear = currentDate.year;
    int targetMonth = currentDate.month + monthOffset;
    
    // Handle year overflow/underflow
    if (targetMonth > 12) {
      targetMonth = 1;
      targetYear++;
    } else if (targetMonth < 1) {
      targetMonth = 12;
      targetYear--;
    }
    
    // Get the last valid day of the target month
    final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    
    // Clamp the day to be within valid range (1 to lastDayOfTargetMonth)
    final targetDay = currentDate.day > lastDayOfTargetMonth 
        ? lastDayOfTargetMonth 
        : currentDate.day;
    
    return DateTime(targetYear, targetMonth, targetDay);
  }

  // Add this method to handle calendar page changes
  void _onPageChanged(DateTime focusedDay) async {
    if (!mounted) return; // Prevent setState after dispose
    
    setState(() {
      _focusedDay = focusedDay;
    });
    
    // Preload the new month's events and wait for completion to ensure UI updates
    try {
      await EventService.preloadMonth(focusedDay);
      
      // Trigger UI refresh after events are loaded to show indicator dots
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle preload errors gracefully
    }
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
                  
                  // Skip header line and load duty codes
                  for (var i = 1; i < lines.length; i++) {
                    if (lines[i].trim().isEmpty) continue;
                    final parts = lines[i].split(',');
                    if (parts.isNotEmpty) {
                      // For regular work shifts, include ALL duties (including workouts)
                      combinedShifts.add(parts[0]);
                    }
                  }
                } catch (e) {
                  // Silently handle CSV parsing errors - file may not exist or be malformed
                }
                
                // On weekdays, also load from UNI_M-F.csv
                if (dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday') {
                  try {
                    final csv = await rootBundle.loadString('assets/UNI_M-F.csv');
                    final lines = csv.split('\n');
                    
                    // Skip header line and load duty codes
                    for (var i = 1; i < lines.length; i++) {
                      if (lines[i].trim().isEmpty) continue;
                      final parts = lines[i].split(',');
                      if (parts.isNotEmpty) {
                        // For regular work shifts, include ALL duties (including workouts)
                        combinedShifts.add(parts[0]);
                      }
                    }
                  } catch (e) {
                    // Silently handle CSV parsing errors - file may not exist or be malformed
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
                }
              }
              
              // If no selected shift number yet but shifts are available, select the first one
              if (selectedShiftNumber.isEmpty && shiftNumbers.isNotEmpty) {
                selectedShiftNumber = shiftNumbers[0];
              }
            } catch (e) {
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
                                // EA Type Training doesn't have A/B halves
                                final isEATypeTraining = shift.contains('EA Type Training');
                                return DropdownMenuItem(
                                  value: shift,
                                  child: Text((overtimeHalfType.isNotEmpty && !isEATypeTraining)
                                      ? '$shift$overtimeHalfType' // Add A/B suffix for display (not for EA Type Training)
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
                        // EA Type Training shifts don't have A/B halves
                        final isEATypeTraining = selectedShiftNumber.contains('EA Type Training');
                        final title = isEATypeTraining 
                            ? '$selectedShiftNumber (OT)'
                            : '$selectedShiftNumber$overtimeHalfType (OT)';
                        
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
                          
                          // EA Type Training uses times directly, no A/B half adjustments
                          TimeOfDay adjustedStartTime;
                          TimeOfDay adjustedEndTime;
                          
                          if (isEATypeTraining) {
                            // Use CSV times directly for EA Type Training
                            adjustedStartTime = startTime;
                            adjustedEndTime = endTime;
                          } else {
                            // Calculate actual start and end times based on overtime half type
                            final shiftDuration = (endTime.hour * 60 + endTime.minute) - 
                                                (startTime.hour * 60 + startTime.minute);
                          
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
                              // Silently handle CSV parsing errors - file may not exist or be malformed
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
                              if (!mounted) return;
                              setState(() {
                                // Trigger a rebuild with explicit re-selection of day
                                _selectedDay = null;
                              });
                              
                              // Small delay
                              await Future.delayed(const Duration(milliseconds: 100));
                              
                              // Set selected day back to event date and rebuild again
                              if (!mounted) return;
                              setState(() {
                                _selectedDay = event.startDate;
                              });
                              
                              // Show confirmation after everything is done
                              if (!mounted) return;
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

  // Helper method to build day toggle button
  Widget _buildDayToggle(BuildContext context, StateSetter setState, int dayIndex, String label, bool isSelected, Map<int, bool> selectedDays, bool isDisabled) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive sizing: smaller on very small screens
    final toggleSize = screenWidth < 350 ? 32.0 : 36.0;
    final fontSize = screenWidth < 350 ? 12.0 : 14.0;
    
    return GestureDetector(
      onTap: isDisabled ? null : () {
        setState(() {
          selectedDays[dayIndex] = !isSelected;
        });
      },
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          width: toggleSize,
          height: toggleSize,
          decoration: BoxDecoration(
            color: isDisabled
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : (isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDisabled
                  ? Theme.of(context).dividerColor.withValues(alpha: 0.5)
                  : (isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).dividerColor),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isDisabled
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                    : (isSelected 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.onSurface),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
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

// Animated cell widget for selected day with animated border
class _AnimatedSelectedDayCell extends StatefulWidget {
  final Color? backgroundColor;
  final bool isToday;
  final bool isBankHoliday;
  final Color borderColor;
  final Widget child;

  const _AnimatedSelectedDayCell({
    required this.backgroundColor,
    required this.isToday,
    required this.isBankHoliday,
    required this.borderColor,
    required this.child,
  });

  @override
  State<_AnimatedSelectedDayCell> createState() => _AnimatedSelectedDayCellState();
}

class _AnimatedSelectedDayCellState extends State<_AnimatedSelectedDayCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200), // Slower, more relaxed animation
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 2.0, // Thicker minimum
      end: 3.5,   // Thicker maximum
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Determine border color: red for bank holidays, primary color otherwise
        final borderColor = widget.isBankHoliday ? Colors.red : widget.borderColor;
        final borderWidth = _animation.value;
        
        return Container(
          margin: const EdgeInsets.all(4.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: widget.isToday
                ? Border.all(
                    color: widget.isBankHoliday ? Colors.red : Colors.blue,
                    width: 2,
                  )
                : Border.all(
                    // Show animated border - red for bank holidays, primary color otherwise
                    color: borderColor,
                    width: borderWidth,
                  ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
