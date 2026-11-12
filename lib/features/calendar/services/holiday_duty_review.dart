import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/dialogs/cancel_holiday_day_dialog.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_day_exclusion_service.dart';
import 'package:spdrivercalendar/features/calendar/services/holiday_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/holiday_duty_overlap.dart';
import 'package:spdrivercalendar/services/annual_leave_service.dart';

/// After the changelog has closed, ask about duties already saved on a holiday.
///
/// Rest days are skipped. Does nothing when no work day has a duty on a holiday.
Future<void> reviewExistingHolidayDuties(
  BuildContext context, {
  bool Function(DateTime date)? isRestDay,
}) async {
  final alreadyReviewed = await StorageService.getBool(
    AppConstants.holidayDutyReviewKey,
    defaultValue: false,
  );
  if (alreadyReviewed) return;

  final holidays = await HolidayService.getHolidays();
  if (holidays.isEmpty) {
    await StorageService.saveBool(AppConstants.holidayDutyReviewKey, true);
    return;
  }

  final events = await EventService.getAllEvents();
  final dates = dutyDatesOnHolidays(
    holidays: holidays,
    events: events,
    isRestDay: isRestDay,
  );

  for (final date in dates) {
    if (!context.mounted) return;
    final current = await HolidayService.getHolidays();
    final covering =
        current.where((holiday) => holiday.containsDate(date)).toList();
    if (covering.isEmpty) continue;

    final creditsDayInLieu =
        await AnnualLeaveService.consumesAnnualLeaveOn(date);
    if (!context.mounted) return;

    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CancelHolidayDayDialog(
        date: date,
        holidays: covering,
        creditsDayInLieu: creditsDayInLieu,
      ),
    );
    if (remove == true) {
      await HolidayDayExclusionService().excludeDay(date);
    }
  }

  await StorageService.saveBool(AppConstants.holidayDutyReviewKey, true);
}
