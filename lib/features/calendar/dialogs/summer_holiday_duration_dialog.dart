import 'package:flutter/material.dart';

/// Chooses 1-week or 2-week summer holiday duration before year/date pickers.
class SummerHolidayDurationDialog extends StatelessWidget {
  const SummerHolidayDurationDialog({
    super.key,
    required this.onDurationSelected,
  });

  final ValueChanged<int> onDurationSelected;

  void _select(BuildContext context, int durationWeeks) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    onDurationSelected(durationWeeks);
  }

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {'titleFontSize': 14.0, 'optionTitleFontSize': 16.0};
    } else if (screenWidth < 400) {
      return {'titleFontSize': 15.0, 'optionTitleFontSize': 17.0};
    }
    return {'titleFontSize': 16.0, 'optionTitleFontSize': 18.0};
  }

  Widget _durationOption({
    required BuildContext context,
    required int durationWeeks,
    required String title,
    required String subtitle,
    required IconData icon,
    required double optionTitleFontSize,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _select(context, durationWeeks),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Theme.of(context).cardColor
                : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.orange.shade900.withValues(alpha: 0.5)
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: optionTitleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 12 : 24,
        vertical: 24,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.orange.shade900.withValues(alpha: 0.3)
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wb_sunny, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select Duration',
              style: TextStyle(
                fontSize: sizes['titleFontSize'],
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _durationOption(
              context: context,
              durationWeeks: 1,
              title: '1 Week',
              subtitle: 'Sunday to Saturday (7 days)',
              icon: Icons.calendar_view_week,
              optionTitleFontSize: sizes['optionTitleFontSize']!,
            ),
            const SizedBox(height: 12),
            _durationOption(
              context: context,
              durationWeeks: 2,
              title: '2 Weeks',
              subtitle: 'Sunday to Saturday (14 days)',
              icon: Icons.calendar_view_month,
              optionTitleFontSize: sizes['optionTitleFontSize']!,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
