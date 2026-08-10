import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/calendar/widgets/holiday_balance_item.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';

/// Presentation dialog for holiday balances and add-type entry points.
///
/// Booking persistence and existing-holiday editing stay with the caller.
class AddHolidaysDialog extends StatefulWidget {
  const AddHolidaysDialog({
    super.key,
    required this.loadBalances,
    required this.hasExistingHolidays,
    required this.existingHolidaysSection,
    required this.onShowBookedAnnualLeave,
    required this.onShowBookedDaysInLieu,
    required this.onSummerHoliday,
    required this.onWinterHoliday,
    required this.onOtherHoliday,
    required this.onUnpaidLeave,
    required this.onDayInLieu,
  });

  final Future<Map<String, int>> Function() loadBalances;
  final bool hasExistingHolidays;
  final Widget existingHolidaysSection;
  final VoidCallback onShowBookedAnnualLeave;
  final VoidCallback onShowBookedDaysInLieu;
  final VoidCallback onSummerHoliday;
  final VoidCallback onWinterHoliday;
  final VoidCallback onOtherHoliday;
  final VoidCallback onUnpaidLeave;
  final VoidCallback onDayInLieu;

  @override
  State<AddHolidaysDialog> createState() => _AddHolidaysDialogState();
}

class _AddHolidaysDialogState extends State<AddHolidaysDialog> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _closeAndRun(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {
        'maxWidthFactor': 0.95,
        'sectionTitle': 11.0,
        'optionFont': 13.0,
      };
    }
    if (screenWidth < 600) {
      return {
        'maxWidthFactor': 0.95,
        'sectionTitle': 12.0,
        'optionFont': 14.0,
      };
    }
    if (screenWidth < 900) {
      return {
        'maxWidthFactor': 0.85,
        'sectionTitle': 13.0,
        'optionFont': 14.0,
      };
    }
    return {
      'maxWidthFactor': 0.0, // unused when fixed max width applies
      'sectionTitle': 13.0,
      'optionFont': 14.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxWidth = screenWidth < 600
        ? screenWidth * 0.95
        : screenWidth < 900
            ? screenWidth * 0.85
            : 600.0;

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
          maxHeight: screenHeight * 0.8,
          maxWidth: maxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 350 ? 12 : 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Holidays',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: widget.hasExistingHolidays,
                thickness: 6,
                radius: const Radius.circular(3),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FutureBuilder<Map<String, int>>(
                        future: widget.loadBalances(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          final balances = snapshot.data!;
                          final primaryColor =
                              Theme.of(context).colorScheme.primary;
                          final dayInLieuColor =
                              ColorCustomizationService.getColorForShift(
                            'DAY_IN_LIEU',
                          );
                          final sectionTitleSize = sizes['sectionTitle']!;

                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 350 ? 12 : 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                _balanceGroup(
                                  context,
                                  title: 'Annual Leave',
                                  titleSize: sectionTitleSize,
                                  today: balances['annualLeaveToday']!,
                                  remaining:
                                      balances['annualLeaveRemaining']!,
                                  booked: balances['annualLeaveBooked']!,
                                  accent: primaryColor,
                                  onBookedTap:
                                      widget.onShowBookedAnnualLeave,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 1,
                                  color: Theme.of(context)
                                      .dividerColor
                                      .withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 8),
                                _balanceGroup(
                                  context,
                                  title: 'Days In Lieu',
                                  titleSize: sectionTitleSize,
                                  today: balances['daysInLieuToday']!,
                                  remaining:
                                      balances['daysInLieuRemaining']!,
                                  booked: balances['daysInLieuBooked']!,
                                  accent: dayInLieuColor,
                                  onBookedTap: widget.onShowBookedDaysInLieu,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 350 ? 12 : 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Holiday',
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
                            _optionTile(
                              icon: Icons.wb_sunny,
                              label: 'Summer Holiday',
                              fontSize: sizes['optionFont']!,
                              onTap: () =>
                                  _closeAndRun(widget.onSummerHoliday),
                            ),
                            _optionTile(
                              icon: Icons.ac_unit,
                              label: 'Winter (1 Week)',
                              fontSize: sizes['optionFont']!,
                              onTap: () =>
                                  _closeAndRun(widget.onWinterHoliday),
                            ),
                            _optionTile(
                              icon: Icons.event,
                              label: 'Holiday',
                              fontSize: sizes['optionFont']!,
                              onTap: () =>
                                  _closeAndRun(widget.onOtherHoliday),
                            ),
                            _optionTile(
                              icon: Icons.money_off,
                              iconColor: Colors.purple,
                              label: 'Unpaid Leave',
                              fontSize: sizes['optionFont']!,
                              onTap: () =>
                                  _closeAndRun(widget.onUnpaidLeave),
                            ),
                            _optionTile(
                              icon: Icons.event_available,
                              iconColor:
                                  ColorCustomizationService.getColorForShift(
                                'DAY_IN_LIEU',
                              ),
                              label: 'Day In Lieu',
                              fontSize: sizes['optionFont']!,
                              onTap: () => _closeAndRun(widget.onDayInLieu),
                            ),
                          ],
                        ),
                      ),
                      if (widget.hasExistingHolidays) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 350 ? 12 : 16,
                            vertical: 12,
                          ),
                          child: widget.existingHolidaysSection,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceGroup(
    BuildContext context, {
    required String title,
    required double titleSize,
    required int today,
    required int remaining,
    required int booked,
    required Color accent,
    required VoidCallback onBookedTap,
  }) {
    final divider = Container(
      width: 1,
      height: 20,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
    );
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: HolidayBalanceItem(
                      label: 'Today',
                      value: today,
                      color: accent,
                    ),
                  ),
                  divider,
                  Expanded(
                    child: HolidayBalanceItem(
                      label: 'Remaining',
                      value: remaining,
                      color: accent,
                    ),
                  ),
                  divider,
                  Expanded(
                    child: HolidayBalanceItem(
                      label: 'Booked',
                      value: booked,
                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey,
                      onTap: onBookedTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required double fontSize,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
