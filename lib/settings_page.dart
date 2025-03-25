import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/google_login_page.dart';
import 'package:spdrivercalendar/screens/google_calendar_settings_screen.dart';
import 'package:spdrivercalendar/utils/preferences_util.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';  // Add this import
import 'package:spdrivercalendar/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback resetRestDaysCallback;
  final ValueNotifier<bool> isDarkModeNotifier;

  const SettingsPage({
    Key? key,
    required this.resetRestDaysCallback,
    required this.isDarkModeNotifier,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late bool _isDarkMode;
  bool _isGoogleSignedIn = false;
  String _googleAccount = '';
  bool _isLoading = false;
  bool _syncToGoogleCalendar = false;  // Added this field

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkModeNotifier.value;
    _loadPreferences();
    _checkGoogleSignIn();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncToGoogleCalendar = prefs.getBool('syncToGoogleCalendar') ?? false;
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> _toggleGoogleSync(bool value) async {
    setState(() {
      _syncToGoogleCalendar = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('syncToGoogleCalendar', value);
  }

  Future<void> _handleGoogleSignIn() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleLoginPage(
          onLoginComplete: () {
            Navigator.pop(context);
            _checkGoogleSignIn(); // Refresh sign-in status
          },
        ),
      ),
    );
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
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out of Google')),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
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
          _buildSyncStatusOption(),
          const Divider(height: 32),
          
          _buildSectionHeader('Schedule'),
          _buildResetRestDaysButton(),
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
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Google Calendar'),
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
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
        onTap: _isGoogleSignedIn ? null : _handleGoogleSignIn,
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

  Widget _buildSyncStatusOption() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.cloud_sync),
        title: const Text('Sync Status Check'),
        subtitle: const Text('Check if all events are synced to Google Calendar'),
        trailing: _isGoogleSignedIn ? const Icon(Icons.chevron_right) : null,
        enabled: _isGoogleSignedIn,
        onTap: _isGoogleSignedIn ? () => _checkSyncStatus(context) : null,
      ),
    );
  }

  Future<void> _checkSyncStatus(BuildContext context) async {
    // Show a loading dialog
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
      final syncResult = await CalendarTestHelper.checkCalendarSyncStatus();
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show the sync status dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Sync Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Local Events: ${syncResult['totalLocalEvents'] ?? 0}'),
              Text('Events on Google Calendar: ${syncResult['matchedEvents'] ?? 0}'),
              Text('Missing Events: ${syncResult['missingEvents'] ?? 0}'),
              if ((syncResult['missingEvents'] ?? 0) > 0) ...[
                SizedBox(height: 16),
                Text('Would you like to upload the missing events to Google Calendar?'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            if ((syncResult['missingEvents'] ?? 0) > 0)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _syncMissingEvents(context);
                },
                child: Text('Sync Missing Events'),
              ),
          ],
        ),
      );
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking sync status: $e')),
      );
    }
  }

  Future<void> _syncMissingEvents(BuildContext context) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
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

    try {
      final result = await CalendarTestHelper.syncMissingEventsToGoogleCalendar(context);
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced ${result['syncedCount']} events to Google Calendar')),
      );
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error syncing events: $e')),
      );
    }
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
}