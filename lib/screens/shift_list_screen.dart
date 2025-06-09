import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/work_shift.dart';
import 'package:spdrivercalendar/services/shift_service.dart';
import 'package:intl/intl.dart';

class ShiftListScreen extends StatefulWidget {
  const ShiftListScreen({super.key});

  @override
  _ShiftListScreenState createState() => _ShiftListScreenState();
}

class _ShiftListScreenState extends State<ShiftListScreen> {
  late List<WorkShift> _shifts;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy - HH:mm');
  
  @override
  void initState() {
    super.initState();
    _shifts = ShiftService.getAllShifts();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Shifts'),
      ),
      body: _shifts.isEmpty
          ? const Center(child: Text('No shifts created yet'))
          : ListView.builder(
              itemCount: _shifts.length,
              itemBuilder: (context, index) {
                final shift = _shifts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(shift.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start: ${_dateFormat.format(shift.startTime)}'),
                        Text('End: ${_dateFormat.format(shift.endTime)}'),
                        if (shift.location.isNotEmpty)
                          Text('Location: ${shift.location}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        // Capture ScaffoldMessenger before async operation
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final success = await shift.addToGoogleCalendar(context);
                        if (success) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(content: Text('Added to Google Calendar')),
                          );
                        }
                      },
                      tooltip: 'Add to Google Calendar',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
