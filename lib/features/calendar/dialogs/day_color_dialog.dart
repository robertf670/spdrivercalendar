import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/utils/day_color_swatches.dart';

class DayColorResult {
  const DayColorResult.apply(this.color) : reset = false;
  const DayColorResult.reset()
      : color = null,
        reset = true;

  final Color? color;
  final bool reset;
}

/// Compact sheet to set or clear a one-day colour override.
class DayColorDialog extends StatelessWidget {
  const DayColorDialog({
    super.key,
    required this.date,
    this.currentOverride,
    this.initialColor,
  });

  final DateTime date;
  final Color? currentOverride;
  final Color? initialColor;

  static Future<DayColorResult?> show(
    BuildContext context, {
    required DateTime date,
    Color? currentOverride,
    Color? initialColor,
  }) {
    return showModalBottomSheet<DayColorResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DayColorDialog(
        date: date,
        currentOverride: currentOverride,
        initialColor: initialColor,
      ),
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    var selected = currentOverride ?? initialColor ?? Colors.teal;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenWidth < 350 ? 16.0 : 40.0,
            vertical: screenWidth < 350 ? 16.0 : 24.0,
          ),
          title: const Text('Custom colour'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selected,
              onColorChanged: (color) => selected = color,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
            ),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Use colour'),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(DayColorResult.apply(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final swatches = dayColorSwatches();
    final selectedArgb = currentOverride?.toARGB32();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Day colour',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEE d MMM yyyy').format(date),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in swatches)
                _SwatchButton(
                  key: ValueKey('day-color-swatch-${color.toARGB32()}'),
                  color: color,
                  selected: selectedArgb == color.toARGB32(),
                  onTap: () =>
                      Navigator.of(context).pop(DayColorResult.apply(color)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (currentOverride != null)
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(const DayColorResult.reset()),
                  child: const Text('Reset'),
                ),
              TextButton(
                onPressed: () => _pickCustom(context),
                child: const Text('Custom'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Day colour',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.5),
                width: selected ? 3 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
