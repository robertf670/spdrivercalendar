import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/utils/jamestown_december_bank_holiday.dart';
import 'package:spdrivercalendar/features/calendar/utils/marked_in_status.dart';
import 'package:spdrivercalendar/models/bank_holiday.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

/// Whether the signed-in driver should see 28 December 2026 as a bank holiday.
class JamestownDecemberBankHolidayGate {
  JamestownDecemberBankHolidayGate._();

  static bool devMenuEnabled = false;
  static bool markedInJamestown = false;

  static void resetForTest() {
    devMenuEnabled = false;
    markedInJamestown = false;
  }

  static bool get applies => JamestownDecemberBankHoliday.qualifies(
        devMenuEnabled: devMenuEnabled,
        markedInJamestown: markedInJamestown,
      );

  static BankHoliday? forDate(DateTime date) {
    if (!applies || !JamestownDecemberBankHoliday.isDate(date)) return null;
    return JamestownDecemberBankHoliday.holiday();
  }

  static Future<void> refreshFlags() async {
    devMenuEnabled = await JamestownFeatureService.isEnabled();
    final markedInEnabled = await StorageService.getBool(
      AppConstants.markedInEnabledKey,
    );
    final status =
        await StorageService.getString(AppConstants.markedInStatusKey) ?? '';
    markedInJamestown =
        markedInEnabled && status == MarkedInStatus.jamestown;
  }
}
