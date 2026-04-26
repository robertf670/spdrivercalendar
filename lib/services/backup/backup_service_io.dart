import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/features/settings/screens/settings_screen.dart'
    show kNotificationsEnabledKey, kNotificationOffsetHoursKey;
import 'package:spdrivercalendar/services/backup/backup_models.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';
import 'package:spdrivercalendar/services/bank_holiday_redundant_day_service.dart';
import 'package:spdrivercalendar/services/day_note_service.dart';

class BackupService {
  static const String _autoBackupDirName = 'autobackups';
  static const int _maxAutoBackups = 5;

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
      final Uint8List backupBytes = utf8.encode(backupJson);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/spdrivercalendar_backup.json');
      await tempFile.writeAsBytes(backupBytes);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Backup file',
        subject: 'SP Driver Calendar Backup',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Directory> _getAutoBackupDirectory() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final autoBackupPath = '${appSupportDir.path}/$_autoBackupDirName';
    final autoBackupDir = Directory(autoBackupPath);
    if (!await autoBackupDir.exists()) {
      await autoBackupDir.create(recursive: true);
    }
    return autoBackupDir;
  }

  static Future<bool> createAutoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> backupData = {};

      for (String key in _backupKeys) {
        final value = prefs.get(key);
        if (value != null) backupData[key] = value;
      }
      backupData.addAll(ColorCustomizationService.exportColors());

      final String backupJson = jsonEncode(backupData);
      final Uint8List backupBytes = utf8.encode(backupJson);

      final autoBackupDir = await _getAutoBackupDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = 'autobackup_$timestamp.json';
      final filePath = '${autoBackupDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(backupBytes);

      final files = autoBackupDir
          .listSync()
          .where((item) => item is File && item.path.endsWith('.json'))
          .map((item) => item as File)
          .toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      if (files.length > _maxAutoBackups) {
        for (int i = _maxAutoBackups; i < files.length; i++) {
          await files[i].delete();
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<BackupEntry>> listAutoBackups() async {
    try {
      final autoBackupDir = await _getAutoBackupDirectory();
      final files = autoBackupDir
          .listSync()
          .where((item) =>
              item is File &&
              item.path.endsWith('.json') &&
              item.path.contains('autobackup_'))
          .map((item) => item as File)
          .toList();
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files
          .map((f) => BackupEntry(
                path: f.path,
                modified: f.statSync().modified.toLocal(),
                size: f.lengthSync(),
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> restoreBackup({String? filePathToRestore}) async {
    try {
      String? filePath;

      if (filePathToRestore != null) {
        filePath = filePathToRestore;
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Select Backup File',
          type: FileType.any,
        );
        if (result == null || result.files.isEmpty || result.files.single.path == null) {
          return false;
        }
        final pickedFile = result.files.single;
        if (!pickedFile.name.toLowerCase().contains('.json')) {
          return false;
        }
        filePath = pickedFile.path!;
      }

      final file = File(filePath);
      if (!await file.exists()) return false;

      final String backupJson = await file.readAsString();
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
