import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Presentation-only break and late-finish status picker.
///
/// Persistence and nested dialog navigation stay with the caller.
class BreakStatusDialog extends StatelessWidget {
  const BreakStatusDialog({
    super.key,
    required this.hasLateBreak,
    required this.tookFullBreak,
    required this.overtimeDurationMinutes,
    required this.hasLateFinish,
    required this.lateFinishDurationMinutes,
    required this.onRemoveBreak,
    required this.onFullBreak,
    required this.onOvertime,
    required this.onRemoveLateFinish,
    required this.onLateFinish,
  });

  final bool hasLateBreak;
  final bool tookFullBreak;
  final int? overtimeDurationMinutes;
  final bool hasLateFinish;
  final int? lateFinishDurationMinutes;
  final Future<void> Function() onRemoveBreak;
  final Future<void> Function() onFullBreak;
  final VoidCallback onOvertime;
  final Future<void> Function() onRemoveLateFinish;
  final VoidCallback onLateFinish;

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {
        'statusPadding': 10.0,
        'iconSize': 14.0,
        'spacing': 12.0,
      };
    } else if (screenWidth < 400) {
      return {
        'statusPadding': 11.0,
        'iconSize': 15.0,
        'spacing': 14.0,
      };
    }
    return {
      'statusPadding': 12.0,
      'iconSize': 16.0,
      'spacing': 16.0,
    };
  }

  Widget _statusCard({
    required BuildContext context,
    required Map<String, double> sizes,
    required String title,
    required IconData icon,
    required String body,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(sizes['statusPadding']!),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: sizes['iconSize'],
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  body,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 40.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: const Row(
        children: [
          Icon(Icons.access_time, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Break & Finish Status',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasLateBreak) ...[
              _statusCard(
                context: context,
                sizes: sizes,
                title: 'Current Status:',
                icon: tookFullBreak
                    ? Icons.free_breakfast
                    : Icons.monetization_on,
                body: tookFullBreak
                    ? 'Full Break Taken'
                    : 'Overtime ($overtimeDurationMinutes mins)',
              ),
              SizedBox(height: sizes['spacing']),
              const Divider(height: 1),
              SizedBox(height: sizes['spacing']),
            ],
            if (hasLateFinish) ...[
              _statusCard(
                context: context,
                sizes: sizes,
                title: 'Current Late Finish Status:',
                icon: Icons.schedule,
                body: 'Late Finish: $lateFinishDurationMinutes mins',
              ),
              SizedBox(height: sizes['spacing']),
              const Divider(height: 1),
              SizedBox(height: sizes['spacing']),
            ],
            Text(
              'Select an option:',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  if (hasLateBreak)
                    TextButton(
                      onPressed: () async => onRemoveBreak(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Remove'),
                    ),
                  if (!hasLateBreak)
                    TextButton(
                      onPressed: () async => onFullBreak(),
                      child: const Text('Full Break'),
                    ),
                  if (!hasLateBreak)
                    TextButton(
                      onPressed: onOvertime,
                      child: const Text('Overtime'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 8,
                children: [
                  if (hasLateFinish)
                    TextButton(
                      onPressed: () async => onRemoveLateFinish(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Remove Late Finish'),
                    ),
                  if (!hasLateFinish)
                    TextButton(
                      onPressed: onLateFinish,
                      child: const Text('Late Finish'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
