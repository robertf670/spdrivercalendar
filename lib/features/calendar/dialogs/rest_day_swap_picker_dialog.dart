import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RestDaySwapCandidateOption {
  const RestDaySwapCandidateOption({
    required this.date,
    required this.label,
  });

  final DateTime date;
  final String label;
}

/// Presentation picker for choosing the other day in a rest-day swap.
class RestDaySwapPickerDialog extends StatelessWidget {
  const RestDaySwapPickerDialog({
    super.key,
    required this.isWorkDay,
    required this.candidates,
  });

  final bool isWorkDay;
  final List<RestDaySwapCandidateOption> candidates;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 40.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: Text(isWorkDay ? 'Swap with rest day' : 'Swap with work day'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: candidates.map((candidate) {
            return ListTile(
              title: Text(
                '${DateFormat('EEEE d MMM').format(candidate.date)} (${candidate.label})',
              ),
              onTap: () => Navigator.pop(context, candidate.date),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
