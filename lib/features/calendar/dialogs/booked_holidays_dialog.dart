import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_type_presentation.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';

/// Lists booked annual-leave or days-in-lieu holidays with delete actions.
///
/// Persistence stays with the caller via [onDeleteHoliday].
class BookedHolidaysDialog extends StatefulWidget {
  const BookedHolidaysDialog({
    super.key,
    required this.holidayType,
    required this.initialHolidays,
    required this.onDeleteHoliday,
  });

  /// `'annualLeave'` or `'daysInLieu'`.
  final String holidayType;
  final List<Holiday> initialHolidays;

  /// Removes the holiday and returns the refreshed booked list for this type.
  final Future<List<Holiday>> Function(Holiday holiday) onDeleteHoliday;

  @override
  State<BookedHolidaysDialog> createState() => _BookedHolidaysDialogState();
}

class _BookedHolidaysDialogState extends State<BookedHolidaysDialog> {
  late List<Holiday> _holidays;

  @override
  void initState() {
    super.initState();
    _holidays = List<Holiday>.from(widget.initialHolidays);
  }

  bool get _isAnnualLeave => widget.holidayType == 'annualLeave';

  String get _title =>
      _isAnnualLeave ? 'Booked Annual Leave' : 'Booked Days In Lieu';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxWidth = screenWidth < 600
        ? screenWidth * 0.95
        : screenWidth < 900
            ? screenWidth * 0.85
            : 600.0;
    final accent = _isAnnualLeave
        ? Theme.of(context).colorScheme.primary
        : ColorCustomizationService.getColorForShift('DAY_IN_LIEU');

    final horizontalInset = screenWidth < 350
        ? 12.0
        : screenWidth < 400
            ? 16.0
            : 40.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.7,
          maxWidth: maxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isAnnualLeave ? Icons.beach_access : Icons.event_available,
                    color: accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _title,
                      style: TextStyle(
                        fontSize: screenWidth < 350 ? 16.0 : 18.0,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            Flexible(
              child: _holidays.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No holidays booked yet.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _holidays.length,
                      itemBuilder: (context, index) {
                        final holiday = _holidays[index];
                        final presentation =
                            holidayTypePresentation(holiday.type);
                        final dateText = holiday.startDate == holiday.endDate
                            ? DateFormat('MMM d, yyyy')
                                .format(holiday.startDate)
                            : '${DateFormat('MMM d, yyyy').format(holiday.startDate)} - ${DateFormat('MMM d, yyyy').format(holiday.endDate)}';
                        final daysCount = holiday.endDate
                                .difference(holiday.startDate)
                                .inDays +
                            1;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).cardColor
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).dividerColor
                                    : Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: presentation.color
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      presentation.icon,
                                      color: presentation.color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          presentation.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          dateText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: presentation.color
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$daysCount ${daysCount == 1 ? 'day' : 'days'}',
                                      style: TextStyle(
                                        color: presentation.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _confirmAndDelete(
                                      context,
                                      holiday,
                                      presentation.label,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade400,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    Holiday holiday,
    String holidayTypeLabel,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text(
          'Are you sure you want to delete this ${holidayTypeLabel.toLowerCase()}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      final updated = await widget.onDeleteHoliday(holiday);
      if (!mounted) return;
      setState(() {
        _holidays
          ..clear()
          ..addAll(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Holiday removed successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (_holidays.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing holiday: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Empty-state dialog used when there are no booked holidays.
class EmptyBookedHolidaysDialog extends StatelessWidget {
  const EmptyBookedHolidaysDialog({
    super.key,
    required this.holidayType,
  });

  final String holidayType;

  @override
  Widget build(BuildContext context) {
    final title = holidayType == 'annualLeave'
        ? 'Booked Annual Leave'
        : 'Booked Days In Lieu';
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text('No holidays booked yet.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
