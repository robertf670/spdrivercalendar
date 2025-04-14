import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/features/settings/screens/google_calendar_settings_screen.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spdrivercalendar/services/backup_service.dart';

// Define Preference Keys for Notifications (Consider moving to AppConstants if not already there)
const String kNotificationsEnabledKey = 'notificationsEnabled';
const String kNotificationOffsetHoursKey = 'notificationOffsetHours';

class SettingsScreen extends StatefulWidget {
  final VoidCallback resetRestDaysCallback;
  final ValueNotifier<bool> isDarkModeNotifier;

  const SettingsScreen({
    Key? key,
    required this.resetRestDaysCallback,
    required this.isDarkModeNotifier,
  }) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;
  bool _isGoogleSignedIn = false;
  String _googleAccount = '';
  bool _syncToGoogleCalendar = false;
  bool _isLoading = false;

  // Notification state variables
  bool _notificationsEnabled = false;
  int _notificationOffsetHours = 1; // Default offset

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkModeNotifier.value;
    _loadSettings();
    _checkGoogleSignIn();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance(); // Use SharedPreferences directly here
    final syncToGoogle = prefs.getBool(AppConstants.syncToGoogleCalendarKey) ?? false;
    final notificationsEnabled = prefs.getBool(kNotificationsEnabledKey) ?? false;
    final notificationOffset = prefs.getInt(kNotificationOffsetHoursKey) ?? 1;
    
    setState(() {
      _syncToGoogleCalendar = syncToGoogle;
      _notificationsEnabled = notificationsEnabled;
      _notificationOffsetHours = notificationOffset;
    });
  }

  Future<void> _checkGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final isSignedIn = await GoogleCalendarService.isSignedIn();
    final user = await GoogleCalendarService.getCurrentUser();

    setState(() {
      _isGoogleSignedIn = isSignedIn;
      _googleAccount = user?.email ?? '';
      _isLoading = false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    widget.isDarkModeNotifier.value = value;
    await StorageService.saveBool(AppConstants.isDarkModeKey, value);
  }

  Future<void> _toggleGoogleSync(bool value) async {
    setState(() {
      _syncToGoogleCalendar = value;
    });
    await StorageService.saveBool(AppConstants.syncToGoogleCalendarKey, value);
  }

  // --- Notification Preference Saving Methods ---
  Future<void> _saveNotificationsEnabled(bool enabled) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kNotificationsEnabledKey, enabled);
      setState(() {
        _notificationsEnabled = enabled;
      });
  }
  
  Future<void> _saveNotificationOffset(int hours) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kNotificationOffsetHoursKey, hours);
      setState(() {
        _notificationOffsetHours = hours;
      });
  }

  // --- Notification Toggle Method ---
  Future<void> _toggleNotificationsEnabled(bool value) async {
    if (value) {
      // Request permissions when enabling
      bool? permissionsGranted = await NotificationService().requestPermissions();
      if (permissionsGranted == true && mounted) {
         await _saveNotificationsEnabled(true);
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications enabled.')),
         );
      } else if (mounted) {
        // Permission denied or null (e.g., platform not supported)
         await _saveNotificationsEnabled(false); // Keep it disabled
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification permissions denied or unavailable.')),
         );
      }
    } else {
      // Just disable if turning off
      await _saveNotificationsEnabled(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications disabled.')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Appearance'),
          _buildDarkModeSwitch(),
          
          const Divider(height: 32),
          _buildSectionHeader('Google Calendar'),
          _buildGoogleAccountSection(),
          _buildGoogleSyncOption(),
          _buildManualSyncOption(),
          
          // --- Modify Notifications Section --- 
          const Divider(height: 32),
          _buildSectionHeader('Notifications'),
          // Add the warning message here
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Shift notifications are temporarily disabled due to technical issues. We are working on a fix.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error, // Use error color for warning
                //fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
              ),
            ),
          ),
          _buildNotificationsEnabledSwitch(), // This method will be modified below
          _buildNotificationOffsetDropdown(), // This method will be modified below
          _buildTestNotificationButton(), // This method will be modified below
          _buildViewPendingNotificationsButton(), // This method will be modified below
          // --- End Notifications Section --- 
          
          const Divider(height: 32),
          _buildSectionHeader('Schedule'),
          _buildResetRestDaysButton(),
          
          // --- Restore Backup & Restore section to original position ---
          const Divider(height: 32),
          _buildSectionHeader('Backup & Restore'),
          _buildBackupButton(),
          _buildRestoreButton(),
          // --- End Restored Section ---
          
          const Divider(height: 32),
          _buildSectionHeader('App'),
          _buildShowWelcomePageButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDarkModeSwitch() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Toggle dark mode theme'),
        secondary: Icon(
          _isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: _isDarkMode ? Colors.amber : Colors.blueGrey,
        ),
        value: _isDarkMode,
        onChanged: _toggleDarkMode,
      ),
    );
  }

  Widget _buildGoogleAccountSection() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Google Calendar'),
              SizedBox(height: 8),
              LinearProgressIndicator(),
            ],
          ),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _isGoogleSignedIn ? AppTheme.successColor : Colors.grey,
          child: Icon(
            _isGoogleSignedIn ? Icons.check : Icons.login,
            color: Colors.white,
          ),
        ),
        title: Text(_isGoogleSignedIn ? 'Google Calendar Connected' : 'Connect Google Calendar'),
        subtitle: Text(_isGoogleSignedIn ? _googleAccount : 'Sync your shifts with Google Calendar'),
        trailing: _isGoogleSignedIn
          ? IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: _handleGoogleSignOut,
            )
          : const Icon(Icons.chevron_right),
        onTap: _isGoogleSignedIn 
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoogleCalendarSettingsScreen()),
              )
            : _handleGoogleSignIn,
      ),
    );
  }

  Widget _buildGoogleSyncOption() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: SwitchListTile(
        title: const Text('Auto-sync to Google Calendar'),
        subtitle: const Text('Automatically add new events to Google Calendar'),
        secondary: const Icon(Icons.sync),
        value: _syncToGoogleCalendar,
        onChanged: _isGoogleSignedIn ? _toggleGoogleSync : null,
      ),
    );
  }

  Widget _buildManualSyncOption() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.sync),
        title: const Text('Manual Sync to Google'),
        subtitle: const Text('Check and upload missing events'),
        trailing: _isGoogleSignedIn ? const Icon(Icons.chevron_right) : null,
        enabled: _isGoogleSignedIn,
        onTap: _isGoogleSignedIn ? () => _showSyncDialog(context) : null,
      ),
    );
  }

  Widget _buildResetRestDaysButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.refresh),
        title: const Text('Reset Rest Days'),
        subtitle: const Text('Change your shift pattern'),
        onTap: widget.resetRestDaysCallback,
      ),
    );
  }

  Widget _buildShowWelcomePageButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Show Welcome Page'),
        subtitle: const Text('View app introduction'),
        onTap: () {
          Navigator.pushNamed(
            context, 
            '/welcome',
            arguments: true, // This indicates it's opened from settings
          );
        },
      ),
    );
  }

  Widget _buildNotificationsEnabledSwitch() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: SwitchListTile(
        title: const Text('Enable Shift Notifications'),
        subtitle: const Text('Get notified before your shift starts'),
        secondary: const Icon(
          Icons.notifications_off, // Force off icon
          color: Colors.grey, // Force grey
        ),
        value: false, // Force off value
        onChanged: null, // *** Disable the switch ***
      ),
    );
  }

  Widget _buildNotificationOffsetDropdown() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        enabled: false, // Disable the ListTile visually
        leading: const Icon(
          Icons.timer_outlined,
          color: Colors.grey, // Force grey
        ),
        title: const Text(
          'Notify Before Shift',
          style: TextStyle(color: Colors.grey), // Force grey text
        ),
        trailing: DropdownButton<int>(
          value: _notificationOffsetHours,
          onChanged: null, // *** Disable the dropdown ***
          items: <int>[1, 2, 4]
              .map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(
                 '$value hour${value > 1 ? 's' : ''}',
                 style: const TextStyle(color: Colors.grey), // Force grey item text
              ),
            );
          }).toList(),
          disabledHint: Text( // Show hint when disabled
             '$_notificationOffsetHours hour${_notificationOffsetHours > 1 ? 's' : ''}',
             style: const TextStyle(color: Colors.grey), 
          ),
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        enabled: false, // Disable the ListTile visually
        leading: const Icon(
          Icons.notification_important_outlined,
          color: Colors.grey, // Force grey
        ),
        title: const Text(
          'Test Notification',
          style: TextStyle(color: Colors.grey), // Force grey text
        ),
        trailing: ElevatedButton(
          onPressed: null, // *** Disable the button ***
          child: const Text('Send Test'),
          style: ElevatedButton.styleFrom(
             backgroundColor: Colors.grey[300],
             foregroundColor: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildViewPendingNotificationsButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        enabled: false, // Disable the ListTile visually
        leading: const Icon(
          Icons.pending_actions_outlined,
          color: Colors.grey, // Force grey
        ),
        title: const Text(
          'View Pending Notifications',
          style: TextStyle(color: Colors.grey), // Force grey text
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          onPressed: null, // *** Disable the button ***
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });
    
    final account = await GoogleCalendarService.signIn();
    
    setState(() {
      _isGoogleSignedIn = account != null;
      _googleAccount = account?.email ?? '';
      _isLoading = false;
    });
    
    if (account != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully connected to Google Calendar')),
      );
    }
  }

  Future<void> _handleGoogleSignOut() async {
    setState(() {
      _isLoading = true;
    });
    
    await GoogleCalendarService.signOut();
    
    setState(() {
      _isGoogleSignedIn = false;
      _googleAccount = '';
      _isLoading = false;
      _syncToGoogleCalendar = false;
    });

    await StorageService.saveBool(AppConstants.syncToGoogleCalendarKey, false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disconnected from Google Calendar')),
    );
  }

  Future<void> _showSyncDialog(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Checking Sync Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Comparing local events with Google Calendar...'),
          ],
        ),
      ),
    );

    try {
      // Check sync status
      final syncResult = await CalendarTestHelper.checkCalendarSyncStatus();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show sync status with option to sync missing events
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sync Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Local Events: ${syncResult['totalLocalEvents'] ?? 0}'),
              Text('Events on Google Calendar: ${syncResult['matchedEvents'] ?? 0}'),
              Text('Missing Events: ${syncResult['missingEvents'] ?? 0}'),
              if ((syncResult['missingEvents'] ?? 0) > 0) ...[
                const SizedBox(height: 16),
                const Text('Would you like to upload the missing events to Google Calendar?'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if ((syncResult['missingEvents'] ?? 0) > 0)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _syncMissingEvents(context);
                },
                child: const Text('Sync Missing Events'),
              ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking sync status: $e')),
      );
    }
  }

  Future<void> _syncMissingEvents(BuildContext context) async {
    // Show loading dialog
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return WillPopScope(
          onWillPop: () async => false,
          child: const AlertDialog(
            title: Text('Syncing Missing Events'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading missing events to Google Calendar...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      final result = await CalendarTestHelper.syncMissingEventsToGoogleCalendar(context);
      
      // Close the dialog using the captured context
      if (dialogContext != null) {
        Navigator.pop(dialogContext!);
      }
      
      // Show the result
      if (context.mounted) {
        final syncedCount = result['syncedCount'] ?? 0;
        final updatedCount = result['updatedCount'] ?? 0;
        String message;
        if (syncedCount > 0 && updatedCount > 0) {
          message = 'Synced $syncedCount new events and updated $updatedCount existing events in Google Calendar';
        } else if (syncedCount > 0) {
          message = 'Synced $syncedCount new events to Google Calendar';
        } else if (updatedCount > 0) {
          message = 'Updated $updatedCount existing events in Google Calendar';
        } else {
          message = 'No events needed syncing or updating';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      // Close the dialog using the captured context
      if (dialogContext != null) {
        Navigator.pop(dialogContext!);
      }
      
      // Show the error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing events: $e')),
        );
      }
    }
  }

  // --- Add back the Backup & Restore UI + Logic methods ---

  Widget _buildBackupButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: Icon(Icons.backup_outlined, color: Theme.of(context).iconTheme.color),
        title: const Text('Backup Data'),
        subtitle: const Text('Save events and settings to a file'),
        onTap: _performBackup,
      ),
    );
  }

  Widget _buildRestoreButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: Icon(Icons.restore_page_outlined, color: Theme.of(context).iconTheme.color),
        title: const Text('Restore Data'),
        subtitle: const Text('Load events and settings from a file'),
        onTap: _confirmRestore,
      ),
    );
  }

  Future<void> _performBackup() async {
    // Show loading indicator
     _showLoadingDialog("Creating backup...");
    
    final bool success = await BackupService.createBackup();
    
    // Close loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Backup created successfully!' : 'Backup failed.')),
        );
    }
  }

  Future<void> _confirmRestore() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text('Restoring data will overwrite current events and settings. Are you sure?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation
              _performRestore(); // Start restore process
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore() async {
     // Show loading indicator
    _showLoadingDialog("Restoring backup...");

    final bool success = await BackupService.restoreBackup();

    // Close loading dialog
    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      // Show success message and prompt for restart
      if (mounted) {
         showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Restore Complete'),
              content: const Text('Data restored successfully. Please restart the app for changes to take full effect.'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore failed. Please check the backup file and try again.')),
        );
      }
    }
  }
  
  // Helper for loading dialog
  void _showLoadingDialog(String message) {
     showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16), 
            Text(message),
          ],
        ),
      ),
    );
  }
}
