import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';
import 'package:spdrivercalendar/services/donnybrook_feature_service.dart';
import 'package:spdrivercalendar/services/jamestown_feature_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clear();
    await ShiftService.initialize();
  });

  group('DonnybrookFeatureService', () {
    test('selects CSV files using service-day rules', () {
      expect(
        DonnybrookFeatureService.resolveDutyCsvAsset(
          DateTime(2026, 7, 20),
        ),
        DonnybrookFeatureService.weekdayCsvAsset,
      );
      expect(
        DonnybrookFeatureService.resolveDutyCsvAsset(
          DateTime(2026, 7, 25),
        ),
        DonnybrookFeatureService.saturdayCsvAsset,
      );
      expect(
        DonnybrookFeatureService.resolveDutyCsvAsset(
          DateTime(2026, 7, 26),
        ),
        DonnybrookFeatureService.sundayCsvAsset,
      );
      expect(
        DonnybrookFeatureService.resolveDutyCsvAsset(
          DateTime(2026, 1, 1),
        ),
        DonnybrookFeatureService.sundayCsvAsset,
      );
      expect(
        DonnybrookFeatureService.resolveDutyCsvAsset(
          DateTime(2026, 12, 24),
        ),
        DonnybrookFeatureService.saturdayCsvAsset,
      );
    });

    test('loads duties from each day-specific file', () async {
      final weekdayDuties =
          await DonnybrookFeatureService.loadShiftCodesForDate(
        DateTime(2026, 7, 20),
      );
      final saturdayDuties =
          await DonnybrookFeatureService.loadShiftCodesForDate(
        DateTime(2026, 7, 25),
      );
      final sundayDuties =
          await DonnybrookFeatureService.loadShiftCodesForDate(
        DateTime(2026, 7, 26),
      );

      expect(weekdayDuties, contains('DZ1/69'));
      expect(saturdayDuties, contains('DZ1/56'));
      expect(sundayDuties, contains('DZ1/43'));
    });

    test('feature toggles are mutually exclusive', () async {
      await JamestownFeatureService.setEnabled(true);
      await DonnybrookFeatureService.setEnabled(true);

      expect(await DonnybrookFeatureService.isEnabled(), isTrue);
      expect(await JamestownFeatureService.isEnabled(), isFalse);

      await JamestownFeatureService.setEnabled(true);

      expect(await JamestownFeatureService.isEnabled(), isTrue);
      expect(await DonnybrookFeatureService.isEnabled(), isFalse);
    });
  });
}
