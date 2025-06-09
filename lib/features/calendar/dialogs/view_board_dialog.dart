import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/board_entry.dart';

class ViewBoardDialog extends StatelessWidget {
  final List<BoardEntry> entries;
  final String dutyNumber;
  final int weekday;
  final bool isBankHoliday;

  const ViewBoardDialog({
    Key? key,
    required this.entries,
    required this.dutyNumber,
    required this.weekday,
    required this.isBankHoliday,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Duty $dutyNumber Board',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No board entries found for this duty',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      
                      // If this is a Finish entry, we need to show an SPL to Garage before it
                      if (entry.route == 'Finish') {
                        // Skip this entry if it's not the one we want to show
                        if (index > 0) {
                          final prevEntry = entries[index - 1];
                          // Don't show SPL if previous entry is already an SPL
                          if (prevEntry.route != 'SPL') {
                            // Create SPL entry based on the day
                            final splEntry = BoardEntry(
                              route: 'SPL',
                              from: prevEntry.location,
                              to: 'Garage',
                              location: prevEntry.location,
                              duty: dutyNumber,
                              // For M-F use arrival time from current Finish entry
                              arrival: weekday >= DateTime.monday && weekday <= DateTime.friday && !isBankHoliday
                                ? entry.arrival 
                                : null,
                              // For Sunday and Bank Holidays use departure time from previous entry
                              departure: (weekday == DateTime.sunday || isBankHoliday)
                                ? prevEntry.departure 
                                : null,
                              // For Saturday use arrival time for the time display
                              departs: weekday == DateTime.saturday 
                                ? prevEntry.arrival 
                                : null,
                            );

                            // Show SPL card...
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Timeline line and dot
                                  SizedBox(
                                    width: 32,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.directions_bus,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Entry content
                                  Expanded(
                                    child: Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: _buildRouteInfo(splEntry, index),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      }

                      // Skip Break entries
                      if (entry.route == 'Break') {
                        return const SizedBox.shrink();
                      }

                      // Show SPL entries and regular route entries
                      final isLast = index == entries.length - 1;
                      
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Timeline line and dot
                            SizedBox(
                              width: 32,
                              child: Column(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getEntryIcon(entry),
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // Entry content
                            Expanded(
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: entry.route == 'SPL' 
                                    ? _buildRouteInfo(entry, index)
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Time and Location
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (entry.route != 'SPL')
                                                Text(
                                                  _getTimeText(entry, index),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              if (entry.route != 'SPL' && entry.route != 'Break' && entry.route != 'Finish')
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    entry.location,
                                                    style: TextStyle(
                                                      color: Theme.of(context).primaryColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          
                                          const SizedBox(height: 2),
                                          
                                          // Route and Direction
                                          if (entry.route != 'Finish')
                                            _buildRouteInfo(entry, index),
                                          
                                          // Notes
                                          if (entry.notes != null && entry.notes!.isNotEmpty && !entry.notes!.contains('SPL to Garage')) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      entry.notes!,
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ] else if (entry.route == 'Finish' && entry.location == 'Garage' && !entry.notes!.contains('Finished Duty')) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'End of First Half',
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 11,
                                                      ),
                                                    ),
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
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEntryIcon(BoardEntry entry) {
    if (entry.route == 'SPL') return Icons.directions_bus;
    if (entry.route == 'Break') return Icons.coffee;
    if (entry.route == 'Finish') return Icons.check_circle;
    return Icons.location_on;
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    // If time is already in HH:mm:ss format, return as is
    if (time.length == 8) return time;
    // If time is in HH:mm format, append :00
    if (time.length == 5) return '$time:00';
    return time;
  }

  String _getTimeText(BoardEntry entry, int index) {
    // For first entry (from garage), show departs time
    if (index == 0) {
      return entry.departs != null ? 'Departs: ${_formatTime(entry.departs)}' : '';
    }

    // For SPL routes
    if (entry.route == 'SPL') {
      // Only show departs time for SPL trips FROM garage
      if (entry.location == 'Garage') {
        // For Sunday and Bank Holidays, use departs time if available, otherwise use departure
        if (weekday == DateTime.sunday || isBankHoliday) {
          return entry.departs != null ? 'Departs: ${_formatTime(entry.departs)}' : 
                 entry.departure != null ? 'Departs: ${_formatTime(entry.departure)}' : '';
        }
        return entry.departs != null ? 'Departs: ${_formatTime(entry.departs)}' : '';
      }
      return '';
    }

    // For regular routes (L58, L59), show departure time
    if (entry.route != 'Break' && entry.route != 'Finish') {
      // For Sunday and Bank Holidays, show departure time
      if (weekday == DateTime.sunday || isBankHoliday) {
        return entry.departure != null ? 'Departs: ${_formatTime(entry.departure)}' : '';
      }
      // For other days, show departure time
      return entry.departure != null ? 'Departs: ${_formatTime(entry.departure)}' : '';
    }

    return '';
  }

  String _getRouteText(BoardEntry entry, int index) {
    if (entry.route == 'SPL') {
      // For SPL from Garage, show Garage → next location
      if (entry.location == 'Garage') {
        return '${entry.location} → ${_getNextLocation(entries, index)}';
      }
      // For SPL to Garage, show current location → Garage
      return '${entry.location} → Garage';
    }
    if (entry.route != 'Break' && entry.route != 'Finish' && entry.from != null && entry.to != null) {
      return '${entry.from} → ${entry.to}';
    }
    return '';
  }

  Widget _buildRouteInfo(BoardEntry entry, int index) {
    if (entry.route == 'Break') {
      return const SizedBox.shrink();
    }

    if (entry.route == 'SPL' || (entry.route != 'Break' && entry.route != 'Finish')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.route == 'SPL' && entry.location == 'Garage') ...[
            Text(
              _getTimeText(entry, index),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: entry.route == 'SPL' 
                    ? Colors.orange.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  entry.route,
                  style: TextStyle(
                    color: entry.route == 'SPL' ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_getRouteText(entry, index).isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getRouteText(entry, index),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _getNextLocation(List<BoardEntry> entries, int currentIndex) {
    // Skip the current entry and look for the next non-SPL entry
    for (var i = currentIndex + 1; i < entries.length; i++) {
      if (entries[i].route != 'SPL') {
        return entries[i].location;
      }
    }
    // If no next location found and this is the last regular trip, return Garage
    if (currentIndex == entries.where((entry) => entry.route != 'Break' && entry.route != 'SPL' && entry.route != 'Finish').length - 1) {
      return 'Garage';
    }
    // If no next location found, return the current location
    return entries[currentIndex].location;
  }


} 
