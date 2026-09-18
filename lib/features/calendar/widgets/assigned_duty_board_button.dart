import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/universal_board_dialog.dart';
import 'package:spdrivercalendar/features/calendar/utils/assigned_duty_board_lookup.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

/// Loads a board for an assigned spare duty and shows View Board when found.
class AssignedDutyBoardButton extends StatelessWidget {
  const AssignedDutyBoardButton({
    super.key,
    required this.dutyCode,
    required this.date,
    this.compact = false,
  });

  final String dutyCode;
  final DateTime date;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UniversalBoard?>(
      future: AssignedDutyBoardLookup.load(
        assignedDuty: dutyCode,
        date: date,
      ),
      builder: (context, snapshot) {
        final board = snapshot.data;
        if (board == null || board.sections.isEmpty) {
          return const SizedBox.shrink();
        }

        void openBoard() {
          showDialog<void>(
            context: context,
            builder: (_) => UniversalBoardDialog(board: board),
          );
        }

        if (compact) {
          return IconButton(
            tooltip: 'View Board',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            iconSize: 18,
            onPressed: openBoard,
            icon: const Icon(Icons.description),
          );
        }

        return TextButton.icon(
          onPressed: openBoard,
          icon: const Icon(Icons.description, size: 18),
          label: const Text('View Board'),
        );
      },
    );
  }
}
