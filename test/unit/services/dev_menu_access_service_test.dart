import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/services/dev_menu_access_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clear();
  });

  group('DevMenuAccessService', () {
    test('validates the existing Jamestown password', () {
      expect(DevMenuAccessService.isValidPassword('2113'), isTrue);
      expect(DevMenuAccessService.isValidPassword('wrong'), isFalse);
    });

    test('remembers access after a valid password', () async {
      expect(await DevMenuAccessService.unlockWithPassword('2113'), isTrue);
      expect(await DevMenuAccessService.isUnlocked(), isTrue);
      expect(
        await StorageService.getBool(AppConstants.devMenuUnlockedKey),
        isTrue,
      );
    });

    test('does not unlock after an invalid password', () async {
      expect(await DevMenuAccessService.unlockWithPassword('wrong'), isFalse);
      expect(await DevMenuAccessService.isUnlocked(), isFalse);
    });

    test('migrates a remembered Jamestown password', () async {
      await StorageService.saveBool(AppConstants.jamestownUnlockedKey, true);

      expect(await DevMenuAccessService.isUnlocked(), isTrue);
      expect(
        await StorageService.getBool(AppConstants.devMenuUnlockedKey),
        isTrue,
      );
    });

    test('migrates enabled Jamestown without changing its state', () async {
      await StorageService.saveBool(AppConstants.jamestownEnabledKey, true);

      expect(await DevMenuAccessService.isUnlocked(), isTrue);
      expect(
        await StorageService.getBool(AppConstants.jamestownEnabledKey),
        isTrue,
      );
      expect(
        await StorageService.getBool(AppConstants.devMenuUnlockedKey),
        isTrue,
      );
    });
  });
}
