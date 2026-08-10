import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/services/rest_day_swap_service.dart';

/// Confirms removal of an existing rest-day swap.
class RemoveRestDaySwapDialog extends StatelessWidget {
  const RemoveRestDaySwapDialog({
    super.key,
    required this.swap,
  });

  final RestDaySwap swap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 40.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: const Text('Remove rest day swap'),
      content: Text(
        'This day is part of a swap. Remove it? '
        '(${DateFormat('EEE d MMM').format(swap.workDate)} ↔ ${DateFormat('EEE d MMM').format(swap.restDate)})',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Remove swap'),
        ),
      ],
    );
  }
}
