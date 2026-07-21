import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';

/// Controls access to the developer-only settings menu.
class DevMenuAccessService {
  static const String password = '2113';

  static bool isValidPassword(String input) => input == password;

  /// Returns whether this device can open the Dev Menu.
  ///
  /// Existing Jamestown users are migrated automatically so moving the toggle
  /// does not require them to enter the password again.
  static Future<bool> isUnlocked() async {
    if (await StorageService.getBool(AppConstants.devMenuUnlockedKey)) {
      return true;
    }

    final wasPreviouslyUnlocked =
        await StorageService.getBool(AppConstants.jamestownUnlockedKey);
    final jamestownAlreadyEnabled =
        await StorageService.getBool(AppConstants.jamestownEnabledKey);

    if (!wasPreviouslyUnlocked && !jamestownAlreadyEnabled) {
      return false;
    }

    await StorageService.saveBool(AppConstants.devMenuUnlockedKey, true);
    return true;
  }

  /// Validates and permanently remembers access on this device.
  static Future<bool> unlockWithPassword(String input) async {
    if (!isValidPassword(input)) {
      return false;
    }

    await StorageService.saveBool(AppConstants.devMenuUnlockedKey, true);
    return true;
  }
}
