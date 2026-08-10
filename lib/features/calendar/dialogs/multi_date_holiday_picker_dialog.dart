import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/widgets/dialog_action_layout.dart';
import 'package:spdrivercalendar/features/calendar/widgets/multi_select_calendar.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Accent colors for [MultiDateHolidayPickerDialog] chrome (header / selection banner).
class MultiDateHolidayPickerAccent {
  const MultiDateHolidayPickerAccent({
    required this.iconColor,
    required this.confirmButtonColor,
    required this.headerBackgroundFor,
    required this.selectionBackgroundFor,
    required this.selectionForegroundFor,
  });

  final Color iconColor;
  final Color confirmButtonColor;
  final Color Function(bool isDark) headerBackgroundFor;
  final Color Function(bool isDark) selectionBackgroundFor;
  final Color Function(bool isDark) selectionForegroundFor;

  static MultiDateHolidayPickerAccent materialGreen() {
    return MultiDateHolidayPickerAccent(
      iconColor: Colors.green.shade400,
      confirmButtonColor: AppTheme.successColor,
      headerBackgroundFor: (isDark) => isDark
          ? Colors.green.shade900.withValues(alpha: 0.4)
          : Colors.green.shade50,
      selectionBackgroundFor: (isDark) => isDark
          ? Colors.green.shade900.withValues(alpha: 0.4)
          : Colors.green.shade50,
      selectionForegroundFor: (isDark) =>
          isDark ? Colors.green.shade300 : Colors.green.shade700,
    );
  }

  static MultiDateHolidayPickerAccent materialPurple() {
    return MultiDateHolidayPickerAccent(
      iconColor: Colors.purple.shade400,
      confirmButtonColor: const Color(0xFF8E24AA),
      headerBackgroundFor: (isDark) => isDark
          ? Colors.purple.shade900.withValues(alpha: 0.4)
          : Colors.purple.shade50,
      selectionBackgroundFor: (isDark) => isDark
          ? Colors.purple.shade900.withValues(alpha: 0.4)
          : Colors.purple.shade50,
      selectionForegroundFor: (isDark) =>
          isDark ? Colors.purple.shade300 : Colors.purple.shade700,
    );
  }

  /// Solid accent used by Day In Lieu (custom shift color).
  static MultiDateHolidayPickerAccent solid(Color color) {
    return MultiDateHolidayPickerAccent(
      iconColor: color,
      confirmButtonColor: color,
      headerBackgroundFor: (_) => color.withValues(alpha: 0.1),
      selectionBackgroundFor: (_) => color.withValues(alpha: 0.1),
      selectionForegroundFor: (_) => color,
    );
  }
}

/// Multi-date holiday picker shared by Other / Unpaid / Day In Lieu.
///
/// Persistence stays with the caller via [onConfirm]. Returns the value from
/// [onConfirm] when the dialog is closed after a successful confirm.
class MultiDateHolidayPickerDialog<T> extends StatefulWidget {
  const MultiDateHolidayPickerDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.confirmLabelSingular,
    required this.confirmLabelPlural,
    required this.onConfirm,
    this.topContent,
  });

  final String title;
  final IconData icon;
  final MultiDateHolidayPickerAccent accent;
  final String confirmLabelSingular;
  final String confirmLabelPlural;
  final Future<T> Function(List<DateTime> sortedDates) onConfirm;
  final Widget? topContent;

  @override
  State<MultiDateHolidayPickerDialog<T>> createState() =>
      _MultiDateHolidayPickerDialogState<T>();
}

class _MultiDateHolidayPickerDialogState<T>
    extends State<MultiDateHolidayPickerDialog<T>> {
  final Set<DateTime> _selectedDates = {};
  DateTime _currentMonth = DateTime.now();
  bool _isSaving = false;

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {
        'padding': 12.0,
        'titleFontSize': 16.0,
        'monthFontSize': 15.0,
      };
    } else if (screenWidth < 400) {
      return {
        'padding': 14.0,
        'titleFontSize': 18.0,
        'monthFontSize': 16.0,
      };
    }
    return {
      'padding': 16.0,
      'titleFontSize': 20.0,
      'monthFontSize': 18.0,
    };
  }

  void _toggleDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    setState(() {
      if (_selectedDates.contains(normalized)) {
        _selectedDates.remove(normalized);
      } else {
        _selectedDates.add(normalized);
      }
    });
  }

  Future<void> _handleConfirm() async {
    if (_selectedDates.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final sorted = _selectedDates.toList()..sort();
      final result = await widget.onConfirm(sorted);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _getResponsiveSizes(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;
    final padding = sizes['padding']!;

    final maxDialogHeight = screenHeight * (screenWidth < 350 ? 0.9 : 0.8);
    final verticalInset = screenWidth < 350 ? 12.0 : 24.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 12 : 24,
        vertical: verticalInset,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dialogHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight.clamp(0.0, maxDialogHeight)
              : maxDialogHeight;
          final dialogWidth = screenWidth < 600
              ? constraints.maxWidth
              : 500.0;

          return SizedBox(
            height: dialogHeight,
            width: dialogWidth,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.headerBackgroundFor(isDark),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: accent.iconColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: sizes['titleFontSize'],
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _isSaving
                            ? null
                            : () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (widget.topContent != null) widget.topContent!,
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: padding),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          _currentMonth = DateTime(
                                            _currentMonth.year,
                                            _currentMonth.month - 1,
                                          );
                                        });
                                      },
                              ),
                              Flexible(
                                child: Text(
                                  DateFormat('MMMM yyyy').format(_currentMonth),
                                  style: TextStyle(
                                    fontSize: sizes['monthFontSize'],
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _isSaving
                                    ? null
                                    : () {
                                        setState(() {
                                          _currentMonth = DateTime(
                                            _currentMonth.year,
                                            _currentMonth.month + 1,
                                          );
                                        });
                                      },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 0),
                        Padding(
                          padding: EdgeInsets.all(padding),
                          child: MultiSelectCalendar(
                            currentMonth: _currentMonth,
                            selectedDates: _selectedDates,
                            onDateTapped: _toggleDate,
                          ),
                        ),
                        if (_selectedDates.isNotEmpty) ...[
                          const Divider(height: 0),
                          Padding(
                            padding: EdgeInsets.all(padding),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accent.selectionBackgroundFor(isDark),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color:
                                        accent.selectionForegroundFor(isDark),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_selectedDates.length} day${_selectedDates.length == 1 ? '' : 's'} selected',
                                      style: TextStyle(
                                        color: accent
                                            .selectionForegroundFor(isDark),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 0),
                dialogFooterActions(
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: _selectedDates.isEmpty || _isSaving
                          ? null
                          : _handleConfirm,
                      style: dialogAccentElevatedStyle(
                        context,
                        accent.confirmButtonColor,
                      ),
                      child: Text(
                        _selectedDates.length == 1
                            ? widget.confirmLabelSingular
                            : widget.confirmLabelPlural,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Balance / warning strip shown above the Day In Lieu date picker.
class DayInLieuBalanceHeader extends StatelessWidget {
  const DayInLieuBalanceHeader({
    super.key,
    required this.used,
    required this.remaining,
  });

  final int used;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final hasZeroBalance = remaining == 0;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final padding = screenWidth < 350 ? 12.0 : 16.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Remaining',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$remaining',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasZeroBalance ? Colors.orange : null,
                          ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Used',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$used',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (hasZeroBalance)
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 8, padding, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warning: You have no days in lieu remaining. Make sure to add days when you earn them in Settings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
