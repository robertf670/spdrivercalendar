import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/widgets/dialog_insets.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/utils/assigned_duty_board_lookup.dart';
import 'package:spdrivercalendar/features/calendar/utils/spare_shift_duties.dart';
import 'package:spdrivercalendar/features/ratings/duty_rate_menu_actions.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

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
    this.onSwapDuty,
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
  final VoidCallback? onSwapDuty;
  final Widget? busAssignmentSection;
  final Future<UniversalBoard?> Function()? loadBoard;

  bool get _showDelete =>
      !(event.isWorkShift && event.title.startsWith('SP')) ||
      SpareShiftDuties.hasFullDuties(event);

  /// Zone/Jamestown/Uni from the event title, then spare assigned duties.
  static Future<UniversalBoard?> _defaultLoadBoard(Event event) {
    return AssignedDutyBoardLookup.loadForEvent(event);
  }

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boardLoader = loadBoard ?? () => _defaultLoadBoard(event);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: dialogHorizontalInset(context),
        vertical: screenWidth < 350 ? 12 : 24,
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      title: const Text('Edit Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              displayTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${DateFormat('EEE, MMM d').format(event.startDate)} ${event.formattedStartTime} - ${event.formattedEndTime}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (onSwapDuty != null)
              _actionButton(
                icon: Icons.swap_horiz,
                label: 'Swap duty',
                onPressed: () {
                  _close(context);
                  onSwapDuty!();
                },
              ),
            FutureBuilder<UniversalBoard?>(
              future: boardLoader(),
              builder: (context, snapshot) {
                final board = snapshot.data;
                final hasBoard = board != null && board.sections.isNotEmpty;
                if (!hasBoard) return const SizedBox.shrink();
                return _actionButton(
                  icon: Icons.description,
                  label: 'View Board',
                  onPressed: () {
                    _close(context);
                    onViewBoard(board);
                  },
                );
              },
            ),
            if (event.isCustomTraining)
              _actionButton(
                icon: Icons.school,
                label: 'Edit Training',
                onPressed: () async {
                  _close(context);
                  await onEditTraining();
                },
              ),
            if (event.isEligibleForOvertimeTracking)
              _actionButton(
                icon: Icons.free_breakfast,
                label: 'Break & Finish',
                onPressed: () {
                  _close(context);
                  onBreakFinish();
                },
              ),
            if (event.isWorkShift)
              _actionButton(
                icon: Icons.sick,
                label: 'Sick Day Status',
                onPressed: () {
                  _close(context);
                  onSickDayStatus();
                },
              ),
            DutyRateMenuActions(
              event: event,
              style: DutyRateMenuStyle.list,
            ),
            if (showBankHolidayRedundant) ...[
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Bank holiday — redundant',
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      'Rostered on the bank holiday but off (not working)',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: event.bankHolidayRedundant,
                    onChanged: (value) async {
                      await onBankHolidayRedundantChanged(value);
                      setDialogState(() {});
                    },
                  );
                },
              ),
            ],
            if (busAssignmentSection != null) busAssignmentSection!,
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      actions: [
        OverflowBar(
          spacing: 0,
          children: [
            if (_showDelete)
              TextButton(
                style: _barButtonStyle(foreground: Colors.red),
                onPressed: () async {
                  await onDelete();
                },
                child: const Text('Delete'),
              ),
            TextButton(
              style: _barButtonStyle(),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
        TextButton(
          style: _barButtonStyle(),
          onPressed: () {
            _close(context);
            onNotes();
          },
          child: const Text('Notes'),
        ),
      ],
    );
  }
}

ButtonStyle _barButtonStyle({Color? foreground}) {
  return TextButton.styleFrom(
    foregroundColor: foreground,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    minimumSize: const Size(48, 48),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}

Widget _actionButton({
  required IconData icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return TextButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    label: Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
  );
}
