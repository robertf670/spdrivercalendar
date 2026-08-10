import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/spare_shift_duties.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Bus assignment controls for the Edit Event dialog.
///
/// Persistence and dialog reopen stay with the caller via
/// [onBusAssignmentChanged].
class EditEventBusAssignmentSection extends StatelessWidget {
  const EditEventBusAssignmentSection({
    super.key,
    required this.event,
    required this.isTrackingBus,
    required this.onTrackBus,
    required this.onBusAssignmentChanged,
  });

  final Event event;
  final bool Function(String? busNumber) isTrackingBus;
  final Future<void> Function(String busNumber) onTrackBus;
  final Future<void> Function(Event oldEvent, Event updatedEvent)
      onBusAssignmentChanged;

  @override
  Widget build(BuildContext context) {
    if (!((event.isWorkShift && !event.title.startsWith('BusCheck')) ||
        SpareShiftDuties.hasFullDuties(event))) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      children: [
                        Icon(Icons.directions_bus, size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bus Assignment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                                        onTap: isTrackingBus(event.firstHalfBus)
                                            ? null
                                            : () => onTrackBus(event.firstHalfBus!),
                                        child: Container(
                                          padding: EdgeInsets.all(iconPadding),
                                          child: isTrackingBus(event.firstHalfBus)
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
                                        await onBusAssignmentChanged(oldEvent, updatedEvent);
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
                                          await onBusAssignmentChanged(oldEvent, updatedEvent);
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
                                        onTap: isTrackingBus(event.secondHalfBus)
                                            ? null
                                            : () => onTrackBus(event.secondHalfBus!),
                                        child: Container(
                                          padding: EdgeInsets.all(iconPadding),
                                          child: isTrackingBus(event.secondHalfBus)
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
                                        await onBusAssignmentChanged(oldEvent, updatedEvent);
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
                                      await onBusAssignmentChanged(oldEvent, updatedEvent);
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
                                await onBusAssignmentChanged(oldEvent, updatedEvent);
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
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Icon(Icons.directions_bus, size: 18),
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
                                        await onBusAssignmentChanged(oldEvent, updatedEvent);
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
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          const Icon(Icons.directions_bus, size: 18),
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
                                        await onBusAssignmentChanged(oldEvent, updatedEvent);
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
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          const Icon(Icons.directions_bus, size: 18),
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
        const SizedBox(height: 8),
      ],
    );
  }
}
