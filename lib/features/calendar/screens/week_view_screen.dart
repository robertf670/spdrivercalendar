import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';

class WeekViewScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, ShiftInfo> shiftInfoMap;
  final DateTime? startDate;
  final int startWeek;
  final List<BankHoliday>? bankHolidays;

  const WeekViewScreen({
    super.key,
    required this.selectedDate,
    required this.shiftInfoMap,
    this.startDate,
    this.startWeek = 0,
    this.bankHolidays,
  });

  @override
  WeekViewScreenState createState() => WeekViewScreenState();
}

class WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _currentWeekStart;
  late List<DateTime> _weekDays;
  bool _markedInEnabled = false;
  String _markedInStatus = 'Shift';

  @override
  void initState() {
    super.initState();
    _calculateWeekStart();
    _generateWeekDays();
    _loadMarkedInSettings();
  }

  Future<void> _loadMarkedInSettings() async {
    final markedInEnabled = await StorageService.getBool(AppConstants.markedInEnabledKey);
    final markedInStatus = await StorageService.getString(AppConstants.markedInStatusKey) ?? '';
    if (mounted) {
      setState(() {
        _markedInEnabled = markedInEnabled && markedInStatus.isNotEmpty;
        _markedInStatus = markedInStatus.isEmpty ? 'Spare' : markedInStatus;
      });
    }
  }

  void _calculateWeekStart() {
    final weekday = widget.selectedDate.weekday;
    // Sunday-first: Sunday = 0 days back, Monday = 1 day back, etc.
    final daysFromSunday = weekday % 7; // Sunday (7) becomes 0, Monday (1) becomes 1, etc.
    _currentWeekStart = widget.selectedDate.subtract(Duration(days: daysFromSunday));
  }

  void _generateWeekDays() {
    _weekDays = List.generate(7, (index) => _currentWeekStart.add(Duration(days: index)));
  }

  void _navigateWeek(int direction) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7 * direction));
      _generateWeekDays();
    });
  }


  List<Event> _getEventsForDate(DateTime date) {
    return EventService.getEventsForDay(date);
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && 
           date.month == today.month && 
           date.day == today.day;
  }

  BankHoliday? _getBankHoliday(DateTime date) {
    if (widget.bankHolidays == null) return null;
    try {
      return widget.bankHolidays!.firstWhere(
        (bh) => bh.date.year == date.year && 
                bh.date.month == date.month && 
                bh.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  String _getShiftForDate(DateTime date) {
    if (widget.startDate == null) return '';
    
    // Check if marked in is enabled
    if (_markedInEnabled) {
      // M-F marked in logic: W on Mon-Fri, R on Sat-Sun
      // Bank holidays are REST days for M-F
      if (_markedInStatus == 'M-F') {
        // Check if this is a bank holiday
        final bankHoliday = _getBankHoliday(date);
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
      if (_markedInStatus == 'Shift') {
        return RosterService.getShiftForDate(date, widget.startDate!, widget.startWeek);
      }
    }
    
    // Default or normal roster calculation
    return RosterService.getShiftForDate(date, widget.startDate!, widget.startWeek);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Week View'),
            if (_markedInEnabled && _markedInStatus == 'M-F') ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'M-F',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Current Week',
            onPressed: () {
              setState(() {
                final today = DateTime.now();
                final weekday = today.weekday;
                final daysFromSunday = weekday % 7;
                _currentWeekStart = today.subtract(Duration(days: daysFromSunday));
                _generateWeekDays();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Week navigation header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _navigateWeek(-1),
                  ),
                  Flexible(
                    child: Text(
                      '${DateFormat('MMM d').format(_weekDays.first)} - ${DateFormat('MMM d, yyyy').format(_weekDays.last)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _navigateWeek(1),
                  ),
                ],
              ),
            ),
            
            // Week view content - Stacked layout (1-3-3) using Expanded to fill space
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sizes = _getResponsiveSizes(context);
                  final cardSpacing = sizes['cardSpacing']!;
                  final verticalSpacing = sizes['verticalSpacing']!;
                  final horizontalPadding = sizes['horizontalPadding']!;
                  
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalSpacing * 0.5,
                    ),
                    child: Column(
                      children: [
                        // Row 1: Sunday only (centered)
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: SizedBox()), // Left spacer
                              Expanded(
                                flex: 2,
                                child: _buildDayCard(_weekDays[0]), // Sunday
                              ),
                              Expanded(child: SizedBox()), // Right spacer
                            ],
                          ),
                        ),
                        
                        SizedBox(height: verticalSpacing),
                        
                        // Row 2: Monday, Tuesday, Wednesday
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildDayCard(_weekDays[1])), // Monday
                              SizedBox(width: cardSpacing),
                              Expanded(child: _buildDayCard(_weekDays[2])), // Tuesday
                              SizedBox(width: cardSpacing),
                              Expanded(child: _buildDayCard(_weekDays[3])), // Wednesday
                            ],
                          ),
                        ),
                        
                        SizedBox(height: verticalSpacing),
                        
                        // Row 3: Thursday, Friday, Saturday
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: _buildDayCard(_weekDays[4])), // Thursday
                              SizedBox(width: cardSpacing),
                              Expanded(child: _buildDayCard(_weekDays[5])), // Friday
                              SizedBox(width: cardSpacing),
                              Expanded(child: _buildDayCard(_weekDays[6])), // Saturday
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(DateTime day) {
    final sizes = _getResponsiveSizes(context);
    final events = _getEventsForDate(day);
    final workEvents = events.where((event) => event.isWorkShift).toList();
    
    // Get the actual roster shift type for this date (respecting M-F)
    final rosterShiftType = _getShiftForDate(day);
    final isRosteredRestDay = rosterShiftType == 'R';
    
    // Get rest day color for visual distinction
    final restDayColor = widget.shiftInfoMap['R']?.color;
    
    return Container(
      decoration: BoxDecoration(
        // Use tinted background for rest days to make them stand out
        color: isRosteredRestDay && restDayColor != null
            ? restDayColor.withValues(alpha: 0.15)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isToday(day) 
            ? AppTheme.primaryColor 
            : isRosteredRestDay && restDayColor != null
              ? restDayColor.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: _isToday(day) ? 4 : isRosteredRestDay ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day header - compact
          Container(
            padding: EdgeInsets.symmetric(
              vertical: sizes['dutyCardPadding']!,
              horizontal: sizes['dutyCardPadding']! * 0.5,
            ),
            decoration: BoxDecoration(
              color: _isToday(day) 
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : isRosteredRestDay && restDayColor != null
                  ? restDayColor.withValues(alpha: 0.25)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat('EEEE').format(day),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: sizes['dayName']!,
                          color: _isToday(day) ? AppTheme.primaryColor : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (RosterService.isSaturdayService(day)) ...[
                      SizedBox(width: sizes['dayName']! * 0.2),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: sizes['dayName']! * 0.3,
                          vertical: sizes['dayName']! * 0.1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(sizes['dayName']! * 0.3),
                        ),
                        child: Text(
                          'SAT',
                          style: TextStyle(
                            fontSize: sizes['dayName']! * 0.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  DateFormat('MMM d').format(day),
                  style: TextStyle(
                    fontSize: sizes['date']!,
                    color: _isToday(day) 
                      ? AppTheme.primaryColor 
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Day content - no scrolling, fits all content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: sizes['dutyCardPadding']!,
                bottom: sizes['dutyCardPadding']!,
                left: sizes['blueBoxMargin']!,
                right: sizes['blueBoxMargin']!,
              ),
              child: workEvents.isNotEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Work events - distribute space evenly
                        ...workEvents.take(3).map((event) => Expanded(
                          flex: 1,
                          child: _buildDayDutyItem(event),
                        )),
                        if (workEvents.length > 3)
                          Padding(
                            padding: EdgeInsets.only(top: sizes['dutyCardMargin']!),
                            child: Text(
                              '+${workEvents.length - 3} more',
                              style: TextStyle(
                                fontSize: sizes['moreText']!,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Show different message based on whether it's a rostered rest day or work day without duties
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: sizes['dutyCardMargin']!,
                                bottom: sizes['dutyCardMargin']!,
                                left: sizes['blueBoxMargin']!,
                                right: sizes['blueBoxMargin']!,
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: sizes['dutyCardPadding']!,
                                  horizontal: sizes['dutyCardPadding']! * 0.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isRosteredRestDay && restDayColor != null
                                      ? restDayColor.withValues(alpha: 0.2)
                                      : Theme.of(context).colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isRosteredRestDay && restDayColor != null
                                      ? Border.all(color: restDayColor.withValues(alpha: 0.4), width: 1.5)
                                      : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isRosteredRestDay ? Icons.free_breakfast : Icons.info_outline,
                                      size: sizes['moreText']! * 3,
                                      color: isRosteredRestDay && restDayColor != null
                                          ? restDayColor
                                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                    ),
                                    SizedBox(height: sizes['dutyCardMargin']!),
                                    Text(
                                      isRosteredRestDay ? 'Rest Day' : 'No duties loaded',
                                      style: TextStyle(
                                        fontSize: sizes['moreText']!,
                                        fontWeight: isRosteredRestDay ? FontWeight.w600 : FontWeight.normal,
                                        color: isRosteredRestDay && restDayColor != null
                                            ? restDayColor
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        fontStyle: isRosteredRestDay ? FontStyle.normal : FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDutyItem(Event event) {
    final hasBreaks = event.breakStartTime != null && event.breakEndTime != null;
    final sizes = _getResponsiveSizes(context);
    
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: sizes['dutyCardPadding']!,
          horizontal: sizes['blueBoxPadding']!,
        ),
        margin: EdgeInsets.only(
          top: sizes['dutyCardMargin']! * 0.5,
          bottom: sizes['dutyCardMargin']! * 0.5,
        ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Duty title
          Text(
            event.title,
            style: TextStyle(
              fontSize: sizes['dutyTitle']!,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: sizes['dutyCardMargin']! * 0.75),
          
          // Start - End time (stacked vertically)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.formattedStartTime,
                style: TextStyle(
                  fontSize: sizes['timeText']!, 
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: sizes['dutyCardMargin']! * 0.3),
              Icon(
                Icons.keyboard_arrow_down,
                size: sizes['arrowIcon']!,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              SizedBox(height: sizes['dutyCardMargin']! * 0.3),
              Text(
                event.formattedEndTime,
                style: TextStyle(
                  fontSize: sizes['timeText']!, 
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          
          // Break times
          if (hasBreaks) ...[
            SizedBox(height: sizes['dutyCardMargin']! * 0.75),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause_circle_outline, size: sizes['breakIcon']!),
                SizedBox(width: sizes['dutyCardMargin']! * 0.5),
                Flexible(
                  child: Text(
                    '${_formatTimeOfDay(event.breakStartTime!)}-${_formatTimeOfDay(event.breakEndTime!)}',
                    style: TextStyle(
                      fontSize: sizes['breakText']!,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
          
          // Work time - always show if available
          if (event.workTime != null) ...[
            SizedBox(height: sizes['dutyCardMargin']! * 0.75),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: sizes['dutyCardPadding']! * 0.5,
                vertical: sizes['dutyCardMargin']! * 0.3,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(event.workTime!),
                style: TextStyle(
                  fontSize: sizes['workDuration']!,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }



  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Responsive sizing helper method - optimized for compact fit
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate compact sizing based on screen dimensions
    final isSmallScreen = screenWidth < 400 || screenHeight < 700;
    final isMediumScreen = screenWidth < 600 && screenHeight < 900;
    
    // Very small screens - compact sizing
    if (isSmallScreen) {
      return {
        'dayName': 12.0,
        'date': 10.0,
        'shiftName': 9.0,
        'dutyTitle': 9.0,
        'timeText': 11.0,
        'breakText': 8.0,
        'workDuration': 8.0,
        'eventTitle': 8.0,
        'moreText': 7.0,
        'arrowIcon': 10.0,
        'breakIcon': 8.0,
        'dutyCardPadding': 4.0,
        'dutyCardMargin': 2.0,
        'cardSpacing': 4.0,
        'verticalSpacing': 6.0,
        'horizontalPadding': 4.0,
        'blueBoxMargin': 3.0,
        'blueBoxPadding': 3.0,
      };
    }
    // Medium screens - balanced sizing
    else if (isMediumScreen) {
      return {
        'dayName': 14.0,
        'date': 12.0,
        'shiftName': 11.0,
        'dutyTitle': 11.0,
        'timeText': 12.0,
        'breakText': 10.0,
        'workDuration': 10.0,
        'eventTitle': 10.0,
        'moreText': 9.0,
        'arrowIcon': 11.0,
        'breakIcon': 10.0,
        'dutyCardPadding': 6.0,
        'dutyCardMargin': 3.0,
        'cardSpacing': 6.0,
        'verticalSpacing': 8.0,
        'horizontalPadding': 6.0,
        'blueBoxMargin': 4.0,
        'blueBoxPadding': 4.0,
      };
    }
    // Larger screens - comfortable sizing
    else {
      return {
        'dayName': 16.0,
        'date': 14.0,
        'shiftName': 13.0,
        'dutyTitle': 13.0,
        'timeText': 13.0,
        'breakText': 11.0,
        'workDuration': 11.0,
        'eventTitle': 11.0,
        'moreText': 10.0,
        'arrowIcon': 12.0,
        'breakIcon': 11.0,
        'dutyCardPadding': 8.0,
        'dutyCardMargin': 4.0,
        'cardSpacing': 8.0,
        'verticalSpacing': 8.0,
        'horizontalPadding': 8.0,
        'blueBoxMargin': 5.0,
        'blueBoxPadding': 5.0,
      };
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
