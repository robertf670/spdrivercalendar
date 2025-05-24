import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/features/settings/screens/google_calendar_settings_screen.dart';
import 'package:spdrivercalendar/features/payscale/screens/payscale_screen.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spdrivercalendar/services/backup_service.dart';
import 'dart:io'; // For File type in auto-backup list
import 'package:intl/intl.dart'; // For DateFormat

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

  // Auto-Backup state variable
  bool _autoBackupEnabled = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkModeNotifier.value;
    _loadSettings();
    _checkGoogleSignIn();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(AppConstants.isDarkModeKey) ?? widget.isDarkModeNotifier.value;
    _syncToGoogleCalendar = prefs.getBool(AppConstants.syncToGoogleCalendarKey) ?? false;
    
    // Load notification settings
    _notificationsEnabled = prefs.getBool(kNotificationsEnabledKey) ?? false;
    _notificationOffsetHours = prefs.getInt(kNotificationOffsetHoursKey) ?? 1;

    // Load auto-backup setting - default to true
    _autoBackupEnabled = prefs.getBool(AppConstants.autoBackupEnabledKey) ?? true;

    setState(() {
      _isLoading = false;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
          _buildAutoBackupToggle(),
          _buildRestoreFromAutoBackupButton(),
          // --- End Restored Section ---
          
                    // Driver Resources section removed and moved to dropdown menu
          
          const Divider(height: 32),
          _buildSectionHeader('App'),
          _buildShowWelcomePageButton(),
          _buildVersionHistoryButton(),
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
    
    return Column(
      children: [
        Card(
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
        ),
        // Always show debugging options
        _buildGoogleDebuggingSection(),
      ],
    );
  }

  Widget _buildGoogleDebuggingSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.bug_report, color: Colors.orange),
        title: const Text('Google Sign-In Debugging'),
        subtitle: const Text('Tools to fix connection issues'),
        children: [
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.blue),
            title: const Text('Force Re-authentication'),
            subtitle: const Text('Clear cache and sign in again'),
            onTap: _handleGoogleReauth,
          ),
          ListTile(
            leading: const Icon(Icons.clear_all, color: Colors.red),
            title: const Text('Clear All Google Data'),
            subtitle: const Text('Reset all Google authentication data'),
            onTap: _handleClearGoogleData,
          ),
          ListTile(
            leading: const Icon(Icons.power_settings_new, color: Colors.deepOrange),
            title: const Text('Complete Disconnect'),
            subtitle: const Text('Nuclear option - revoke all permissions'),
            onTap: _handleCompleteReset,
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services, color: Colors.orange),
            title: const Text('Simple Reset'),
            subtitle: const Text('Alternative reset (if complete disconnect fails)'),
            onTap: _handleSimpleReset,
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.green),
            title: const Text('Test Google Configuration'),
            subtitle: const Text('Check if setup is correct'),
            onTap: _handleTestGoogleConfig,
          ),
        ],
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

  Future<void> _handleGoogleReauth() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First sign out to clear any stale tokens
      await GoogleCalendarService.signOut();
      await GoogleCalendarService.clearLoginData();
      
      // Then sign in fresh
      final account = await GoogleCalendarService.signIn();
      
      setState(() {
        _isGoogleSignedIn = account != null;
        _googleAccount = account?.email ?? '';
        _isLoading = false;
      });
      
      if (account != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully re-authenticated with Google Calendar')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Re-authentication was cancelled')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-authentication failed: $e')),
      );
    }
  }

  Future<void> _handleClearGoogleData() async {
    // Show confirmation dialog
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Google Data'),
        content: const Text('This will remove all Google authentication data and signed-in status. You will need to sign in again to use Google Calendar features.\n\nAre you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Clear all Google data
        await GoogleCalendarService.clearLoginData();
        await GoogleCalendarService.signOut();
        
        // Update UI state
        setState(() {
          _isGoogleSignedIn = false;
          _googleAccount = '';
          _isLoading = false;
          _syncToGoogleCalendar = false;
        });

        // Save sync preference
        await StorageService.saveBool(AppConstants.syncToGoogleCalendarKey, false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All Google data cleared successfully')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing Google data: $e')),
        );
      }
    }
  }

  Future<void> _handleCompleteReset() async {
    // Show confirmation dialog
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Disconnect'),
        content: const Text('This will completely disconnect your Google account and revoke ALL permissions granted to this app. This is the "nuclear option" that should fix authentication issues.\n\nYou will need to sign in again and re-grant permissions.\n\nAre you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Complete Reset'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Use the complete reset function
        await GoogleCalendarService.completeReset();
        
        // Update UI state
        setState(() {
          _isGoogleSignedIn = false;
          _googleAccount = '';
          _isLoading = false;
          _syncToGoogleCalendar = false;
        });

        // Save sync preference
        await StorageService.saveBool(AppConstants.syncToGoogleCalendarKey, false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complete reset successful! All Google permissions revoked.'),
            duration: Duration(seconds: 4),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during complete reset: $e')),
        );
      }
    }
  }

  Future<void> _handleSimpleReset() async {
    // Show confirmation dialog
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simple Reset'),
        content: const Text('This will clear authentication data and sign you out, but won\'t try to revoke permissions (which sometimes fails).\n\nThis is a good alternative if the Complete Disconnect option failed.\n\nAre you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Simple Reset'),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Use the simple reset function
        await GoogleCalendarService.simpleReset();
        
        // Update UI state
        setState(() {
          _isGoogleSignedIn = false;
          _googleAccount = '';
          _isLoading = false;
          _syncToGoogleCalendar = false;
        });

        // Save sync preference
        await StorageService.saveBool(AppConstants.syncToGoogleCalendarKey, false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simple reset completed! Try signing in again.'),
            duration: Duration(seconds: 4),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during simple reset: $e')),
        );
      }
    }
  }

  Future<void> _handleTestGoogleConfig() async {
    setState(() {
      _isLoading = true;
    });

    final List<String> results = [];
    
    try {
      // Test 1: Check if Google Sign-In is initialized
      results.add('✓ Google Sign-In service initialized');
      
      // Test 2: Check current sign-in status
      final isSignedIn = await GoogleCalendarService.isSignedIn();
      results.add(isSignedIn ? '✓ Currently signed in' : '✗ Not currently signed in');
      
      // Test 3: Check if we can get current user
      final currentUser = await GoogleCalendarService.getCurrentUser();
      if (currentUser != null) {
        results.add('✓ Current user found: ${currentUser.email}');
      } else {
        results.add('✗ No current user found');
      }
      
      // Test 4: Check calendar access (only if signed in)
      if (isSignedIn) {
        final hasAccess = await GoogleCalendarService.checkCalendarAccess();
        results.add(hasAccess ? '✓ Calendar API access working' : '✗ Calendar API access failed');
      } else {
        results.add('- Calendar API test skipped (not signed in)');
      }
      
      // Test 5: Check if config files are present (placeholder - would need platform channels for real check)
      results.add('- Configuration files check (manual verification needed)');
      
    } catch (e) {
      results.add('✗ Error during testing: $e');
    }

    setState(() {
      _isLoading = false;
    });

    // Show results dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Configuration Test'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Test Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...results.map((result) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(result, style: TextStyle(
                  fontFamily: 'monospace',
                  color: result.startsWith('✓') ? Colors.green :
                         result.startsWith('✗') ? Colors.red : null,
                )),
              )),
              const SizedBox(height: 16),
              const Text('Manual Checks:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('• Ensure google-services.json exists in android/app/'),
              const Text('• Ensure GoogleService-Info.plist exists in ios/Runner/'),
              const Text('• Check that package names match in Google Cloud Console'),
              const Text('• Verify SHA-1 fingerprints are added for Android'),
              const Text('• Add your account as a test user in OAuth consent screen'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
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

  Widget _buildAutoBackupToggle() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: SwitchListTile(
        title: const Text('Enable Automatic Backups'),
        subtitle: const Text('Backs up data when app is backgrounded'),
        value: _autoBackupEnabled,
        onChanged: (bool value) async {
          setState(() {
            _autoBackupEnabled = value;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(AppConstants.autoBackupEnabledKey, value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(value ? 'Automatic backups enabled' : 'Automatic backups disabled')),
          );
          // Optionally trigger an initial backup if enabling for the first time
          if (value) {
             _showLoadingDialog("Creating initial auto-backup...");
            bool success = await BackupService.createAutoBackup();
            Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? 'Initial auto-backup created.' : 'Initial auto-backup failed.')),
                );
            }
          }
        },
        secondary: Icon(Icons.autorenew, color: Theme.of(context).iconTheme.color),
      ),
    );
  }

  Widget _buildRestoreFromAutoBackupButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: Icon(Icons.settings_backup_restore, color: Theme.of(context).iconTheme.color),
        title: const Text('Restore from Auto-Backup'),
        subtitle: const Text('Restore data from an internal backup'),
        onTap: _showAutoBackupSelectionDialog,
      ),
    );
  }

  Future<void> _showAutoBackupSelectionDialog() async {
    _showLoadingDialog("Loading auto-backups...");
    List<File> autoBackups = await BackupService.listAutoBackups();
    Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

    if (!mounted) return;

    if (autoBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No automatic backups found.')),
      );
      return;
    }

    showDialog<File>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select an Auto-Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: autoBackups.length,
              itemBuilder: (BuildContext context, int index) {
                final backupFile = autoBackups[index];
                // Use the file's last modified timestamp for display
                final DateTime lastModified = backupFile.statSync().modified.toLocal();
                // Format for better readability (e.g., "Wed, Jul 10, 2024  3:45 PM")
                final String formattedDateTime = DateFormat('EEE, MMM d, yyyy  h:mm a').format(lastModified);

                return ListTile(
                  title: Text('Backup - $formattedDateTime'), // Updated title
                  subtitle: Text('Size: ${(backupFile.lengthSync() / 1024).toStringAsFixed(2)} KB'), // Added "Size:" and improved clarity
                  onTap: () {
                    Navigator.of(dialogContext).pop(backupFile);
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    ).then((selectedBackupFile) {
      if (selectedBackupFile != null) {
        _confirmRestoreFromAutoBackup(selectedBackupFile.path);
      }
    });
  }

  Future<void> _confirmRestoreFromAutoBackup(String filePath) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text('Restoring data from this auto-backup will overwrite current events and settings. Are you sure?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation
              _performRestore(filePathToRestore: filePath);
            },
          ),
        ],
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
              _performRestore(); // Start manual restore process (no path given)
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore({String? filePathToRestore}) async {
     // Show loading indicator
    _showLoadingDialog(filePathToRestore == null ? "Restoring backup..." : "Restoring auto-backup...");

    final bool success = await BackupService.restoreBackup(filePathToRestore: filePathToRestore);

    // Close loading dialog
    // Use a local variable for context that might be used in an async gap.
    final navContext = Navigator.of(context, rootNavigator: true);
    navContext.pop();

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

    // Payscale button removed from settings and moved to dropdown menu

  Widget _buildVersionHistoryButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.history),
        title: const Text('Version History'),
        subtitle: const Text('View changelog and app updates'),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/version-history', 
          );
        },
      ),
    );
  }
}
