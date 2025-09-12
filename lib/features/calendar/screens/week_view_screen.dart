import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class WeekViewScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, ShiftInfo> shiftInfoMap;

  const WeekViewScreen({
    Key? key,
    required this.selectedDate,
    required this.shiftInfoMap,
  }) : super(key: key);

  @override
  WeekViewScreenState createState() => WeekViewScreenState();
}

class WeekViewScreenState extends State<WeekViewScreen> {
  late DateTime _currentWeekStart;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _calculateWeekStart();
    _generateWeekDays();
  }

  void _calculateWeekStart() {
    // Calculate the start of the week (Sunday)
    // DateTime.weekday: Monday = 1, Sunday = 7
    final weekday = widget.selectedDate.weekday;
    // For Sunday-first week: Sunday = 0 days back, Monday = 1 day back, etc.
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

  ShiftInfo? _getShiftForDate(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return widget.shiftInfoMap[dateString];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Week View'),
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
        child: SingleChildScrollView(
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
                    Text(
                      '${DateFormat('MMM d').format(_weekDays.first)} - ${DateFormat('MMM d, yyyy').format(_weekDays.last)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _navigateWeek(1),
                    ),
                  ],
                ),
              ),
              
              // Week view content - Stacked layout (1-3-3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                children: [
                  // Row 1: Sunday only (centered)
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        const Expanded(child: SizedBox()), // Left spacer
                        Expanded(
                          flex: 2,
                          child: _buildDayCard(_weekDays[0]), // Sunday (first in the week starting Sunday)
                        ),
                        const Expanded(child: SizedBox()), // Right spacer
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Row 2: Monday, Tuesday, Wednesday
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(child: _buildDayCard(_weekDays[1])), // Monday
                        const SizedBox(width: 8),
                        Expanded(child: _buildDayCard(_weekDays[2])), // Tuesday
                        const SizedBox(width: 8),
                        Expanded(child: _buildDayCard(_weekDays[3])), // Wednesday
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Row 3: Thursday, Friday, Saturday
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(child: _buildDayCard(_weekDays[4])), // Thursday
                        const SizedBox(width: 8),
                        Expanded(child: _buildDayCard(_weekDays[5])), // Friday
                        const SizedBox(width: 8),
                        Expanded(child: _buildDayCard(_weekDays[6])), // Saturday
                      ],
                    ),
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

  Widget _buildDayCard(DateTime day) {
    final shift = _getShiftForDate(day);
    final sizes = _getResponsiveSizes(context);
    final events = _getEventsForDate(day);
    final workEvents = events.where((event) => event.isWorkShift).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isToday(day) 
            ? AppTheme.primaryColor 
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: _isToday(day) ? 4 : 1,
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
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _isToday(day) 
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE').format(day),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: sizes['dayName']!,
                    color: _isToday(day) ? AppTheme.primaryColor : null,
                  ),
                  textAlign: TextAlign.center,
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
                ),
              ],
            ),
          ),
          
          // Day content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Column(
                children: [
                  // Shift info
                  if (shift != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: shift.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: shift.color, width: 1),
                      ),
                      child: Text(
                        shift.name,
                        style: TextStyle(
                          fontSize: sizes['shiftName']!,
                          fontWeight: FontWeight.w600,
                          color: shift.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Work events
                  if (workEvents.isNotEmpty) ...[
                    ...workEvents.map((event) => _buildDayDutyItem(event)),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.free_breakfast,
                              size: sizes['moreText']! * 4, // Responsive icon size
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            SizedBox(height: sizes['dutyCardMargin']!),
                            Text(
                              'Free Day',
                              style: TextStyle(
                                fontSize: sizes['moreText']!,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Non-work events
                  if (events.any((event) => !event.isWorkShift)) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Other Events',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          ...events.where((event) => !event.isWorkShift).take(2).map((event) => 
                            Text(
                              event.title,
                              style: TextStyle(fontSize: sizes['eventTitle']!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (events.where((event) => !event.isWorkShift).length > 2)
                            Text(
                              '+${events.where((event) => !event.isWorkShift).length - 2} more',
                              style: TextStyle(fontSize: sizes['moreText']!),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
                ),
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
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(sizes['dutyCardPadding']!),
      margin: EdgeInsets.only(bottom: sizes['dutyCardMargin']!),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
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
          
          const SizedBox(height: 6),
          
          // Start - End time (stacked vertically)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Text(
                  event.formattedStartTime,
                  style: TextStyle(
                    fontSize: sizes['timeText']!, 
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: sizes['arrowIcon']!,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                Text(
                  event.formattedEndTime,
                  style: TextStyle(
                    fontSize: sizes['timeText']!, 
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          
          // Break times
          if (hasBreaks) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pause_circle_outline, size: sizes['breakIcon']!),
                const SizedBox(width: 3),
                Text(
                  '${_formatTimeOfDay(event.breakStartTime!)}-${_formatTimeOfDay(event.breakEndTime!)}',
                  style: TextStyle(
                    fontSize: sizes['breakText']!,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
          
          // Work time
          if (event.workTime != null) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
              ),
            ),
          ],
        ],
      ),
    );
  }



  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Responsive sizing helper method
  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Very small screens (narrow phones) - ULTRA conservative to prevent overflow
    if (screenWidth < 350) {
      return {
        'dayName': 11.0,  // even smaller
        'date': 9.0,      // even smaller
        'shiftName': 8.0,   // even smaller
        'dutyTitle': 8.0,   // even smaller
        'timeText': 10.0,   // made bigger for readability
        'breakText': 7.0,   // keep small
        'workDuration': 6.0,  // even smaller
        'eventTitle': 7.0,    // even smaller
        'moreText': 6.0,      // even smaller
        'arrowIcon': 8.0,     // slightly bigger for visibility
        'breakIcon': 7.0,     // keep small
        // Container dimensions - ULTRA conservative for very small screens
        'dutyCardPadding': 3.0,  // even smaller
        'dutyCardMargin': 1.0,    // even smaller
      };
    }
    // Mid-range phones (like S23) - MUCH MORE generous for readability 
    else if (screenWidth < 450) {
      return {
        'dayName': 20.0,  // +4 (more generous)
        'date': 17.0,     // +4 (more generous)
        'shiftName': 16.0,   // +4 (more generous)
        'dutyTitle': 15.0,   // +4 (more generous)
        'timeText': 14.0,    // +4 (MUCH bigger - was 12, now 14)
        'breakText': 13.0,   // +4 (more generous)
        'workDuration': 12.0,  // +4 (more generous)
        'eventTitle': 13.0,    // +4 (more generous)
        'moreText': 12.0,      // +4 (more generous)
        'arrowIcon': 12.0,     // +2 (bigger)
        'breakIcon': 14.0,     // +4 (more generous)
        // Container dimensions - MORE generous for mid-range phones but contained
        'dutyCardPadding': 12.0,  // +4 (generous but not excessive)
        'dutyCardMargin': 8.0,    // +2 (reasonable spacing)
      };
    }
    // Larger phones and small tablets
    else if (screenWidth < 600) {
      return {
        'dayName': 20.0,  // +4
        'date': 17.0,     // +4
        'shiftName': 16.0,   // +4
        'dutyTitle': 15.0,   // +4
        'timeText': 13.0,    // +3
        'breakText': 13.0,   // +4
        'workDuration': 12.0,  // +4
        'eventTitle': 13.0,    // +4
        'moreText': 12.0,      // +4
        'arrowIcon': 12.0,     // +2
        'breakIcon': 14.0,     // +4
        // Container dimensions - larger for good-sized phones but contained
        'dutyCardPadding': 12.0,  // +4 (generous but controlled)
        'dutyCardMargin': 10.0,    // +4 (good spacing)
      };
    }
    // Medium sizes for tablets or larger phones
    else if (screenWidth < 900) {
      return {
        'dayName': 20.0,  // +3
        'date': 17.0,     // +3
        'shiftName': 16.0,   // +3
        'dutyTitle': 15.0,   // +3
        'timeText': 14.0,    // +3
        'breakText': 13.0,   // +3
        'workDuration': 12.0,  // +3
        'eventTitle': 13.0,    // +3
        'moreText': 12.0,      // +3
        'arrowIcon': 14.0,     // +3
        'breakIcon': 14.0,     // +3
        // Container dimensions - moderate for medium screens
        'dutyCardPadding': 10.0,  // controlled sizing
        'dutyCardMargin': 8.0,   // controlled spacing
      };
    }
    // Large sizes for desktop/large tablets
    else {
      return {
        'dayName': 22.0,  // +4
        'date': 19.0,     // +4
        'shiftName': 18.0,   // +4
        'dutyTitle': 17.0,   // +4
        'timeText': 16.0,    // +4
        'breakText': 15.0,   // +4
        'workDuration': 14.0,  // +4
        'eventTitle': 15.0,    // +4
        'moreText': 14.0,      // +4
        'arrowIcon': 16.0,     // +4
        'breakIcon': 16.0,     // +4
        // Container dimensions - controlled even for large screens
        'dutyCardPadding': 12.0,  // generous but contained
        'dutyCardMargin': 10.0,   // good spacing
      };
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
