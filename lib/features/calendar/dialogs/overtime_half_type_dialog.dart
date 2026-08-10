import 'package:flutter/material.dart';

/// Presentation picker for first/second overtime half.
class OvertimeHalfTypeDialog extends StatelessWidget {
  const OvertimeHalfTypeDialog({
    super.key,
    required this.onFirstHalf,
    required this.onSecondHalf,
  });

  final VoidCallback onFirstHalf;
  final VoidCallback onSecondHalf;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 40.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: const Text('Select Overtime Half'),
      content: const Text('Is this for the first or second half of a shift?'),
      actions: [
        TextButton(
          onPressed: onFirstHalf,
          child: const Text('First Half'),
        ),
        TextButton(
          onPressed: onSecondHalf,
          child: const Text('Second Half'),
        ),
      ],
    );
  }
}
