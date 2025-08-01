import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
// Import keys for settings that might not be in AppConstants
import 'package:spdrivercalendar/features/settings/screens/settings_screen.dart' show kNotificationsEnabledKey, kNotificationOffsetHoursKey;
import 'package:path_provider/path_provider.dart'; // Added for auto-backup
import 'package:spdrivercalendar/services/color_customization_service.dart';

class BackupService {
  // --- Auto-Backup Configuration ---
  static const String _autoBackupDirName = 'autobackups';
  static const int _maxAutoBackups = 5; // Keep the last 5 auto-backups
  // --- End Auto-Backup Configuration ---

  // List all SharedPreferences keys to back up
  static final List<String> _backupKeys = [
    AppConstants.eventsStorageKey,       // Events data
    'holidays',                          // Holiday data (ASSUMED KEY - PLEASE VERIFY/CHANGE)
    AppConstants.startDateKey,           // Roster start date
    AppConstants.startWeekKey,           // Roster start week
    AppConstants.isDarkModeKey,          // Dark mode setting
    AppConstants.syncToGoogleCalendarKey, // Google sync setting
    kNotificationsEnabledKey,            // Notification enabled setting
    kNotificationOffsetHoursKey,         // Notification offset setting
    // Add any other keys you want to back up here
    AppConstants.hasSeenWelcomeKey, // Example: Add welcome flag
    AppConstants.hasCompletedGoogleLoginKey // Example: Add google login flag
  ];

  static Future<bool> createBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> backupData = {};

      for (String key in _backupKeys) {
        backupData[key] = prefs.get(key);
      }

      // Add custom color data
      backupData.addAll(ColorCustomizationService.exportColors());

      final String backupJson = jsonEncode(backupData);
      // Convert the JSON string to bytes using UTF-8 encoding
      final Uint8List backupBytes = utf8.encode(backupJson);

      // Ask user where to save the file, providing the bytes directly
      // saveFile returns null on mobile when bytes are provided and saving is successful.
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'spdrivercalendar_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: backupBytes, // Pass the bytes directly
      );

      // On mobile, if bytes are provided, success is indicated by a null return value.
      // On desktop/web it might return a path, but for consistency we check if an error was thrown.
      // If we reach here without an exception, assume success.
      
      // Backup save dialog completed
      return true; // Assume success if no exception was thrown

    } catch (e) {

      // Check specifically for the error message we saw, though any error is a failure here.
      if (e.toString().contains('Bytes are required')) {

      }
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
        // Ensure we don't try to backup null if a key was added but not yet set.
        // JSON encoding null is fine, but good to be aware.
        if (value != null) {
          backupData[key] = value;
        } else {
          // Optionally log or handle missing keys if necessary

        }
      }

      // Add custom color data
      backupData.addAll(ColorCustomizationService.exportColors());

      final String backupJson = jsonEncode(backupData);
      final Uint8List backupBytes = utf8.encode(backupJson);

      final autoBackupDir = await _getAutoBackupDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = 'autobackup_$timestamp.json';
      final filePath = '${autoBackupDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(backupBytes);

      // Manage retention policy
      final files = autoBackupDir.listSync()
          .where((item) => item is File && item.path.endsWith('.json'))
          .map((item) => item as File)
          .toList();
          
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified)); // Sort by newest first

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

  static Future<List<File>> listAutoBackups() async {
    try {
      final autoBackupDir = await _getAutoBackupDirectory();
      final files = autoBackupDir.listSync()
          .where((item) => item is File && item.path.endsWith('.json') && item.path.contains('autobackup_'))
          .map((item) => item as File)
          .toList();
      // Sort by newest first
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
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
        // Ask user to pick the backup file (original manual restore behavior)
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          dialogTitle: 'Select Backup File',
          type: FileType.any, // Keep FileType.any
        );

        if (result == null || result.files.single.path == null) {

          return false; // User cancelled the picker
        }

        // Validate if the picked file is a .json file
        final pickedFile = result.files.single;
        if (!pickedFile.name.toLowerCase().contains('.json')) {

          // We can't show a SnackBar here, so we rely on returning false
          // and letting SettingsScreen handle the user notification.
          return false; // Indicate failure due to wrong file type
        }
        filePath = pickedFile.path!;
      }
      
      final file = File(filePath);

      if (!await file.exists()) {

        return false;
      }



      // Read the JSON data from the file
      final String backupJson = await file.readAsString();

      
      // Validate JSON structure
      if (backupJson.trim().isEmpty) {

        return false;
      }

      Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(backupJson);

      } catch (e) {

        return false;
      }

      if (backupData.isEmpty) {

        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      int restoredCount = 0;

      // Restore data into SharedPreferences
      for (String key in backupData.keys) {
        try {
          final value = backupData[key];

          
          // Check if it's a key we recognize (more flexible approach)
          bool shouldRestore = _backupKeys.contains(key) || 
                              key == 'holidays' || // Support legacy key
                              key.startsWith('notification') || // Support notification keys
                              key.startsWith('google') || // Support google keys
                              key.startsWith('events') || // Support events keys
                              key.startsWith('start') || // Support start date/week keys
                              key.startsWith('dark') ||  // Support dark mode
                              key.startsWith('welcome') || // Support welcome flags
                              key.startsWith('sync'); // Support sync settings
          
          if (shouldRestore) {
            // Need to check the type and use the correct setter
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
              // Try to convert to List<String> if possible
              try {
                final stringList = value.map((e) => e.toString()).toList();
                await prefs.setStringList(key, stringList);
                restoredCount++;

              } catch (e) {
                // Skip invalid list values
              }
            } else {
              // Skip unsupported value type
            }
          } else {
            // Skip unrecognized key
          }
        } catch (e) {
          // Skip problematic key
        }
      }
      
      // Import custom colors if present
      try {
        await ColorCustomizationService.importColors(backupData);

      } catch (e) {
        // Failed to import custom colors, continue
      }


      
      // Consider success if we restored at least some data
      if (restoredCount > 0) {

        return true;
      } else {

        return false;
      }

    } catch (e) {

      return false;
    }
  }
} 
