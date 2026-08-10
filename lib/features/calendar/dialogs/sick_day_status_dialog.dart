import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/utils/sick_day_display.dart';

/// Presentation-only sick-day status picker.
///
/// Persistence and self-certified limit checks stay with the caller.
class SickDayStatusDialog extends StatelessWidget {
  const SickDayStatusDialog({
    super.key,
    required this.currentSickDayType,
    required this.onClear,
    required this.onSelectNormal,
    required this.onSelectSelfCertified,
    required this.onSelectForceMajeure,
  });

  final String? currentSickDayType;
  final Future<void> Function() onClear;
  final Future<void> Function() onSelectNormal;
  final Future<void> Function() onSelectSelfCertified;
  final Future<void> Function() onSelectForceMajeure;

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

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final theme = Theme.of(context);
    final hasCurrentStatus = currentSickDayType != null;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 40.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: const Row(
        children: [
          Icon(Icons.medical_services, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sick Day Status',
              maxLines: 2,
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
            if (hasCurrentStatus) ...[
              Container(
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
                      'Current Status:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: sizes['iconSize'],
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            SickDayDisplay.typeLabel(currentSickDayType!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: sizes['spacing']),
              const Divider(height: 1),
              SizedBox(height: sizes['spacing']),
            ],
            Text(
              'Select sick day type:',
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
                  if (hasCurrentStatus)
                    TextButton(
                      onPressed: () async => onClear(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Clear'),
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
                  TextButton(
                    onPressed: () async => onSelectNormal(),
                    child: const Text('Normal Sick'),
                  ),
                  TextButton(
                    onPressed: () async => onSelectSelfCertified(),
                    child: const Text('Self-Certified'),
                  ),
                  TextButton(
                    onPressed: () async => onSelectForceMajeure(),
                    child: const Text('Force Majeure'),
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
