import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:spdrivercalendar/features/calendar/widgets/event_card.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/models/shift_info.dart';

class CalendarWidget extends StatefulWidget {
  final Function(DateTime) onDaySelected;
  final Map<String, ShiftInfo> shiftInfoMap;
  final Function(Event) onShowNotes;
  
  const CalendarWidget({
    Key? key, 
    required this.onDaySelected,
    required this.shiftInfoMap,
    required this.onShowNotes,
  }) : super(key: key);
  
  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  List<Event> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Initialize with today's events
    _selectedEvents = _getEventsForDay(_selectedDay!);
  }

  List<Event> _getEventsForDay(DateTime day) {
    return EventService.getEventsForDay(day);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          eventLoader: _getEventsForDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _selectedEvents = _getEventsForDay(selectedDay);
            });
            widget.onDaySelected(selectedDay);
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          // Calendar styling
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: _selectedEvents.isEmpty
              ? Center(
                  child: Text(
                    'No events for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  itemCount: _selectedEvents.length,
                  itemBuilder: (context, index) {
                    final event = _selectedEvents[index];
                    return EventCard(
                      event: event,
                      shiftType: '',
                      shiftInfoMap: widget.shiftInfoMap,
                      onEdit: (Event e) {
                        print("Edit requested from CalendarWidget for: ${e.title}");
                      },
                      onShowNotes: widget.onShowNotes,
                      isBankHoliday: false,
                      isRestDay: false,
                    );
                  },
                ),
        ),
      ],
    );
  }
} 