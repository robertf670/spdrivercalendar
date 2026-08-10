import 'package:flutter/material.dart';
import 'package:spdrivercalendar/features/bills/screens/bills_screen.dart';
import 'package:spdrivercalendar/features/calendar/screens/week_view_screen.dart';
import 'package:spdrivercalendar/features/calendar/screens/year_view_screen.dart';
import 'package:spdrivercalendar/features/contacts/contacts_page.dart';
import 'package:spdrivercalendar/features/notes/screens/all_notes_screen.dart';
import 'package:spdrivercalendar/features/payscale/screens/payscale_screen.dart';
import 'package:spdrivercalendar/features/search/screens/search_screen.dart';
import 'package:spdrivercalendar/features/statistics/screens/statistics_screen.dart';
import 'package:spdrivercalendar/features/timing_points/screens/timing_points_screen.dart';
import 'package:spdrivercalendar/features/toilet_codes/screens/toilet_codes_screen.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/models/event.dart';
import 'package:spdrivercalendar/models/holiday.dart';
import 'package:spdrivercalendar/models/shift_info.dart';
import 'package:spdrivercalendar/screens/live_updates_details_screen.dart';

/// First day of the month for a year-view selection.
DateTime firstDayOfMonth(DateTime month) =>
    DateTime(month.year, month.month, 1);

/// Navigation helpers for secondary calendar destinations.
class CalendarFeatureNavigation {
  const CalendarFeatureNavigation._();

  static Future<void> openStatistics(
    BuildContext context, {
    required Map<DateTime, List<Event>> events,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatisticsScreen(events: events),
      ),
    );
  }

  static Future<void> openContacts(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContactsPage()),
    );
  }

  static Future<void> openNotes(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AllNotesScreen()),
    );
  }

  static Future<void> openBills(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BillsScreen()),
    );
  }

  static Future<void> openPayscale(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PayscaleScreen()),
    );
  }

  static Future<void> openTimingPoints(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TimingPointsScreen()),
    );
  }

  static Future<void> openToiletCodes(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ToiletCodesScreen()),
    );
  }

  static Future<void> openLiveUpdates(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LiveUpdatesDetailsScreen()),
    );
  }

  static Future<DateTime?> openSearch(BuildContext context) {
    return Navigator.of(context).push<DateTime>(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  static Future<void> openWeekView(
    BuildContext context, {
    required DateTime selectedDate,
    required Map<String, ShiftInfo> shiftInfoMap,
    required DateTime? startDate,
    required int startWeek,
    required List<BankHoliday>? bankHolidays,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeekViewScreen(
          selectedDate: selectedDate,
          shiftInfoMap: shiftInfoMap,
          startDate: startDate,
          startWeek: startWeek,
          bankHolidays: bankHolidays,
        ),
      ),
    );
  }

  static Future<DateTime?> openYearView(
    BuildContext context, {
    required int year,
    required Map<String, ShiftInfo> shiftInfoMap,
    required DateTime? startDate,
    required int startWeek,
    required List<Holiday> holidays,
    required List<BankHoliday>? bankHolidays,
    required bool markedInEnabled,
    required String markedInStatus,
  }) {
    return Navigator.of(context).push<DateTime>(
      MaterialPageRoute(
        builder: (_) => YearViewScreen(
          key: ValueKey('year_view_$year'),
          year: year,
          shiftInfoMap: shiftInfoMap,
          startDate: startDate,
          startWeek: startWeek,
          holidays: holidays,
          bankHolidays: bankHolidays,
          markedInEnabled: markedInEnabled,
          markedInStatus: markedInStatus,
        ),
      ),
    );
  }
}
