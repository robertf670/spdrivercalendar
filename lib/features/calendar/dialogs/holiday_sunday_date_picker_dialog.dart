import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Sunday start-date list for winter/summer holiday booking.
///
/// Persistence stays with the caller via [onConfirm]. [onBack] is invoked after
/// the dialog is popped (Change Year / title back).
class HolidaySundayDatePickerDialog extends StatelessWidget {
  const HolidaySundayDatePickerDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.sundays,
    required this.loadHasHolidayFlags,
    required this.onConfirm,
    required this.onBack,
    this.endPreviewFor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final MaterialColor accent;
  final List<DateTime> sundays;
  final Future<List<bool>> Function() loadHasHolidayFlags;
  final Future<void> Function(DateTime sunday) onConfirm;
  final VoidCallback onBack;

  /// Optional secondary line under the start date (summer preview).
  final DateTime? Function(DateTime sunday)? endPreviewFor;

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (screenWidth < 350) {
      return {
        'titleFontSize': 14.0,
        'listHeight': (screenHeight * 0.45).clamp(220.0, 360.0),
      };
    } else if (screenWidth < 400) {
      return {
        'titleFontSize': 15.0,
        'listHeight': (screenHeight * 0.48).clamp(240.0, 380.0),
      };
    }
    return {
      'titleFontSize': 16.0,
      'listHeight': (screenHeight * 0.5).clamp(250.0, 400.0),
    };
  }

  Future<void> _handleConfirm(BuildContext context, DateTime date) async {
    await onConfirm(date);
    if (!context.mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    onBack();
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listHeight = sizes['listHeight']!;

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
                  ? accent.shade900.withValues(alpha: 0.3)
                  : accent.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: sizes['titleFontSize'],
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => _handleBack(context),
            tooltip: 'Change year',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.only(top: 8, bottom: 0),
      content: FutureBuilder<List<bool>>(
        future: loadHasHolidayFlags(),
        builder: (context, snapshot) {
          final hasHolidayFlags =
              snapshot.data ?? List.filled(sundays.length, false);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).cardColor
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Theme.of(context).dividerColor
                        : Colors.grey.shade200,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: double.maxFinite,
                  height: listHeight,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sundays.length,
                    itemBuilder: (context, index) {
                      final date = sundays[index];
                      final alreadyHasHoliday = hasHolidayFlags[index];
                      final endPreview = endPreviewFor?.call(date);

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (alreadyHasHoliday
                                  ? Theme.of(context)
                                      .cardColor
                                      .withValues(alpha: 0.5)
                                  : Theme.of(context).cardColor)
                              : (alreadyHasHoliday
                                  ? Colors.grey.shade100
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? (alreadyHasHoliday
                                    ? Theme.of(context).dividerColor
                                    : accent.shade700)
                                : (alreadyHasHoliday
                                    ? Colors.grey.shade300
                                    : accent.shade100),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: alreadyHasHoliday
                                ? null
                                : () => _handleConfirm(context, date),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? (alreadyHasHoliday
                                              ? Theme.of(context).dividerColor
                                              : accent.shade900
                                                  .withValues(alpha: 0.3))
                                          : (alreadyHasHoliday
                                              ? Colors.grey.shade300
                                              : accent.shade50),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Sun',
                                      style: TextStyle(
                                        color: isDark
                                            ? (alreadyHasHoliday
                                                ? Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color
                                                : accent.shade300)
                                            : (alreadyHasHoliday
                                                ? Colors.grey.shade600
                                                : accent.shade700),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('MMM d, yyyy')
                                              .format(date),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark
                                                ? Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color
                                                : (alreadyHasHoliday
                                                    ? Colors.grey.shade600
                                                    : Colors.black87),
                                          ),
                                        ),
                                        if (endPreview != null)
                                          Text(
                                            'Ends: ${DateFormat('MMM d, yyyy').format(endPreview)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        if (alreadyHasHoliday)
                                          Text(
                                            'Already added',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withValues(alpha: 0.7),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (!alreadyHasHoliday)
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: accent.shade300,
                                    )
                                  else
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe,
                    size: 16,
                    color: isDark
                        ? Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.6)
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Scroll to see more dates',
                      style: TextStyle(
                        color: isDark
                            ? Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.7)
                            : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        if (screenWidth < 350) ...[
          TextButton(
            onPressed: () => _handleBack(context),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? accent.shade300 : accent.shade700,
            ),
            child: const Text('Change Year'),
          ),
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            child: const Text('Cancel'),
          ),
        ] else ...[
          TextButton.icon(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Change Year'),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? accent.shade300 : accent.shade700,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ],
    );
  }
}
