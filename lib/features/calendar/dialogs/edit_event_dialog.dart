import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/utils/spare_shift_duties.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/universal_board.dart';
import 'package:spdrivercalendar/services/universal_board_service.dart';
import 'package:spdrivercalendar/services/zone_board_service.dart';

/// Presentation dialog for editing/deleting a calendar event.
///
/// Bus assignment UI is supplied by [busAssignmentSection] so persistence and
/// tracking stay with the caller.
class EditEventDialog extends StatelessWidget {
  const EditEventDialog({
    super.key,
    required this.event,
    required this.displayTitle,
    required this.showBankHolidayRedundant,
    required this.onNotes,
    required this.onBreakFinish,
    required this.onSickDayStatus,
    required this.onEditTraining,
    required this.onViewBoard,
    required this.onBankHolidayRedundantChanged,
    required this.onDelete,
    this.busAssignmentSection,
    this.loadBoard,
  });

  final Event event;
  final String displayTitle;
  final bool showBankHolidayRedundant;
  final VoidCallback onNotes;
  final VoidCallback onBreakFinish;
  final VoidCallback onSickDayStatus;
  final Future<void> Function() onEditTraining;
  final void Function(UniversalBoard board) onViewBoard;
  final Future<void> Function(bool value) onBankHolidayRedundantChanged;
  final Future<void> Function() onDelete;
  final Widget? busAssignmentSection;
  final Future<UniversalBoard?> Function()? loadBoard;

  bool get _showDelete =>
      !(event.isWorkShift && event.title.startsWith('SP')) ||
      SpareShiftDuties.hasFullDuties(event);

  /// Zone boards (PZ1/3/4 by day type), Jamestown (811/xx), then Uni/Euro.
  static Future<UniversalBoard?> _defaultLoadBoard(Event event) async {
    final zoneBoard = await ZoneBoardService.getBoardForDuty(
      dutyTitle: event.title,
      date: event.startDate,
    );
    if (zoneBoard != null) return zoneBoard;
    return UniversalBoardService.getBoardByShift(event.title);
  }

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {
        'insetH': 16.0,
        'insetV': 16.0,
        'titleSize': 16.0,
        'bhTitle': 13.0,
        'bhSubtitle': 11.0,
      };
    }
    if (screenWidth < 400) {
      return {
        'insetH': 24.0,
        'insetV': 20.0,
        'titleSize': 18.0,
        'bhTitle': 13.5,
        'bhSubtitle': 11.5,
      };
    }
    return {
      'insetH': 40.0,
      'insetV': 24.0,
      'titleSize': 20.0,
      'bhTitle': 14.0,
      'bhSubtitle': 12.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final boardLoader = loadBoard ?? () => _defaultLoadBoard(event);

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: sizes['insetH']!,
        vertical: sizes['insetV']!,
      ),
      title: Text(
        'Edit Event',
        style: TextStyle(fontSize: sizes['titleSize']),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('EEE, MMM d').format(event.startDate)} ${event.formattedStartTime} - ${event.formattedEndTime}',
            ),
            const SizedBox(height: 8),
            const Text('What would you like to do with this event?'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FutureBuilder<UniversalBoard?>(
                    future: boardLoader(),
                    builder: (context, snapshot) {
                      final board = snapshot.data;
                      final hasBoard =
                          board != null && board.sections.isNotEmpty;
                      if (!hasBoard) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            _close(context);
                            onViewBoard(board);
                          },
                          icon: const Icon(Icons.description, size: 18),
                          label: const Text('View Board'),
                        ),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      _close(context);
                      onNotes();
                    },
                    child: const Text('Notes'),
                  ),
                  if (event.isCustomTraining) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        _close(context);
                        await onEditTraining();
                      },
                      child: const Text('Edit Training Details'),
                    ),
                  ],
                  if (event.isEligibleForOvertimeTracking) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _close(context);
                        onBreakFinish();
                      },
                      child: const Text('Break & Finish'),
                    ),
                  ],
                  if (event.isWorkShift) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _close(context);
                        onSickDayStatus();
                      },
                      child: const Text('Sick Day Status'),
                    ),
                  ],
                  if (showBankHolidayRedundant) ...[
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setDialogState) {
                        return SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Bank holiday — redundant',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: sizes['bhTitle'],
                            ),
                          ),
                          subtitle: Text(
                            'Rostered on the bank holiday but off (not working)',
                            style: TextStyle(fontSize: sizes['bhSubtitle']),
                          ),
                          value: event.bankHolidayRedundant,
                          onChanged: (v) async {
                            await onBankHolidayRedundantChanged(v);
                            setDialogState(() {});
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (busAssignmentSection != null) ...[
              busAssignmentSection!,
            ],
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_showDelete)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      await onDelete();
                    },
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
