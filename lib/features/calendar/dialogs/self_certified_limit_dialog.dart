import 'package:flutter/material.dart';
import 'package:spdrivercalendar/services/self_certified_sick_days_service.dart';

/// Warns that a self-certified limit is reached, but still lets the user add.
class SelfCertifiedLimitDialog extends StatelessWidget {
  const SelfCertifiedLimitDialog({
    super.key,
    required this.warningMessage,
    required this.halfYearName,
    required this.halfYearCount,
    required this.yearlyCount,
  });

  final String warningMessage;
  final String halfYearName;
  final int halfYearCount;
  final int yearlyCount;

  static Future<bool> confirm(
    BuildContext context, {
    required String warningMessage,
    required String halfYearName,
    required int halfYearCount,
    required int yearlyCount,
  }) async {
    final addAnyway = await showDialog<bool>(
      context: context,
      builder: (context) => SelfCertifiedLimitDialog(
        warningMessage: warningMessage,
        halfYearName: halfYearName,
        halfYearCount: halfYearCount,
        yearlyCount: yearlyCount,
      ),
    );
    return addAnyway == true;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final theme = Theme.of(context);

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16.0 : 40.0,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Self-Certified Limit Reached',
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
            Text(warningMessage),
            const SizedBox(height: 12),
            Text(SelfCertifiedSickDaysService.bonusPeriodExplanation),
            const SizedBox(height: 16),
            Text(
              'Current usage:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('$halfYearName: $halfYearCount/2'),
            Text('Year total: $yearlyCount/4'),
          ],
        ),
      ),
      actions: [
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add anyway'),
            ),
          ],
        ),
      ],
    );
  }
}
