import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/settings/screens/settings_screen.dart'
    show kNotificationsEnabledKey, kNotificationOffsetHoursKey;
import 'package:spdrivercalendar/services/backup/backup_models.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';
import 'package:spdrivercalendar/services/bank_holiday_redundant_day_service.dart';
import 'package:spdrivercalendar/services/day_note_service.dart';

/// Web implementation of BackupService.
/// Auto-backup is a no-op (shared_preferences is source of truth).
/// Manual backup uses share/download; restore uses file picker bytes.
class BackupService {
  static final List<String> _backupKeys = [
    AppConstants.eventsStorageKey,
    AppConstants.dayNotesStorageKey,
    'holidays',
    AppConstants.startDateKey,
    AppConstants.startWeekKey,
    AppConstants.isDarkModeKey,
    AppConstants.syncToGoogleCalendarKey,
    AppConstants.includeBusAssignmentsInGoogleCalendarKey,
    AppConstants.includeBustimesLinksInGoogleCalendarKey,
    kNotificationsEnabledKey,
    kNotificationOffsetHoursKey,
    AppConstants.hasSeenWelcomeKey,
    AppConstants.hasCompletedGoogleLoginKey,
    AppConstants.restDaySwapsKey,
    AppConstants.bankHolidayRedundantDaysKey,
  ];

  static Future<bool> createBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> backupData = {};

      for (String key in _backupKeys) {
        backupData[key] = prefs.get(key);
      }
      backupData.addAll(ColorCustomizationService.exportColors());

      final String backupJson = jsonEncode(backupData);
      final bytes = utf8.encode(backupJson);

      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'spdrivercalendar_backup.json', mimeType: 'application/json')],
        text: 'Backup file',
        subject: 'SP Driver Calendar Backup',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// No-op on Web: data is always in shared_preferences (save-on-change).
  static Future<bool> createAutoBackup() async {
    return true;
  }

  /// Web has no file-based auto-backups.
  static Future<List<BackupEntry>> listAutoBackups() async {
    return [];
  }

  static Future<bool> restoreBackup({String? filePathToRestore}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup File',
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return false;

      final pickedFile = result.files.single;
      if (!pickedFile.name.toLowerCase().contains('.json')) return false;

      List<int>? bytes = pickedFile.bytes;
      if (bytes == null || bytes.isEmpty) return false;

      final String backupJson = utf8.decode(bytes);
      if (backupJson.trim().isEmpty) return false;

      Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(backupJson);
      } catch (e) {
        return false;
      }
      if (backupData.isEmpty) return false;

      return await _applyBackupData(backupData);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _applyBackupData(Map<String, dynamic> backupData) async {
    final prefs = await SharedPreferences.getInstance();
    int restoredCount = 0;

    for (String key in backupData.keys) {
      try {
        final value = backupData[key];
        bool shouldRestore = _backupKeys.contains(key) ||
            key == 'holidays' ||
            key.startsWith('notification') ||
            key.startsWith('google') ||
            key.startsWith('events') ||
            key.startsWith('start') ||
            key.startsWith('dark') ||
            key.startsWith('welcome') ||
            key.startsWith('sync') ||
            key.startsWith('restDay');

        if (shouldRestore && value != null) {
          if (value is String) {
            await prefs.setString(key, value);
            restoredCount++;
          } else if (value is int) {
            await prefs.setInt(key, value);
            restoredCount++;
          } else if (value is double) {
            await prefs.setDouble(key, value);
            restoredCount++;
          } else if (value is bool) {
            await prefs.setBool(key, value);
            restoredCount++;
          } else if (value is List) {
            try {
              final stringList = value.map((e) => e.toString()).toList();
              await prefs.setStringList(key, stringList);
              restoredCount++;
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    try {
      await ColorCustomizationService.importColors(backupData);
    } catch (_) {}

    if (restoredCount > 0) {
      DayNoteService.invalidateCache();
      BankHolidayRedundantDayService.invalidateCache();
      return true;
    }
    return false;
  }
}
