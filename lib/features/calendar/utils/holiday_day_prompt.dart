import 'package:intl/intl.dart';
import 'package:spdrivercalendar/features/calendar/utils/events_for_day.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_day_exclusion.dart';
import 'package:spdrivercalendar/models/holiday.dart';

class HolidayDayPromptCopy {
  const HolidayDayPromptCopy({
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;
}

HolidayDayPromptCopy holidayDayPromptCopy({
  required DateTime date,
  required List<Holiday> holidays,
  required bool creditsDayInLieu,
}) {
  final dayLabel = DateFormat('EEEE d MMM').format(date);
  final singleDay = holidays.isNotEmpty && holidays.every(holidayIsSingleDay);
  final names = holidays.map((holiday) => holidayTitleForType(holiday.type)).toList();
  final name = names.isEmpty
      ? 'Holiday'
      : names.length == 1
          ? names.single
          : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';

  final lines = <String>[];
  if (singleDay) {
    lines.add('$dayLabel is a $name. Cancel it?');
  } else {
    final ranged = holidays.where((holiday) => !holidayIsSingleDay(holiday)).toList();
    final span = ranged.isEmpty ? holidays.first : ranged.first;
    final start = DateFormat('d MMM').format(span.startDate);
    final end = DateFormat('d MMM').format(span.endDate);
    lines.add(
      '$dayLabel is part of your $name ($start – $end). The rest of that week stays booked.',
    );
  }
  if (creditsDayInLieu) {
    lines.add('This day is kept as a day in lieu.');
  }

  return HolidayDayPromptCopy(
    title: singleDay ? 'Cancel holiday?' : 'Remove this day?',
    body: lines.join(' '),
    confirmLabel: singleDay ? 'Cancel holiday' : 'Remove this day',
  );
}
