import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/board_entry.dart';

class ViewBoardDialog extends StatelessWidget {
  final List<BoardEntry> entries;
  final String dutyNumber;
  final int weekday;
  final bool isBankHoliday;
  final String? zone;

  const ViewBoardDialog({
    Key? key,
    required this.entries,
    required this.dutyNumber,
    required this.weekday,
    required this.isBankHoliday,
    this.zone,
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
                      final isLast = index == entries.length - 1;

                      // 1. Handle Zone 3 Finish (Special SPL add + Hide original)
                      if (entry.route == 'Finish' && zone != 'Zone4') {
                        // For non-Zone4 (i.e., Zone 3), automatically add SPL to Garage if needed
                        // and hide the actual Finish entry itself.
                        if (index > 0) {
                          final prevEntry = entries[index - 1];
                          bool shouldShowSPL = prevEntry.route != 'SPL'; // Simplified for Zone 3
                          
                          if (shouldShowSPL) {
                            // Create SPL entry based on the day
                            final splEntry = BoardEntry(
                              route: 'SPL',
                              from: prevEntry.location ?? '',
                              to: 'Garage',
                              location: prevEntry.location ?? '',
                              duty: dutyNumber,
                              arrival: weekday >= DateTime.monday && weekday <= DateTime.friday && !isBankHoliday
                                ? entry.arrival 
                                : null,
                              departure: (weekday == DateTime.sunday || isBankHoliday)
                                ? prevEntry.departure 
                                : null,
                              departs: weekday == DateTime.saturday 
                                ? prevEntry.arrival 
                                : null,
                            );

                            // Show SPL card...
                            return _buildTimelineCard(context, splEntry, index, isLast, child: _buildRouteInfo(splEntry, index));
                          }
                        }
                        // Hide the original Finish entry for Zone 3
                        return const SizedBox.shrink(); 
                      }

                      // 2. Skip Break entries and hidden SPL entries
                      if (entry.route == 'Break' || (entry.route == 'SPL' && entry.notes == 'HIDDEN_SPL')) {
                        return const SizedBox.shrink();
                      }

                      // 3. Handle Handover (End of First Half)
                      else if (entry.route == 'Handover') {
                        return _buildTimelineCard(
                          context,
                          entry,
                          index,
                          isLast,
                          child: _buildSimpleEntryContent(context, entry, showArrival: true),
                        );
                      }

                      // 4. Handle TakeOver (Start of Second Half)
                      else if (entry.route == 'TakeOver') {
                        return _buildTimelineCard(
                          context,
                          entry,
                          index,
                          isLast,
                          child: _buildSimpleEntryContent(context, entry, showDeparture: true),
                        );
                      }

                      // 5. Handle SPL routes
                      else if (entry.route == 'SPL') {
                        return _buildTimelineCard(
                          context,
                          entry,
                          index,
                          isLast,
                          child: _buildRouteInfo(entry, index), // Uses SPL specific layout
                        );
                      }

                      // 6. Handle Zone 4 Finish 
                      else if (entry.route == 'Finish' && zone == 'Zone4') {
                         return _buildTimelineCard(
                          context,
                          entry,
                          index,
                          isLast,
                           // Show Time, Location, and Notes for Zone 4 Finish at PSQ
                          child: _buildSimpleEntryContent(context, entry, showArrival: true),
                        );
                      }

                      // 7. Handle Regular routes (Default)
                      else {
                        return _buildTimelineCard(
                          context,
                          entry,
                          index,
                          isLast,
                          child: _buildRegularEntryContent(context, entry, index),
                        );
                      }
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build the outer timeline card structure
  Widget _buildTimelineCard(BuildContext context, BoardEntry entry, int index, bool isLast, {required Widget child}) {
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
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          // Entry content card
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds content for regular route entries
  Widget _buildRegularEntryContent(BuildContext context, BoardEntry entry, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row( /* Time and Location Badge */ 
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text( _getTimeText(entry, index, forceDeparture: true), /* Force departure for regular */
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),), 
            if (entry.location.isNotEmpty) _buildLocationBadge(context, entry.location), 
          ],
        ),
        const SizedBox(height: 2),
        _buildRouteInfo(entry, index), // Route Badge + From->To
        _buildNotesSection(context, entry), // Notes if available
      ],
    );
  }

  // Builds simplified content for Handover/Takeover 
  Widget _buildSimpleEntryContent(BuildContext context, BoardEntry entry, {bool showArrival = false, bool showDeparture = false}) {
     String timePrefix = '';
     String timeValue = '';

     if (entry.route == 'Handover') {
       timePrefix = 'Hand over at ';
       timeValue = entry.arrival != null ? _formatTime(entry.arrival) : '';
     } else if (entry.route == 'TakeOver') {
       timePrefix = 'Take up at ';
       timeValue = entry.departs != null ? _formatTime(entry.departs) : '';
     }
     // Handle Finish or other cases using the flags
     else if (showArrival) { 
       timePrefix = 'Arrives: ';
       timeValue = entry.arrival != null ? _formatTime(entry.arrival) : '';
     } else if (showDeparture) { 
       timePrefix = 'Departs: '; // Should not happen for Finish, but safe fallback
       timeValue = entry.departs != null ? _formatTime(entry.departs) : '';
     }

     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row( /* Time and Location Badge */ 
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeValue.isNotEmpty ? timePrefix + timeValue : '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),), 
            if (entry.location.isNotEmpty) _buildLocationBadge(context, entry.location), 
          ],
        ),
        _buildNotesSection(context, entry), // Notes only
      ],
    );
  }

  // Builds just the notes section
  Widget _buildNotesSection(BuildContext context, BoardEntry entry) {
    if (entry.notes != null && entry.notes!.isNotEmpty && !entry.notes!.contains('SPL to Garage') && entry.notes != 'HIDDEN_SPL') {
      return Padding(
        padding: const EdgeInsets.only(top: 4.0), // Add some space if time/route is hidden
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(child: Text(entry.notes!, style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic, fontSize: 11))),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Return empty if no notes
    }
  }

  // Helper to build location badge - unchanged
  Widget _buildLocationBadge(BuildContext context, String location) {
      return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(location, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  IconData _getEntryIcon(BoardEntry entry) {
    if (entry.route == 'SPL') return Icons.directions_bus;
    if (entry.route == 'Break') return Icons.coffee;
    if (entry.route == 'Finish') return Icons.check_circle;
    if (entry.route == 'Handover') return Icons.swap_horiz;
    if (entry.route == 'TakeOver') return Icons.play_circle_outline;
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

  String _getTimeText(BoardEntry entry, int index, {bool forceDeparture = false}) {
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

    // For Finish entries, show arrival time at Garage
    if (entry.route == 'Finish') {
      return entry.arrival != null ? 'Arrives: ${_formatTime(entry.arrival)}' : '';
    }

    // For Handover entries, show arrival time
    if (entry.route == 'Handover') {
      return entry.arrival != null ? 'Arrives: ${_formatTime(entry.arrival)}' : '';
    }

    // For TakeOver entries, show departure time
    if (entry.route == 'TakeOver') {
      return entry.departs != null ? 'Departs: ${_formatTime(entry.departs)}' : '';
    }

    return '';
  }

  // Returns the text for the route direction (e.g., "From -> To")
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

  // Builds the widget for route badge and direction text
  Widget _buildRouteInfo(BoardEntry entry, int index) {
    if (entry.route == 'Break') {
      return const SizedBox.shrink();
    }

    if (entry.route == 'SPL' || (entry.route != 'Break' && entry.route != 'Finish' && entry.route != 'Handover' && entry.route != 'TakeOver')) {
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
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
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
    return entries[currentIndex].location ?? '';
  }

  bool _isEndOfFirstHalf(List<BoardEntry> entries, int currentIndex) {
    // Look ahead for a Finish entry in Garage
    for (var i = currentIndex + 1; i < entries.length; i++) {
      if (entries[i].route == 'Finish' && entries[i].location == 'Garage') {
        // Check if this is the end of first half (has "Finished Duty" in notes)
        if (i + 1 < entries.length && entries[i + 1].notes != null && entries[i + 1].notes!.contains('Finished Duty')) {
          return true;
        }
        return false;
      }
    }
    return false;
  }

  String _getPreviousLocation(List<BoardEntry> entries, int currentIndex) {
    // Look back for the previous non-SPL entry
    for (var i = currentIndex - 1; i >= 0; i--) {
      if (entries[i].route != 'SPL') {
        return entries[i].location;
      }
    }
    // If no previous location found, return the current location
    return entries[currentIndex].location ?? '';
  }
} 