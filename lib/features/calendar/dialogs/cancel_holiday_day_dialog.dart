import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/widgets/dialog_insets.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_day_prompt.dart';
import 'package:spdrivercalendar/models/holiday.dart';

/// Asks whether a duty added on a holiday should clear that holiday day.
class CancelHolidayDayDialog extends StatelessWidget {
  const CancelHolidayDayDialog({
    super.key,
    required this.date,
    required this.holidays,
    required this.creditsDayInLieu,
  });

  final DateTime date;
  final List<Holiday> holidays;
  final bool creditsDayInLieu;

  @override
  Widget build(BuildContext context) {
    final copy = holidayDayPromptCopy(
      date: date,
      holidays: holidays,
      creditsDayInLieu: creditsDayInLieu,
    );
    final screenWidth = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: dialogHorizontalInset(context),
        vertical: screenWidth < 350 ? 16.0 : 24.0,
      ),
      title: Text(copy.title),
      content: Text(copy.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep holiday'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(copy.confirmLabel),
        ),
      ],
    );
  }
}
