import 'package:flutter/material.dart';

/// Presentation-only "Add Event" type picker.
///
/// Persistence and follow-on dialogs stay with the caller.
class AddEventTypeDialog extends StatelessWidget {
  const AddEventTypeDialog({
    super.key,
    required this.showBankHolidaySection,
    required this.hasWorkShiftOnDay,
    required this.isDayOnlyRedundant,
    required this.showWorkForOthers,
    required this.showSwapRestDay,
    required this.onToggleDayOnlyRedundant,
    required this.onNormalEvent,
    required this.onWorkShift,
    required this.onOvertime,
    required this.onWorkForOthers,
    required this.onSwapRestDay,
  });

  final bool showBankHolidaySection;
  final bool hasWorkShiftOnDay;
  final bool isDayOnlyRedundant;
  final bool showWorkForOthers;
  final bool showSwapRestDay;
  final Future<void> Function(bool marked) onToggleDayOnlyRedundant;
  final VoidCallback onNormalEvent;
  final VoidCallback onWorkShift;
  final VoidCallback onOvertime;
  final VoidCallback onWorkForOthers;
  final VoidCallback onSwapRestDay;

  Map<String, double> _getResponsiveSizes(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 350) {
      return {
        'disclaimerPadding': 8.0,
        'iconSize': 16.0,
        'spacing': 12.0,
        'fontSize': 11.0,
      };
    } else if (screenWidth < 400) {
      return {
        'disclaimerPadding': 9.0,
        'iconSize': 17.0,
        'spacing': 14.0,
        'fontSize': 11.5,
      };
    }
    return {
      'disclaimerPadding': 10.0,
      'iconSize': 18.0,
      'spacing': 16.0,
      'fontSize': 12.0,
    };
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
      title: const Text('Add Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(sizes['disclaimerPadding']!),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: sizes['iconSize'],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'The duty information in this app is taken from the bills provided in the depot. There may be mistakes at times.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: sizes['fontSize'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sizes['spacing']),
            const Text('What type of event would you like to add?'),
            if (showBankHolidaySection) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _BankHolidayRedundantSection(
                hasWorkShiftOnDay: hasWorkShiftOnDay,
                isDayOnlyRedundant: isDayOnlyRedundant,
                onToggleDayOnlyRedundant: onToggleDayOnlyRedundant,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onNormalEvent,
          child: const Text('Normal Event'),
        ),
        TextButton(
          onPressed: onWorkShift,
          child: const Text('Work Shift'),
        ),
        TextButton(
          onPressed: onOvertime,
          child: const Text('Overtime'),
        ),
        if (showWorkForOthers)
          TextButton(
            onPressed: onWorkForOthers,
            child: const Text('Work For Others'),
          ),
        if (showSwapRestDay)
          TextButton(
            onPressed: onSwapRestDay,
            child: const Text('Swap Rest Day'),
          ),
      ],
    );
  }
}

class _BankHolidayRedundantSection extends StatefulWidget {
  const _BankHolidayRedundantSection({
    required this.hasWorkShiftOnDay,
    required this.isDayOnlyRedundant,
    required this.onToggleDayOnlyRedundant,
  });

  final bool hasWorkShiftOnDay;
  final bool isDayOnlyRedundant;
  final Future<void> Function(bool marked) onToggleDayOnlyRedundant;

  @override
  State<_BankHolidayRedundantSection> createState() =>
      _BankHolidayRedundantSectionState();
}

class _BankHolidayRedundantSectionState
    extends State<_BankHolidayRedundantSection> {
  late bool _dayOnly;

  @override
  void initState() {
    super.initState();
    _dayOnly = widget.isDayOnlyRedundant;
  }

  @override
  void didUpdateWidget(covariant _BankHolidayRedundantSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDayOnlyRedundant != widget.isDayOnlyRedundant) {
      _dayOnly = widget.isDayOnlyRedundant;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasWorkShiftOnDay) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        isThreeLine: true,
        leading: Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Bank holiday redundant'),
        subtitle: const Text(
          'You have a work shift. Open the shift, then Edit, and use the "Bank holiday — redundant" switch on that event.',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Bank holiday redundant (day off)'),
      subtitle: const Text(
        'No work shift in the app. Mark this bank holiday as redundant (off).',
        style: TextStyle(fontSize: 12),
      ),
      value: _dayOnly,
      onChanged: (value) async {
        await widget.onToggleDayOnlyRedundant(value);
        if (!mounted) return;
        setState(() {
          _dayOnly = value;
        });
      },
    );
  }
}
