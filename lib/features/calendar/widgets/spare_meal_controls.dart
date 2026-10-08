import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/utils/spare_time_options.dart';

/// Spare-dialog controls to set or clear the 1-hour instructed break.
class SpareMealControls extends StatelessWidget {
  const SpareMealControls({
    super.key,
    required this.mealStart,
    required this.mealEnd,
    required this.onSet,
    required this.onClear,
  });

  final TimeOfDay? mealStart;
  final TimeOfDay? mealEnd;
  final VoidCallback onSet;
  final VoidCallback onClear;

  String _clock(TimeOfDay time) =>
      formatSpareClockTime(time.hour, time.minute);

  @override
  Widget build(BuildContext context) {
    final hasMeal = mealStart != null && mealEnd != null;
    final theme = Theme.of(context);
    final actionStyle = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.coffee,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasMeal
                    ? 'Break ${_clock(mealStart!)}–${_clock(mealEnd!)}'
                    : 'Take break',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: onSet,
              style: actionStyle,
              child: Text(hasMeal ? 'Change' : 'Set time'),
            ),
            if (hasMeal)
              TextButton(
                onPressed: onClear,
                style: actionStyle,
                child: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}
