import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/widgets/event_card.dart';
import 'package:spdrivercalendar/features/calendar/widgets/shift_details_card.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/shift_info.dart';

class DayDetailEventItem {
  const DayDetailEventItem({
    required this.event,
    required this.shiftType,
    required this.isBankHoliday,
    required this.isRestDay,
    required this.isWorkoutDay,
  });

  final Event event;
  final String shiftType;
  final bool isBankHoliday;
  final bool isRestDay;
  final bool isWorkoutDay;
}

/// Selected-day summary and event cards with all business decisions supplied
/// by the calendar feature boundary.
class DayDetailSection extends StatelessWidget {
  const DayDetailSection({
    super.key,
    required this.selectedDate,
    required this.shiftInfoMap,
    required this.events,
    required this.onAddEvent,
    required this.onEditEvent,
    required this.onShowEventNotes,
    required this.onBusAssignmentUpdate,
    required this.highlightWorkoutDays,
    required this.onShowDayNotes,
    this.showShiftSummary = false,
    this.shift = '',
    this.bankHoliday,
    this.hasDayNote = false,
    this.showBankHolidayRedundant = false,
  });

  final DateTime selectedDate;
  final Map<String, ShiftInfo> shiftInfoMap;
  final List<DayDetailEventItem> events;
  final VoidCallback onAddEvent;
  final ValueChanged<Event> onEditEvent;
  final ValueChanged<Event> onShowEventNotes;
  final Future<void> Function(Event) onBusAssignmentUpdate;
  final bool highlightWorkoutDays;
  final bool showShiftSummary;
  final String shift;
  final BankHoliday? bankHoliday;
  final bool hasDayNote;
  final bool showBankHolidayRedundant;
  final VoidCallback onShowDayNotes;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 350
        ? 8.0
        : screenWidth < 450
            ? 12.0
            : 16.0;
    final emptyPadding = screenWidth < 350 ? 10.0 : 16.0;
    final emptyFontSize = screenWidth < 350 ? 14.0 : 16.0;

    return Column(
      children: [
        if (showShiftSummary)
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: horizontalPadding,
            ),
            child: ShiftDetailsCard(
              date: selectedDate,
              shift: shift,
              shiftInfoMap: shiftInfoMap,
              bankHoliday: bankHoliday,
              hasDayNote: hasDayNote,
              onShowDayNotes: onShowDayNotes,
              showBankHolidayRedundant: showBankHolidayRedundant,
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Events (${events.length})',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      color: Colors.blue,
                      onPressed: onAddEvent,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ],
                ),
              ),
              if (events.isEmpty)
                Padding(
                  padding: EdgeInsets.all(emptyPadding),
                  child: Center(
                    child: Text(
                      'No events for ${DateFormat('EEEE, MMMM d').format(selectedDate)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: emptyFontSize,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    for (final item in events)
                      EventCard(
                        event: item.event,
                        shiftType: item.shiftType,
                        shiftInfoMap: shiftInfoMap,
                        isBankHoliday: item.isBankHoliday,
                        isRestDay: item.isRestDay,
                        onEdit: onEditEvent,
                        onShowNotes: onShowEventNotes,
                        onBusAssignmentUpdate: onBusAssignmentUpdate,
                        highlightWorkoutDays: highlightWorkoutDays,
                        isWorkoutDay: item.isWorkoutDay,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
