import 'package:flutter/material.dart';

/// Compact weekday toggle used by work-shift repeat-this-week UI.
class WeekdayRepeatDayToggle extends StatelessWidget {
  const WeekdayRepeatDayToggle({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isDisabled,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final toggleSize = screenWidth < 350 ? 32.0 : 36.0;
    final fontSize = screenWidth < 350 ? 12.0 : 14.0;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          width: toggleSize,
          height: toggleSize,
          decoration: BoxDecoration(
            color: isDisabled
                ? Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5)
                : (isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDisabled
                  ? Theme.of(context).dividerColor.withValues(alpha: 0.5)
                  : (isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isDisabled
                    ? Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5)
                    : (isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
