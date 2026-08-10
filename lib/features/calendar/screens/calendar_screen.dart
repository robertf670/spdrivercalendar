import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/calendar/controllers/calendar_controller.dart';
import 'package:spdrivercalendar/features/calendar/utils/calendar_day_display_text.dart';
import 'package:spdrivercalendar/features/calendar/utils/calendar_day_appearance.dart';
import 'package:spdrivercalendar/features/calendar/utils/events_for_day.dart';
import 'package:spdrivercalendar/features/calendar/utils/roster_shift_lookup.dart';
import 'package:spdrivercalendar/features/calendar/services/workout_dates_loader.dart';
import 'package:spdrivercalendar/features/calendar/services/leave_balance_setup.dart';
import 'package:spdrivercalendar/features/calendar/services/work_shift_marked_in_prefs.dart';
import 'package:spdrivercalendar/features/calendar/widgets/custom_training_form.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/duty_time_lookup_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_schedule_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:spdrivercalendar/features/calendar/services/workout_highlight_service.dart';
import 'package:spdrivercalendar/services/bus_tracking_service.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/event_duty_notes_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/universal_board_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/day_notes_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/sick_day_status_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/overtime_selection_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/late_finish_selection_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/break_status_dialog.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_day_cell.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_grid.dart';
import 'package:spdrivercalendar/features/calendar/widgets/day_detail_section.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/add_event_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/add_event_type_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/work_for_others_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/remove_rest_day_swap_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/rest_day_swap_picker_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/overtime_half_type_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/overtime_duty_shift_loader.dart';
import 'package:spdrivercalendar/features/calendar/services/overtime_duty_event_persister.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/overtime_duty_details_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/work_shift_duty_loader.dart';
import 'package:spdrivercalendar/features/calendar/services/work_shift_event_persister.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/work_shift_dialog.dart';
import 'package:spdrivercalendar/features/calendar/utils/edit_event_display_title.dart';
import 'package:spdrivercalendar/features/calendar/widgets/edit_event_bus_assignment_section.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/edit_event_dialog.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_dates.dart';
import 'package:spdrivercalendar/features/calendar/utils/booked_holidays_filter.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_balance_loader.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/booked_holidays_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/add_holidays_dialog.dart';
import 'package:spdrivercalendar/features/calendar/widgets/existing_holidays_section.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/multi_date_holiday_picker_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/holiday_year_picker_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/holiday_sunday_date_picker_dialog.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/summer_holiday_duration_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_lookup_service.dart';
import 'package:spdrivercalendar/features/calendar/services/google_calendar_event_description_builder.dart';
import 'package:spdrivercalendar/features/calendar/services/google_calendar_event_sync_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_status_update_service.dart';
import 'package:spdrivercalendar/features/calendar/services/event_deletion_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_booking_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/edit_event_open_action.dart';
import 'package:spdrivercalendar/features/calendar/services/self_certified_sick_day_guard.dart';
import 'package:spdrivercalendar/features/calendar/utils/calendar_month_navigation.dart';
import 'package:spdrivercalendar/features/calendar/utils/shift_info_map_factory.dart';
import 'package:spdrivercalendar/features/calendar/utils/calendar_events_by_date.dart';
import 'package:spdrivercalendar/features/calendar/services/calendar_display_settings_loader.dart';
import 'package:spdrivercalendar/features/calendar/services/calendar_holiday_cache.dart';
import 'package:spdrivercalendar/features/calendar/navigation/calendar_feature_navigation.dart';
import 'package:spdrivercalendar/features/calendar/widgets/calendar_scaffold.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/rest_day_setup_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/work_for_others_shift_loader.dart';
import 'package:spdrivercalendar/features/calendar/utils/work_for_others_title.dart';
import 'package:spdrivercalendar/features/calendar/utils/rest_day_swap_planning.dart';
import 'package:spdrivercalendar/features/settings/screens/settings_screen.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';

import 'package:spdrivercalendar/services/rest_days_service.dart';
import 'package:spdrivercalendar/services/rest_day_swap_service.dart';
import 'package:spdrivercalendar/services/update_service.dart';
import 'package:spdrivercalendar/core/widgets/enhanced_update_dialog.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';
import '../../../models/universal_board.dart';
import '../../../services/days_in_lieu_service.dart';
import '../../../services/day_note_service.dart';
import '../../../services/bank_holiday_redundant_day_service.dart';
import '../dialogs/days_in_lieu_setup_dialog.dart';
import '../dialogs/annual_leave_setup_dialog.dart';

class CalendarScreen extends StatefulWidget {
  final ValueNotifier<bool> isDarkModeNotifier;

  const CalendarScreen(this.isDarkModeNotifier, {super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final CalendarController _calendarController;
  DateTime? get _selectedDay => _calendarController.selectedDay;
  DateTime get _focusedDay => _calendarController.focusedDay;
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
  bool _highlightWorkoutDays = false; // Default to false (OFF)
  Set<DateTime>? _workoutDates; // Cached workout dates for visible month (null = loading)
  final Map<String, Set<DateTime>> _workoutDatesMonthCache = {}; // Per-month cache when no global cache
  final Set<String> _workoutDateLoadsInProgress = {};

  // Add holiday color constant
  static const Color holidayColor = Color(0xFF00BCD4); // Teal color for holidays

  final _eventStatusUpdateService = EventStatusUpdateService();
  final _selfCertifiedSickDayGuard = SelfCertifiedSickDayGuard();
  final _eventDeletionService = EventDeletionService();
  final _holidayBookingService = HolidayBookingService();
  final _displaySettingsLoader = CalendarDisplaySettingsLoader();
  final _holidayCache = CalendarHolidayCache();
  final _workoutDatesLoader = WorkoutDatesLoader();
  final _leaveBalanceSetup = LeaveBalanceSetup();
  final _workShiftMarkedInPrefsLoader = WorkShiftMarkedInPrefsLoader();

  void _initializeShiftColors() {
    _shiftInfoMap = buildShiftInfoMap(ColorCustomizationService.getShiftColors());
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
    final today = DateTime.now();
    _calendarController = CalendarController(
      initialFocusedDay: today,
      initialSelectedDay: today,
      initiallyLoading: true,
    );
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

    // Load day notes and bank-holiday redundant (day-only) flags
    DayNoteService.loadDayNotes().then((_) {
      if (mounted) setState(() {});
    });
    BankHolidayRedundantDayService.load().then((_) {
      if (mounted) setState(() {});
    });

    // Defer non-critical startup work until after the first calendar frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleAutomaticUpdateCheck();
      _checkDaysInLieuSetup();
    });
  }

  @override
  void dispose() {
    ColorCustomizationService.clearColorChangeCallback();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _scrollController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  Future<void> _checkDaysInLieuSetup() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final status = await _leaveBalanceSetup.check();
    if (!mounted) return;

    if (status.needsDaysInLieu) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DaysInLieuSetupDialog(),
      );
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (status.needsAnnualLeave) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnnualLeaveSetupDialog(),
      );
    }
  }

  Future<void> _loadMarkedInSettings({bool refreshWorkoutDates = false}) async {
    if (!mounted) return;

    final settings = await _displaySettingsLoader.load();
    if (!mounted) return;

    final needsUpdate = _markedInEnabled != settings.markedInEnabled ||
        _markedInStatus != settings.markedInStatus ||
        _showDutyCodesOnCalendar != settings.showDutyCodesOnCalendar ||
        _animatedSelectedDay != settings.animatedSelectedDay ||
        _highlightWorkoutDays != settings.highlightWorkoutDays;

    _markedInEnabled = settings.markedInEnabled;
    _markedInStatus = settings.markedInStatus;
    _showDutyCodesOnCalendar = settings.showDutyCodesOnCalendar;
    _animatedSelectedDay = settings.animatedSelectedDay;
    _highlightWorkoutDays = settings.highlightWorkoutDays;

    if (needsUpdate) {
      setState(() {});
      if (_highlightWorkoutDays) {
        await _loadWorkoutDates();
      } else {
        _workoutDates = {};
      }
    } else if (_highlightWorkoutDays && refreshWorkoutDates) {
      await _loadWorkoutDates();
    }
  }

  Future<void> _loadWorkoutDates() async {
    if (!_highlightWorkoutDays) return;

    final cached = await _workoutDatesLoader.loadCachedDates();
    if (cached != null && mounted) {
      if (!WorkoutDatesLoader.setsEqual(_workoutDates, cached)) {
        setState(() => _workoutDates = cached);
      }
      return;
    }

    final monthKey = WorkoutDatesLoader.monthKey(_focusedDay);
    if (_workoutDatesMonthCache.containsKey(monthKey) && mounted) {
      final monthDates = _workoutDatesMonthCache[monthKey]!;
      if (!WorkoutDatesLoader.setsEqual(_workoutDates, monthDates)) {
        setState(() => _workoutDates = monthDates);
      }
      return;
    }

    if (_workoutDateLoadsInProgress.contains(monthKey)) return;
    _workoutDateLoadsInProgress.add(monthKey);
    try {
      if (_workoutDates != null && mounted) {
        setState(() => _workoutDates = null);
      }
      await _loadWorkoutDatesForMonth(_focusedDay);
    } finally {
      _workoutDateLoadsInProgress.remove(monthKey);
    }
  }

  Future<void> _loadWorkoutDatesForMonth(DateTime month) async {
    if (!_highlightWorkoutDays) return;

    final workoutSet = await _workoutDatesLoader.loadForMonth(month);
    if (!mounted) return;

    final monthKey = WorkoutDatesLoader.monthKey(month);
    _workoutDatesMonthCache[monthKey] = workoutSet;
    if (!WorkoutDatesLoader.setsEqual(_workoutDates, workoutSet)) {
      setState(() => _workoutDates = workoutSet);
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
      // Run independent data loading in parallel with error handling
      final results = await Future.wait([
        RestDaysService.initialize(),
        _holidayCache.loadBankHolidays(),
        _holidayCache.loadHolidays(),
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
    } finally {
      if (mounted) {
        _calendarController.setVisibleMonthLoading(false);
      }
    }
  }

  Future<void> _reloadHolidays() async {
    try {
      final holidays = await _holidayCache.reloadHolidays();
      if (mounted) {
        setState(() {
          _holidays = holidays;
        });
      }
    } catch (e) {
      debugPrint('Error reloading holidays: $e');
    }
  }


  Future<void> _loadSettings() async {
    await RosterScheduleService.initialize();
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

  Future<void> _showFirstRunDialog({bool allowEffectiveDate = false}) async {
    final result = await showDialog<RestDaySetupResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RestDaySetupDialog(
        initialStartWeek: _startWeek,
        allowEffectiveDate: allowEffectiveDate,
      ),
    );
    if (result == null || !mounted) return;

    if (result.effectiveDate == null) {
      _startWeek = result.startWeek;
      _startDate = RosterService.getSundayOfCurrentWeek();
      await _saveSettings();
    } else {
      await RosterScheduleService.setChange(
        effectiveDate: result.effectiveDate!,
        startWeek: result.startWeek,
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Define the missing method
  void _resetRestDays() {
    _showFirstRunDialog(allowEffectiveDate: true);
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
  
  String _getRosterShiftForDate(DateTime date) {
    return rosterShiftForDate(
      date: date,
      startDate: _startDate,
      startWeek: _startWeek,
      markedInEnabled: _markedInEnabled,
      markedInStatus: _markedInStatus,
      bankHolidayForDate: getBankHoliday,
    );
  }

  // Full shift lookup with swap overrides
  ShiftLookupResult getShiftResultForDate(DateTime date) {
    return RestDaySwapService.getShiftForDate(
      date,
      startDate: _startDate,
      startWeek: _startWeek,
      rosterGetter: _getRosterShiftForDate,
    );
  }

  // Calculate the shift for a given date (includes swap overrides)
  String getShiftForDate(DateTime date) => getShiftResultForDate(date).shift;

  bool _isRosteredRestDay(DateTime date) {
    final result = getShiftResultForDate(date);
    return isRosteredRestDay(
      shift: result.shift,
      isSwappedWork: result.isSwappedWork,
    );
  }
  
  List<Event> getEventsForDay(DateTime day) {
    return eventsForDay(
      day: day,
      persistedEvents: EventService.getEventsForDay(day),
      holidays: _holidays,
    );
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
    final selectedDay = _selectedDay ?? DateTime.now();
    final isBankHoliday = getBankHoliday(selectedDay) != null;
    final hasWorkShift =
        getEventsForDay(selectedDay).any((event) => event.isWorkShift);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AddEventTypeDialog(
        showBankHolidaySection: isBankHoliday,
        hasWorkShiftOnDay: hasWorkShift,
        isDayOnlyRedundant: BankHolidayRedundantDayService.isMarked(selectedDay),
        showWorkForOthers: getShiftForDate(selectedDay) == 'R',
        showSwapRestDay: _startDate != null,
        onToggleDayOnlyRedundant: (marked) async {
          await BankHolidayRedundantDayService.setMarked(selectedDay, marked);
          if (mounted) setState(() {});
        },
        onNormalEvent: () {
          Navigator.of(dialogContext).pop();
          _showNormalEventDialog();
        },
        onWorkShift: () {
          Navigator.of(dialogContext).pop();
          _showWorkShiftDialog();
        },
        onOvertime: () {
          Navigator.of(dialogContext).pop();
          _promptForOvertimeHalfType();
        },
        onWorkForOthers: () {
          Navigator.of(dialogContext).pop();
          _showWorkForOthersDialog();
        },
        onSwapRestDay: () {
          Navigator.of(dialogContext).pop();
          _showRestDaySwapDialog();
        },
      ),
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
    final shiftDate = _selectedDay ?? DateTime.now();
    final prefs = await _workShiftMarkedInPrefsLoader.load();
    final isMFMarkedIn = prefs.isMFMarkedIn;
    final isShiftMarkedIn = prefs.isShiftMarkedIn;
    final markedInZone = prefs.markedInZone;

    final jamestownEnabled = await JamestownFeatureService.isEnabled();
    final donnybrook1Enabled = await DonnybrookFeatureService.isEnabled();

    if (!mounted) return;

    final shiftLoader = WorkShiftDutyLoader();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => WorkShiftDialog(
        shiftDate: shiftDate,
        isMFMarkedIn: isMFMarkedIn,
        isShiftMarkedIn: isShiftMarkedIn,
        markedInZone: markedInZone,
        jamestownEnabled: jamestownEnabled,
        donnybrook1Enabled: donnybrook1Enabled,
        loadShiftNumbers: (selectedZone) => shiftLoader.loadShiftNumbers(
          selectedZone: selectedZone,
          shiftDate: shiftDate,
          donnybrook1Enabled: donnybrook1Enabled,
        ),
        dayHasBlockingEvent: (date) =>
            EventService.getEventsForDay(date).any((e) => !e.isHoliday),
        onAddShift: (selection) => _addWorkShiftFromSelection(
          dialogContext: dialogContext,
          shiftDate: shiftDate,
          selection: selection,
          isMFMarkedIn: isMFMarkedIn,
          isShiftMarkedIn: isShiftMarkedIn,
          markedInZone: markedInZone,
          jamestownEnabled: jamestownEnabled,
        ),
      ),
    );
  }

  Future<void> _addWorkShiftFromSelection({
    required BuildContext dialogContext,
    required DateTime shiftDate,
    required WorkShiftDialogSelection selection,
    required bool isMFMarkedIn,
    required bool isShiftMarkedIn,
    required String markedInZone,
    required bool jamestownEnabled,
  }) async {
    final persister = WorkShiftEventPersister(
      lookupShiftTimes: (zone, shiftNumber, date) =>
          _getShiftTimes(zone, shiftNumber, date),
      onEventCreated: (created) async {
        if (!mounted) return;
        await _checkAndSyncToGoogleCalendar(created, context);
      },
    );

    final result = await persister.persist(
      shiftDate: shiftDate,
      selection: selection,
      isMFMarkedIn: isMFMarkedIn,
      isShiftMarkedIn: isShiftMarkedIn,
      markedInZone: markedInZone,
      jamestownEnabled: jamestownEnabled,
    );

    if (result.status == WorkShiftPersistStatus.missingCustomTrainingTimes) {
      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('Please enter training times.')),
      );
      return;
    }
    if (result.status == WorkShiftPersistStatus.shiftTimesUnavailable) {
      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Error retrieving shift times. Please try again.'),
        ),
      );
      return;
    }

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (!mounted) return;
    await EventService.preloadMonth(_focusedDay);
    if (!mounted) return;
    setState(() {});
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

  void _showWorkForOthersDialog() {
    final shiftDate = _selectedDay ?? DateTime.now();

    final shiftType = getShiftForDate(shiftDate);
    if (shiftType != 'R') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Work For Others can only be added on rest days.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final shiftLoader = WorkForOthersShiftLoader();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => WorkForOthersDialog(
        shiftDate: shiftDate,
        loadShiftNumbers: (selectedZone) => shiftLoader.loadShiftNumbers(
          selectedZone: selectedZone,
          shiftDate: shiftDate,
        ),
        onAddShift: ({
          required selectedZone,
          required selectedShiftNumber,
        }) async {
          final currentShiftType = getShiftForDate(shiftDate);
          if (currentShiftType != 'R') {
            if (!dialogContext.mounted) return;
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(
                content: Text('Work For Others can only be added on rest days.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final title = buildWorkForOthersTitle(
            selectedZone: selectedZone,
            selectedShiftNumber: selectedShiftNumber,
          );

          final Map<String, dynamic>? shiftTimes;
          if (selectedZone == 'Uni/Euro') {
            shiftTimes =
                await _getShiftTimes(selectedZone, selectedShiftNumber, shiftDate);
          } else {
            shiftTimes = await _getShiftTimes(
              selectedZone.replaceAll('Zone ', ''),
              selectedShiftNumber,
              shiftDate,
            );
          }

          if (shiftTimes == null) {
            if (!dialogContext.mounted) return;
            ScaffoldMessenger.of(dialogContext).showSnackBar(
              const SnackBar(
                content: Text('Error retrieving shift times. Please try again.'),
              ),
            );
            return;
          }

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

          await EventService.addEvent(event);
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
          if (!mounted) return;

          _checkAndSyncToGoogleCalendar(event, context);
          await EventService.preloadMonth(_focusedDay);
          if (!mounted) return;
          setState(() {});
          _refreshEventCardsAfterStatusChange();
        },
      ),
    );
  }

  void _showRestDaySwapDialog() async {
    final selected = _selectedDay ?? DateTime.now();
    final shiftResult = getShiftResultForDate(selected);
    final isWorkDay = shiftResult.shift != 'R' && shiftResult.shift.isNotEmpty;
    final isRestDay = shiftResult.shift == 'R';
    final existingSwaps = RestDaySwapService.getSwaps();

    final existingSwap =
        RestDaySwapPlanning.findSwapForDate(existingSwaps, selected);
    if (existingSwap != null) {
      final remove = await showDialog<bool>(
        context: context,
        builder: (_) => RemoveRestDaySwapDialog(swap: existingSwap),
      );
      if (remove == true && mounted) {
        await RestDaySwapService.removeSwapForDate(selected);
        setState(() {});
      }
      return;
    }

    if (!isWorkDay && !isRestDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a work day or rest day to swap.')),
      );
      return;
    }

    final candidates = RestDaySwapPlanning.buildCandidates(
      selected: selected,
      isWorkDay: isWorkDay,
      existingSwaps: existingSwaps,
      rosterShiftForDate: _getRosterShiftForDate,
    );

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No suitable day to swap with in this week.')),
      );
      return;
    }

    final options = candidates.map((day) {
      final result = getShiftResultForDate(day);
      return RestDaySwapCandidateOption(
        date: day,
        label: isWorkDay ? 'Rest' : result.shift,
      );
    }).toList();

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => RestDaySwapPickerDialog(
        isWorkDay: isWorkDay,
        candidates: options,
      ),
    );

    if (picked != null && mounted) {
      final pair = RestDaySwapPlanning.resolvePair(
        selected: selected,
        picked: picked,
        isWorkDay: isWorkDay,
      );
      final shiftType = _getRosterShiftForDate(pair.workDate);
      if (shiftType == 'R' || shiftType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine shift type.')),
        );
        return;
      }
      await RestDaySwapService.addSwap(
        workDate: pair.workDate,
        restDate: pair.restDate,
        shiftType: shiftType,
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Swapped ${DateFormat('EEE').format(pair.workDate)} with ${DateFormat('EEE').format(pair.restDate)}.',
          ),
        ),
      );
    }
  }

  // Compatibility bridge while existing event flows still consume maps.
  Future<Map<String, dynamic>?> _getShiftTimes(
    String zone,
    String shiftNumber,
    DateTime shiftDate, {
    bool isOvertimeShift = false,
  }) async {
    final result = await DutyTimeLookupService.lookup(
      zone: zone,
      shiftNumber: shiftNumber,
      shiftDate: shiftDate,
      isOvertimeShift: isOvertimeShift,
    );
    return result?.toLegacyMap();
  }

  GoogleCalendarEventSyncService _googleCalendarSyncService() {
    return GoogleCalendarEventSyncService(
      buildDescription: _buildGoogleCalendarDescription,
    );
  }

  Future<void> _syncBusAssignmentsToGoogleCalendar(Event event) {
    return _googleCalendarSyncService().syncBusAssignments(event);
  }

  Future<String?> _buildGoogleCalendarDescription(Event event) {
    return GoogleCalendarEventDescriptionBuilder.build(
      event: event,
      getBreakTime: ShiftService.getBreakTime,
      isWorkingOnRestDay: (date) {
        final result = getShiftResultForDate(date);
        return result.shift == 'R' && !result.isSwappedWork;
      },
    );
  }

  Future<void> _checkAndSyncToGoogleCalendar(Event event, BuildContext? context) async {
    if (context == null || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final success = await _googleCalendarSyncService().syncNewEvent(
      event: event,
      context: context,
      isMounted: () => mounted,
    );

    if (success && mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Shift added to Google Calendar')),
      );
    }
  }

  Future<void> _editCustomTrainingEvent(Event event) async {
    if (!event.isCustomTraining || !mounted) return;

    final result = await showCustomTrainingFormDialog(
      context,
      dialogTitle: 'Edit Training Details',
      initialData: CustomTrainingFormData(
        startTime: event.startTime,
        endTime: event.endTime,
        description: event.trainingDescription,
        location: event.startLocation,
      ),
    );

    if (result == null || !mounted) return;

    final nextDay = customTrainingEndsNextDay(result.startTime, result.endTime);
    final updated = event.copyWith(
      startTime: result.startTime,
      endTime: result.endTime,
      endDate: nextDay
          ? event.startDate.add(const Duration(days: 1))
          : event.startDate,
      trainingDescription: result.description ?? '',
      startLocation: result.location,
      finishLocation: null,
    );

    await EventService.updateEvent(event, updated);
    if (mounted) setState(() {});
  }

  void _editEvent(Event event) {
    final openAction = resolveEditEventOpenAction(event);
    if (openAction == EditEventOpenAction.refreshMonth) {
      if (_selectedDay != null) {
        EventService.preloadMonth(_selectedDay!).then((_) {
          if (mounted) {
            setState(() {});
          }
        });
      } else {
        setState(() {});
      }
      return;
    }

    if (openAction == EditEventOpenAction.refreshSpareInPlace) {
      setState(() {});
      return;
    }

    final displayTitle = formatEditEventDisplayTitle(event.title);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => EditEventDialog(
        event: event,
        displayTitle: displayTitle,
        showBankHolidayRedundant:
            event.isWorkShift && getBankHoliday(event.startDate) != null,
        onViewBoard: _showBoard,
        onNotes: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showNotesDialog(event);
          });
        },
        onEditTraining: () => _editCustomTrainingEvent(event),
        onBreakFinish: () => _showBreakStatusDialog(event),
        onSickDayStatus: () => _showSickDayStatusDialog(event),
        onBankHolidayRedundantChanged: (value) async {
          final oldEvent = event.copyWith();
          event.bankHolidayRedundant = value;
          await EventService.updateEvent(oldEvent, event);
          if (mounted) {
            setState(() {});
          }
        },
        busAssignmentSection: EditEventBusAssignmentSection(
          event: event,
          isTrackingBus: (busNumber) =>
              _busTrackingLoading['tracking_$busNumber'] == true,
          onTrackBus: _trackBus,
          onBusAssignmentChanged: (oldEvent, updatedEvent) async {
            await EventService.updateEvent(oldEvent, updatedEvent);
            await _syncBusAssignmentsToGoogleCalendar(updatedEvent);
            if (!mounted) return;
            setState(() {});
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            _editEvent(updatedEvent);
          },
        ),
        onDelete: () async {
          Navigator.of(dialogContext).pop();

          final scaffoldMessenger = ScaffoldMessenger.of(context);
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
          scaffoldMessenger.showSnackBar(snackBar);

          await _eventDeletionService.deleteEvent(
            event: event,
            context: context,
            isMounted: () => mounted,
          );

          if (_selectedDay != null) {
            await EventService.preloadMonth(_selectedDay!);
          }

          if (!mounted) return;
          setState(() {});
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Event deleted'),
            ),
          );
        },
      ),
    );
  }

  void _showBoard(UniversalBoard board) {
    showDialog<void>(
      context: context,
      builder: (context) => UniversalBoardDialog(board: board),
    );
  }

  void _showNotesDialog(Event event) {
    if (!mounted) return;

    final scaffoldContext = context;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => EventDutyNotesDialog(
        event: event,
        scaffoldContext: scaffoldContext,
        onSave: (notes, imagePaths) async {
          final oldSnapshot = event.copyWith();
          event.notes = notes;
          event.noteImagePaths = imagePaths;
          await EventService.updateEvent(oldSnapshot, event);
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _showDayNotesDialog(DateTime date) {
    showDialog<void>(
      context: context,
      builder: (context) => DayNotesDialog(
        date: date,
        initialNotes: DayNoteService.getDayNote(date) ?? '',
        onSave: (notes) async {
          await DayNoteService.saveDayNote(date, notes);
          if (!mounted) return;
          setState(() {});
        },
      ),
    );
  }

  Future<void> _applyBreakStatusChange(
    BuildContext dialogContext,
    Event event, {
    required String confirmationMessage,
    required void Function(Event event) applyChanges,
  }) async {
    await _eventStatusUpdateService.applyBreakStatusChange(
      event,
      applyChanges: applyChanges,
    );

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(confirmationMessage),
        duration: const Duration(seconds: 2),
      ),
    );
    _refreshEventCardsAfterStatusChange();
  }

  void _showBreakStatusDialog(Event event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BreakStatusDialog(
        hasLateBreak: event.hasLateBreak,
        tookFullBreak: event.tookFullBreak,
        overtimeDurationMinutes: event.overtimeDuration,
        hasLateFinish: event.hasLateFinish,
        lateFinishDurationMinutes: event.lateFinishDuration,
        onRemoveBreak: () => _applyBreakStatusChange(
          dialogContext,
          event,
          confirmationMessage: 'Break status removed',
          applyChanges: EventStatusUpdateService.clearBreakStatus,
        ),
        onFullBreak: () => _applyBreakStatusChange(
          dialogContext,
          event,
          confirmationMessage: 'Full Break status saved',
          applyChanges: EventStatusUpdateService.applyFullBreak,
        ),
        onOvertime: () {
          Navigator.of(dialogContext).pop();
          _showOvertimeSelectionDialog(event);
        },
        onRemoveLateFinish: () => _applyBreakStatusChange(
          dialogContext,
          event,
          confirmationMessage: 'Late finish status removed',
          applyChanges: EventStatusUpdateService.clearLateFinish,
        ),
        onLateFinish: () {
          Navigator.of(dialogContext).pop();
          _showLateFinishSelectionDialog(event);
        },
      ),
    );
  }

  void _refreshEventCardsAfterStatusChange() {
    _editEvent(statusRefreshTriggerEvent());
  }

  Future<void> _applyOvertimeDuration(
    BuildContext dialogContext,
    Event event,
    int durationMinutes, {
    required String confirmationMessage,
  }) async {
    await _eventStatusUpdateService.applyOvertimeDuration(
      event,
      durationMinutes,
    );

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(confirmationMessage),
        duration: const Duration(seconds: 2),
      ),
    );
    _refreshEventCardsAfterStatusChange();
  }

  Future<void> _applyLateFinishDuration(
    BuildContext dialogContext,
    Event event,
    int durationMinutes,
  ) async {
    await _eventStatusUpdateService.applyLateFinishDuration(
      event,
      durationMinutes,
    );

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Late finish ($durationMinutes mins) saved'),
        duration: const Duration(seconds: 2),
      ),
    );
    _refreshEventCardsAfterStatusChange();
  }

  void _showOvertimeSelectionDialog(Event event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => OvertimeSelectionDialog(
        initialDurationMinutes: event.overtimeDuration ?? 60,
        onSaveOneHour: () => _applyOvertimeDuration(
          dialogContext,
          event,
          60,
          confirmationMessage: 'Overtime (1 hour) saved',
        ),
        onSave: (durationMinutes) => _applyOvertimeDuration(
          dialogContext,
          event,
          durationMinutes,
          confirmationMessage: 'Overtime ($durationMinutes mins) saved',
        ),
      ),
    );
  }

  void _showLateFinishSelectionDialog(Event event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => LateFinishSelectionDialog(
        initialDurationMinutes: event.lateFinishDuration,
        onInvalidDuration: () {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid number of minutes'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        },
        onSave: (durationMinutes) => _applyLateFinishDuration(
          dialogContext,
          event,
          durationMinutes,
        ),
      ),
    );
  }

  Future<void> _applySickDayType(
    BuildContext dialogContext,
    Event event,
    String? sickDayType, {
    required String confirmationMessage,
    Duration snackBarDuration = const Duration(seconds: 2),
  }) async {
    await _eventStatusUpdateService.applySickDayType(event, sickDayType);

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(confirmationMessage),
        duration: snackBarDuration,
      ),
    );
  }

  Future<void> _handleSelfCertifiedSickDaySelection(
    BuildContext dialogContext,
    Event event,
  ) async {
    final check = await _selfCertifiedSickDayGuard.evaluate(
      date: event.startDate,
      currentSickDayType: event.sickDayType,
    );

    if (check.decision == SelfCertifiedSickDayDecision.alreadySelected) {
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      return;
    }

    if (check.decision == SelfCertifiedSickDayDecision.limitReached) {
      if (!dialogContext.mounted) return;
      await showDialog<void>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text('Self-Certified Limit Reached'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(check.warningMessage ?? ''),
              const SizedBox(height: 16),
              const Text(
                'Current usage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('${check.halfYearName}: ${check.halfYearCount}/2'),
              Text('Year total: ${check.yearlyCount}/4'),
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
      return;
    }

    await _eventStatusUpdateService.applySickDayType(event, 'self-certified');

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    if (!mounted) return;

    setState(() {});
    final remaining = await _selfCertifiedSickDayGuard.remainingAfterSave(
      date: event.startDate,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Self-Certified Sick Day saved. Remaining: ${remaining.remainingHalfYear} in ${remaining.halfYearName}, ${remaining.remainingYearly} for year.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSickDayStatusDialog(Event event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SickDayStatusDialog(
        currentSickDayType: event.sickDayType,
        onClear: () => _applySickDayType(
          dialogContext,
          event,
          null,
          confirmationMessage: 'Sick day status cleared',
        ),
        onSelectNormal: () => _applySickDayType(
          dialogContext,
          event,
          'normal',
          confirmationMessage: 'Normal Sick Day saved',
        ),
        onSelectSelfCertified: () =>
            _handleSelfCertifiedSickDaySelection(dialogContext, event),
        onSelectForceMajeure: () => _applySickDayType(
          dialogContext,
          event,
          'force-majeure',
          confirmationMessage: 'Force Majeure saved',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CalendarController>.value(
      value: _calendarController,
      child: Builder(builder: _buildCalendarScaffold),
    );
  }

  Widget _buildCalendarScaffold(BuildContext context) {
    return CalendarScaffold(
      scrollController: _scrollController,
      onSearch: _showSearchScreen,
      onWeekView: _showWeekView,
      onMenuSelected: _onCalendarMenuSelected,
      calendar: Selector<CalendarController, (DateTime?, DateTime, bool)>(
        selector: (_, controller) => (
          controller.selectedDay,
          controller.focusedDay,
          controller.isVisibleMonthLoading,
        ),
        builder: (_, __, ___) => _buildCalendar(),
      ),
      dayDetailBuilder: _buildDayDetailSection,
    );
  }

  void _onCalendarMenuSelected(String value) {
    switch (value) {
      case CalendarMenuAction.statistics:
        _showStatisticsPage();
      case CalendarMenuAction.bills:
        _showBillsPage();
      case CalendarMenuAction.timingPoints:
        _showTimingPointsPage();
      case CalendarMenuAction.toiletCodes:
        _showToiletCodesPage();
      case CalendarMenuAction.settings:
        _showSettingsPage();
      case CalendarMenuAction.addHolidays:
        _showAddHolidaysDialog();
      case CalendarMenuAction.contacts:
        _showContactsPage();
      case CalendarMenuAction.notes:
        _navigateToAllNotesScreen();
      case CalendarMenuAction.liveUpdates:
        _showLiveUpdatesPage();
      case CalendarMenuAction.payscale:
        _showPayscalePage();
    }
  }

  Widget _buildCalendar() {
    return CalendarGrid(
      tableKey: ValueKey(
        'calendar_${_markedInEnabled}_$_markedInStatus}_${_focusedDay.year}_${_focusedDay.month}',
      ),
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      onPreviousMonth: () {
        _calendarController.setFocusedDay(
          navigateCalendarMonth(_focusedDay, -1),
        );
      },
      onNextMonth: () {
        _calendarController.setFocusedDay(
          navigateCalendarMonth(_focusedDay, 1),
        );
      },
      onShowYear: () => _showYearView(_focusedDay.year),
      onDaySelected: (selectedDay, focusedDay) async {
        if (_selectedDay != null && selectedDay != _selectedDay) {
          try {
            await EventService.preloadMonth(selectedDay);
            final selectedDayEvents = EventService.getEventsForDay(selectedDay);
            for (final event in selectedDayEvents) {
              if (event.title.startsWith('SP') &&
                  event.assignedDuties != null &&
                  event.assignedDuties!.isNotEmpty) {
                // Spare duty validation is intentionally retained.
              }
            }
          } catch (_) {
            // Preserve graceful navigation when preloading fails.
          }
        }

        if (mounted) {
          _calendarController.selectDay(
            selectedDay,
            focusedDay: focusedDay,
          );
        }
      },
      onPageChanged: _onPageChanged,
      eventLoader: (day) => getEventsForDay(day),
      dayBuilder: (
        date, {
        required isToday,
        required isOutsideDay,
        isSelected = false,
      }) {
        return _buildCalendarDay(
          date,
          isToday: isToday,
          isOutsideDay: isOutsideDay,
          isSelected: isSelected,
        );
      },
    );
  }

  Widget _buildCalendarDay(DateTime date, {required bool isToday, required bool isOutsideDay, bool isSelected = false}) {
    final shift = _startDate != null ? getShiftForDate(date) : '';
    final events = getEventsForDay(date);
    final bankHoliday = getBankHoliday(date);
    final isBankHoliday = bankHoliday != null;

    final displayText = calendarDayDisplayText(
      events: events,
      rosterShift: shift,
      showDutyCodesOnCalendar: _showDutyCodesOnCalendar,
      isSwappedRestDay: RestDaySwapService.isSwappedRestDay(date),
      isSwappedWorkDay: RestDaySwapService.isSwappedWorkDay(date),
    );

    final appearance = resolveCalendarDayAppearance(
      date: date,
      events: events,
      rosterShift: shift,
      shiftInfoMap: _shiftInfoMap,
      holidays: _holidays,
      highlightWorkoutDays: _highlightWorkoutDays,
      workoutDates: _workoutDates,
      hasDayNote: DayNoteService.hasNoteForDate(date),
      isBankHoliday: isBankHoliday,
      isBankHolidayRedundantMarked:
          BankHolidayRedundantDayService.isMarked(date),
      dayInLieuColor: ColorCustomizationService.getColorForShift('DAY_IN_LIEU'),
      workoutColor: ColorCustomizationService.getColorForShift('WORKOUT'),
      sickDayColor: ColorCustomizationService.getColorForSickType,
      themePrimaryColor: Theme.of(context).primaryColor,
      schemePrimaryColor: Theme.of(context).colorScheme.primary,
      holidayColor: holidayColor,
    );

    return CalendarDayCell(
      date: date,
      displayText: displayText,
      shift: shift,
      backgroundColor: appearance.backgroundColor,
      cellColor: appearance.cellColor,
      selectedBorderColor: appearance.selectedBorderColor,
      isDayInLieu: appearance.isDayInLieu,
      isHoliday: appearance.isHoliday,
      hasEvents: appearance.hasEvents,
      isSaturdayService: RosterService.isSaturdayService(date),
      hasNotes: appearance.hasNotes,
      hasBankHolidayRedundant: appearance.hasBankHolidayRedundant,
      isToday: isToday,
      isBankHoliday: appearance.isBankHoliday,
      isOutsideDay: isOutsideDay,
      isSelected: isSelected,
      animatedSelection: _animatedSelectedDay,
    );
  }

  Widget _buildDayDetailSection(DateTime selectedDate) {
    final events = getEventsForDay(selectedDate);
    final bankHoliday = getBankHoliday(selectedDate);
    final showRedundant = bankHoliday != null &&
        (BankHolidayRedundantDayService.isMarked(selectedDate) ||
            events.any(
              (event) => event.isWorkShift && event.bankHolidayRedundant,
            ));
    final eventItems = events.map((event) {
      final eventDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final isWorkoutDay = _workoutDates != null &&
          _workoutDates!.contains(eventDate);
      return DayDetailEventItem(
        event: event,
        shiftType:
            event.isWorkForOthers ? 'WFO' : getShiftForDate(event.startDate),
        isBankHoliday: getBankHoliday(event.startDate) != null,
        isRestDay: _isRosteredRestDay(event.startDate),
        isWorkoutDay: isWorkoutDay,
      );
    }).toList(growable: false);

    return DayDetailSection(
      selectedDate: selectedDate,
      shiftInfoMap: _shiftInfoMap,
      events: eventItems,
      onAddEvent: _showAddEventDialog,
      onEditEvent: _editEvent,
      onShowEventNotes: _showNotesDialog,
      onBusAssignmentUpdate: _syncBusAssignmentsToGoogleCalendar,
      highlightWorkoutDays: _highlightWorkoutDays,
      showShiftSummary: _startDate != null,
      shift: getShiftForDate(selectedDate),
      bankHoliday: bankHoliday,
      hasDayNote: DayNoteService.hasNoteForDate(selectedDate),
      showBankHolidayRedundant: showRedundant,
      onShowDayNotes: () => _showDayNotesDialog(selectedDate),
    );
  }

  void _showStatisticsPage() {
    final allEvents = mapEventsByDate(EventService.allLoadedEvents);
    CalendarFeatureNavigation.openStatistics(context, events: allEvents);
  }
  
  void _showSettingsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          resetRestDaysCallback: _resetRestDays,
          isDarkModeNotifier: widget.isDarkModeNotifier,
          onCalendarDataChanged: _refreshCalendarAfterDataChange,
        ),
      ),
    ).then((result) {
      // Reload marked in settings when returning from settings page
      _loadMarkedInSettings(refreshWorkoutDates: true);
      // If Settings cleared future events, refresh calendar and show feedback
      if (result is int && result >= 0) {
        _refreshCalendarAfterDataChange();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed $result future event(s).')),
          );
        }
      }
    });
  }

  void _refreshCalendarAfterDataChange() {
    if (!mounted) return;
    // Defer to next frame so refresh runs after Settings UI settles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      EventService.refreshMonthCache(_focusedDay).then((_) {
        if (!mounted) return;
        setState(() {});
      });
    });
  }

  // Responsive sizing helper for holidays section
  Future<Map<String, int>> _getHolidayBalances() {
    return HolidayBalanceLoader().loadBalances();
  }

  void _showBookedHolidaysDialog(BuildContext context, String holidayType) async {
    final holidays = await HolidayService.getHolidays();
    final bookedHolidays = filterBookedHolidays(
      holidays: holidays,
      holidayType: holidayType,
    );

    if (!context.mounted) return;

    if (bookedHolidays.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (context) => EmptyBookedHolidaysDialog(holidayType: holidayType),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => BookedHolidaysDialog(
        holidayType: holidayType,
        initialHolidays: bookedHolidays,
        onDeleteHoliday: (holiday) async {
          await HolidayService.removeHoliday(holiday.id);
          final updatedHolidays = await HolidayService.getHolidays();
          await _reloadHolidays();
          _updateAllEvents();
          return filterBookedHolidaysAfterDelete(
            holidays: updatedHolidays,
            holidayType: holidayType,
          );
        },
      ),
    );
  }

  void _showAddHolidaysDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AddHolidaysDialog(
        loadBalances: _getHolidayBalances,
        hasExistingHolidays: _holidays.isNotEmpty,
        existingHolidaysSection: ExistingHolidaysSection(
          holidays: _holidays,
          holidayColor: holidayColor,
          onDeleteHoliday: (holiday) async {
            await HolidayService.removeHoliday(holiday.id);
            setState(() {
              _holidays.removeWhere((h) => h.id == holiday.id);
            });
            _updateAllEvents();
          },
          onAfterDelete: _showAddHolidaysDialog,
        ),
        onShowBookedAnnualLeave: () =>
            _showBookedHolidaysDialog(dialogContext, 'annualLeave'),
        onShowBookedDaysInLieu: () =>
            _showBookedHolidaysDialog(dialogContext, 'daysInLieu'),
        onSummerHoliday: _showSummerHolidayDateDialog,
        onWinterHoliday: _showWinterHolidayDateDialog,
        onOtherHoliday: _showOtherHolidayDialog,
        onUnpaidLeave: _showUnpaidLeaveDialog,
        onDayInLieu: _showDayInLieuDialog,
      ),
    );
  }

  void _showWinterHolidayDateDialog() {
    final currentYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (context) => HolidayYearPickerDialog(
        title: 'Select Year for Winter Holiday',
        infoText: 'Select a year to choose your winter holiday start date',
        icon: Icons.ac_unit,
        accent: Colors.blue,
        startYear: currentYear,
        loadHolidayCounts: () => HolidayLookupService.getHolidayCountsForYears(currentYear, 'winter'),
        onYearSelected: _showWinterHolidayDateDialogForYear,
      ),
    );
  }

  void _showWinterHolidayDateDialogForYear(int year) {
    final sundays = getSundaysForYear(year);

    showDialog<bool>(
      context: context,
      builder: (context) => HolidaySundayDatePickerDialog(
        title: 'Select Winter Holiday Start Date',
        subtitle: 'Year: $year',
        icon: Icons.ac_unit,
        accent: Colors.blue,
        sundays: sundays,
        loadHasHolidayFlags: () => Future.wait(
          sundays.map((date) => HolidayLookupService.hasHolidayForDate(date, 'winter')),
        ),
        onBack: _showWinterHolidayDateDialog,
        onConfirm: (date) async {
          await _holidayBookingService.addWinterHoliday(date);
          await _reloadHolidays();
        },
      ),
    ).then((added) {
      if (!mounted || added != true) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Winter holiday for $year added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showSummerHolidayDateDialog() {
    showDialog(
      context: context,
      builder: (context) => SummerHolidayDurationDialog(
        onDurationSelected: (durationWeeks) {
          _showSummerHolidayYearDialog(durationWeeks: durationWeeks);
        },
      ),
    );
  }

  void _showSummerHolidayYearDialog({required int durationWeeks}) {
    final currentYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (context) => HolidayYearPickerDialog(
        title: 'Select Year for Summer Holiday',
        infoText: 'Select a year to choose your summer holiday start date',
        icon: Icons.wb_sunny,
        accent: Colors.orange,
        startYear: currentYear,
        loadHolidayCounts: () => HolidayLookupService.getHolidayCountsForYears(currentYear, 'summer'),
        onYearSelected: (year) {
          _showSummerHolidayDateDialogForYear(
            year,
            durationWeeks: durationWeeks,
          );
        },
      ),
    );
  }

  void _showSummerHolidayDateDialogForYear(int year, {required int durationWeeks}) {
    final sundays = getSundaysForYear(year);

    showDialog<bool>(
      context: context,
      builder: (context) => HolidaySundayDatePickerDialog(
        title: 'Select Summer Holiday Start Date',
        subtitle: 'Year: $year • ${durationWeeks == 1 ? '1 Week' : '2 Weeks'}',
        icon: Icons.wb_sunny,
        accent: Colors.orange,
        sundays: sundays,
        loadHasHolidayFlags: () => Future.wait(
          sundays.map((date) => HolidayLookupService.hasHolidayForDate(date, 'summer')),
        ),
        onBack: _showSummerHolidayDateDialog,
        // Preserve prior UI quirk: end preview always shows +13 days.
        endPreviewFor: (date) => date.add(const Duration(days: 13)),
        onConfirm: (date) async {
          await _holidayBookingService.addSummerHoliday(
            startSunday: date,
            durationWeeks: durationWeeks,
          );
          await _reloadHolidays();
        },
      ),
    ).then((added) {
      if (!mounted || added != true) return;
      final durationText = durationWeeks == 1 ? '1 week' : '2 weeks';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Summer holiday ($durationText) for $year added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  // Add this new function to update all events
  Future<void> _updateAllEvents() async {
    // Instead of loading all events at once, we'll just preload the current month
    await EventService.preloadMonth(_focusedDay);
    setState(() {});
  }




  void _showOtherHolidayDialog() {
    showDialog<int>(
      context: context,
      builder: (context) => MultiDateHolidayPickerDialog<int>(
        title: 'Select Holiday Dates',
        icon: Icons.event,
        accent: MultiDateHolidayPickerAccent.materialGreen(),
        confirmLabelSingular: 'Add Holiday',
        confirmLabelPlural: 'Add Holidays',
        onConfirm: (sortedDates) async {
          final successCount = await _holidayBookingService.addSingleDayHolidays(
            sortedDates: sortedDates,
            type: 'other',
            idPrefix: 'other',
          );
          await _reloadHolidays();
          return successCount;
        },
      ),
    ).then((successCount) {
      if (!mounted || successCount == null) return;
      final message = successCount == 1
          ? 'Holiday added successfully'
          : '$successCount holidays added successfully';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showUnpaidLeaveDialog() {
    showDialog<int>(
      context: context,
      builder: (context) => MultiDateHolidayPickerDialog<int>(
        title: 'Select Unpaid Leave Dates',
        icon: Icons.money_off,
        accent: MultiDateHolidayPickerAccent.materialPurple(),
        confirmLabelSingular: 'Add Unpaid Leave',
        confirmLabelPlural: 'Add Unpaid Leave Days',
        onConfirm: (sortedDates) async {
          final successCount = await _holidayBookingService.addSingleDayHolidays(
            sortedDates: sortedDates,
            type: 'unpaid_leave',
            idPrefix: 'unpaid_leave',
          );
          await _reloadHolidays();
          return successCount;
        },
      ),
    ).then((successCount) {
      if (!mounted || successCount == null) return;
      setState(() {});
      final message = successCount == 1
          ? 'Unpaid leave added successfully'
          : '$successCount unpaid leave days added successfully';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.purple,
        ),
      );
    });
  }

  Future<void> _showDayInLieuDialog() async {
    final dayInLieuColor =
        ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
    final used = await DaysInLieuService.getUsedDays();
    final remaining = await DaysInLieuService.getRemainingDays();

    if (!mounted) return;
    final successCount = await showDialog<int>(
      context: context,
      builder: (context) => MultiDateHolidayPickerDialog<int>(
        title: 'Select Day In Lieu Dates',
        icon: Icons.event_available,
        accent: MultiDateHolidayPickerAccent.solid(dayInLieuColor),
        confirmLabelSingular: 'Add Day In Lieu',
        confirmLabelPlural: 'Add Days In Lieu',
        topContent: DayInLieuBalanceHeader(
          used: used,
          remaining: remaining,
        ),
        onConfirm: (sortedDates) async {
          final successCount = await _holidayBookingService.addSingleDayHolidays(
            sortedDates: sortedDates,
            type: 'day_in_lieu',
            idPrefix: 'day_in_lieu',
            notifyDayInLieu: true,
          );
          await _reloadHolidays();
          return successCount;
        },
      ),
    );

    if (!mounted || successCount == null) return;
    setState(() {});
    final message = successCount == 1
        ? 'Day In Lieu added successfully'
        : '$successCount days in lieu added successfully';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: dayInLieuColor,
      ),
    );
  }

  void _showContactsPage() {
    CalendarFeatureNavigation.openContacts(context);
  }

  void _navigateToAllNotesScreen() {
    CalendarFeatureNavigation.openNotes(context);
  }

  void _showBillsPage() {
    CalendarFeatureNavigation.openBills(context);
  }

  void _showPayscalePage() {
    CalendarFeatureNavigation.openPayscale(context);
  }

  void _showTimingPointsPage() {
    CalendarFeatureNavigation.openTimingPoints(context);
  }

  void _showToiletCodesPage() {
    CalendarFeatureNavigation.openToiletCodes(context);
  }

  void _showLiveUpdatesPage() {
    CalendarFeatureNavigation.openLiveUpdates(context);
  }

  void _showSearchScreen() async {
    final selectedDate = await CalendarFeatureNavigation.openSearch(context);
    if (selectedDate != null && mounted) {
      _calendarController.selectDay(
        selectedDate,
        focusedDay: selectedDate,
      );
    }
  }

  void _showWeekView() {
    CalendarFeatureNavigation.openWeekView(
      context,
      selectedDate: _selectedDay ?? DateTime.now(),
      shiftInfoMap: _shiftInfoMap,
      startDate: _startDate,
      startWeek: _startWeek,
      bankHolidays: _bankHolidays,
    );
  }

  void _showYearView(int year) async {
    final selectedMonth = await CalendarFeatureNavigation.openYearView(
      context,
      year: year,
      shiftInfoMap: _shiftInfoMap,
      startDate: _startDate,
      startWeek: _startWeek,
      holidays: _holidays,
      bankHolidays: _bankHolidays,
      markedInEnabled: _markedInEnabled,
      markedInStatus: _markedInStatus,
    );

    if (selectedMonth != null && mounted) {
      final targetDate = firstDayOfMonth(selectedMonth);
      try {
        await EventService.preloadMonth(targetDate);
      } catch (_) {
        // Handle preload errors gracefully
      }

      if (mounted) {
        _calendarController.selectDay(
          targetDate,
          focusedDay: targetDate,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _onPageChanged(targetDate);
          }
        });
      }
    }
  }



  // Add this method to handle calendar page changes
  void _onPageChanged(DateTime focusedDay) async {
    if (!mounted) return; // Prevent setState after dispose

    _calendarController.beginVisibleMonthLoad(focusedDay);

    // Preload the new month's events and wait for completion to ensure UI updates
    try {
      await EventService.preloadMonth(focusedDay);

      // Load workout dates for highlight if enabled (uses cache if available)
      if (_highlightWorkoutDays) {
        await _loadWorkoutDates();
      } else if (mounted) {
        _workoutDates = {};
      }

    } catch (e) {
      // Handle preload errors gracefully
    } finally {
      if (mounted) {
        _calendarController.setVisibleMonthLoading(false);
      }
    }
  }

  // Method to prompt user for overtime half type (A or B)
  void _promptForOvertimeHalfType() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => OvertimeHalfTypeDialog(
        onFirstHalf: () {
          Navigator.of(dialogContext).pop();
          _showOvertimeDutyDetailsDialogInternal('A');
        },
        onSecondHalf: () {
          Navigator.of(dialogContext).pop();
          _showOvertimeDutyDetailsDialogInternal('B');
        },
      ),
    );
  }

  // Method to show overtime duty selection dialog with filtered duties by half type
  void _showOvertimeDutyDetailsDialogInternal(String overtimeHalfType) {
    final shiftDate = _selectedDay ?? DateTime.now();
    final shiftLoader = OvertimeDutyShiftLoader();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => OvertimeDutyDetailsDialog(
        shiftDate: shiftDate,
        overtimeHalfType: overtimeHalfType,
        loadShiftNumbers: (selectedZone) => shiftLoader.loadShiftNumbers(
          selectedZone: selectedZone,
          shiftDate: shiftDate,
        ),
        onAddShift: ({
          required selectedZone,
          required selectedShiftNumber,
        }) async {
          await _addOvertimeDutyFromSelection(
            dialogContext: dialogContext,
            overtimeHalfType: overtimeHalfType,
            shiftDate: shiftDate,
            selectedZone: selectedZone,
            selectedShiftNumber: selectedShiftNumber,
          );
        },
      ),
    );
  }

  Future<void> _addOvertimeDutyFromSelection({
    required BuildContext dialogContext,
    required String overtimeHalfType,
    required DateTime shiftDate,
    required String selectedZone,
    required String selectedShiftNumber,
  }) async {
    final persister = OvertimeDutyEventPersister(
      lookupShiftTimes: (
        zone,
        shiftNumber,
        date, {
        bool isOvertimeShift = false,
      }) =>
          _getShiftTimes(
            zone,
            shiftNumber,
            date,
            isOvertimeShift: isOvertimeShift,
          ),
    );

    final result = await persister.persist(
      overtimeHalfType: overtimeHalfType,
      shiftDate: shiftDate,
      selectedZone: selectedZone,
      selectedShiftNumber: selectedShiftNumber,
    );

    final title = result.title ?? selectedShiftNumber;

    if (result.status == OvertimeDutyPersistStatus.shiftTimesUnavailable) {
      return;
    }

    if (result.status == OvertimeDutyPersistStatus.error) {
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding overtime: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adding overtime duty...'),
        duration: Duration(seconds: 1),
      ),
    );

    await EventService.preloadMonth(_focusedDay);

    if (!mounted) return;
    _calendarController.selectDay(null);

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;
    final event = result.event!;
    _calendarController.selectDay(event.startDate);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Overtime duty $title added'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

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

}
