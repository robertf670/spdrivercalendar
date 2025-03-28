import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
// Import keys for settings that might not be in AppConstants
import 'package:spdrivercalendar/features/settings/screens/settings_screen.dart' show kNotificationsEnabledKey, kNotificationOffsetHoursKey;

class BackupService {

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

      final String backupJson = jsonEncode(backupData);
      // Convert the JSON string to bytes using UTF-8 encoding
      final Uint8List backupBytes = utf8.encode(backupJson);

      // Ask user where to save the file, providing the bytes directly
      // saveFile returns null on mobile when bytes are provided and saving is successful.
      String? resultPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'spdrivercalendar_backup.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: backupBytes, // Pass the bytes directly
      );

      // On mobile, if bytes are provided, success is indicated by a null return value.
      // On desktop/web it might return a path, but for consistency we check if an error was thrown.
      // If we reach here without an exception, assume success.
      
      print("Backup save dialog completed."); // Log completion
      return true; // Assume success if no exception was thrown

    } catch (e) {
      print("Error creating backup: $e");
      // Check specifically for the error message we saw, though any error is a failure here.
      if (e.toString().contains('Bytes are required')) {
          print("Internal Error: Bytes were provided but still failed?");
      }
      return false;
    }
  }

  static Future<bool> restoreBackup() async {
    try {
      // Ask user to pick the backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup File',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        print("Restore cancelled by user.");
        return false; // User cancelled the picker
      }

      final String filePath = result.files.single.path!;
      final file = File(filePath);

      if (!await file.exists()) {
        print("Selected backup file does not exist: $filePath");
        return false;
      }

      // Read the JSON data from the file
      final String backupJson = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(backupJson);

      final prefs = await SharedPreferences.getInstance();

      // Restore data into SharedPreferences
      for (String key in backupData.keys) {
        // Only restore keys we expect (optional, but safer)
        if (_backupKeys.contains(key)) { 
           final value = backupData[key];
           // Need to check the type and use the correct setter
           if (value is String) {
             await prefs.setString(key, value);
           } else if (value is int) {
             await prefs.setInt(key, value);
           } else if (value is double) {
             await prefs.setDouble(key, value);
           } else if (value is bool) {
             await prefs.setBool(key, value);
           } else if (value is List<String>) { // SharedPreferences supports List<String>
             await prefs.setStringList(key, value);
           } else if (value == null) {
             await prefs.remove(key); // Handle null values if necessary
           } else {
             print("Warning: Skipping unsupported type for key '$key': ${value.runtimeType}");
           }
        }
      }
      
      print("Restore successful from: $filePath");
      return true;

    } catch (e) {
      print("Error restoring backup: $e");
      return false;
    }
  }
} 