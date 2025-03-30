import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/google_login_page.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/services/notification_service.dart';

// Import the new widgets
import 'features/settings/widgets/section_header.dart';
import 'features/settings/widgets/appearance_settings_card.dart';
import 'features/settings/widgets/google_account_card.dart';
import 'features/settings/widgets/google_sync_settings_card.dart';
import 'features/settings/widgets/notification_settings_group.dart';
import 'features/settings/widgets/schedule_settings_card.dart';
import 'features/settings/widgets/app_settings_card.dart';

// Preference Keys (Consider moving to AppConstants)
const String kNotificationsEnabledKey = 'notificationsEnabled';
const String kNotificationOffsetHoursKey = 'notificationOffsetHours';

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
  bool _syncToGoogleCalendar = false;
  
  // Notification state variables
  bool _notificationsEnabled = false;
  int _notificationOffsetHours = 1; // Default offset

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkModeNotifier.value;
    _loadPreferences();
    _checkGoogleSignIn();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _syncToGoogleCalendar = prefs.getBool('syncToGoogleCalendar') ?? false;
        _notificationsEnabled = prefs.getBool(kNotificationsEnabledKey) ?? false;
        _notificationOffsetHours = prefs.getInt(kNotificationOffsetHoursKey) ?? 1;
      });
    }
  }

  Future<void> _checkGoogleSignIn() async {
    if (mounted) setState(() { _isLoading = true; });
    final isSignedIn = await GoogleCalendarService.isSignedIn();
    final user = await GoogleCalendarService.getCurrentUser();
    if (mounted) {
        setState(() {
          _isGoogleSignedIn = isSignedIn;
          _googleAccount = user?.email ?? '';
          _isLoading = false;
        });
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    if (mounted) setState(() { _isDarkMode = value; });
    widget.isDarkModeNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> _toggleGoogleSync(bool value) async {
    if (mounted) setState(() { _syncToGoogleCalendar = value; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('syncToGoogleCalendar', value);
  }

  Future<void> _handleGoogleSignIn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleLoginPage(
          onLoginComplete: () {
            if (mounted) Navigator.pop(context);
            _checkGoogleSignIn(); // Refresh status
          },
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignOut() async {
    if (mounted) setState(() { _isLoading = true; });
    await GoogleCalendarService.signOut();
    await _checkGoogleSignIn(); // Refresh status
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out of Google')),
        );
    }
  }

  Future<void> _saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotificationsEnabledKey, enabled);
    if (mounted) setState(() { _notificationsEnabled = enabled; });
  }
  
  Future<void> _saveNotificationOffset(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kNotificationOffsetHoursKey, hours);
    if (mounted) setState(() { _notificationOffsetHours = hours; });
  }

  Future<void> _toggleNotificationsEnabled(bool value) async {
    if (value) {
      bool? permissionsGranted = await NotificationService().requestPermissions();
      if (!mounted) return;
      if (permissionsGranted == true) {
         await _saveNotificationsEnabled(true);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications enabled.')));
      } else {
         await _saveNotificationsEnabled(false);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification permissions denied or unavailable.')));
      }
    } else {
      await _saveNotificationsEnabled(false);
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications disabled.')));
    }
  }

  Future<void> _handleTestNotification() async {
    await NotificationService().showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent!')),
      );
    }
  }

  void _showWelcomePage() {
    Navigator.pushNamed(
      context, 
      '/welcome',
      arguments: true, // This indicates it's opened from settings
    );
  }

  Future<void> _checkSyncStatus(BuildContext context) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Checking Sync Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [ CircularProgressIndicator(), SizedBox(height: 16), Text('Comparing events...') ],
        ),
      ),
    );
    try {
      final syncResult = await CalendarTestHelper.checkCalendarSyncStatus();
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sync Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Local Events: ${syncResult['totalLocalEvents'] ?? 0}'),
              Text('Google Calendar Events: ${syncResult['matchedEvents'] ?? 0}'),
              Text('Missing from Google: ${syncResult['missingEvents'] ?? 0}'),
              if ((syncResult['missingEvents'] ?? 0) > 0) ...[
                const SizedBox(height: 16),
                const Text('Upload missing events?'),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            if ((syncResult['missingEvents'] ?? 0) > 0)
              TextButton(
                onPressed: () async {
                  if (!mounted) return;
                  Navigator.of(context).pop(); // Close status dialog
                  await _syncMissingEvents(context);
                },
                child: const Text('Sync Missing'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error checking sync status: $e')));
    }
  }

  Future<void> _syncMissingEvents(BuildContext context) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Syncing Missing Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [ CircularProgressIndicator(), SizedBox(height: 16), Text('Uploading events...') ],
        ),
      ),
    );
    try {
      final result = await CalendarTestHelper.syncMissingEventsToGoogleCalendar(context);
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Synced ${result['syncedCount']} events')));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error syncing events: $e')));
    }
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
          const SectionHeader(title: 'Appearance'),
          AppearanceSettingsCard(
            isDarkMode: _isDarkMode,
            onDarkModeChanged: _toggleDarkMode,
          ),
          const Divider(height: 32),
          
          const SectionHeader(title: 'Google Calendar'),
          GoogleAccountCard(
            isLoading: _isLoading,
            isGoogleSignedIn: _isGoogleSignedIn,
            googleAccountEmail: _googleAccount,
            onSignIn: _handleGoogleSignIn,
            onSignOut: _handleGoogleSignOut,
          ),
          GoogleSyncSettingsCard(
            isGoogleSignedIn: _isGoogleSignedIn,
            syncToGoogleCalendar: _syncToGoogleCalendar,
            onSyncToggleChanged: _toggleGoogleSync,
            onSyncStatusCheck: () => _checkSyncStatus(context),
          ),
          const Divider(height: 32),
          
          const SectionHeader(title: 'Notifications'),
          NotificationSettingsGroup(
            notificationsEnabled: _notificationsEnabled,
            notificationOffsetHours: _notificationOffsetHours,
            onEnabledChanged: _toggleNotificationsEnabled,
            onOffsetChanged: (value) {
              if (value != null) {
                _saveNotificationOffset(value);
              }
            },
            onTestNotification: _handleTestNotification,
          ),
          const Divider(height: 32),
          
          const SectionHeader(title: 'Schedule'),
          ScheduleSettingsCard(
            onResetRestDays: widget.resetRestDaysCallback,
          ),
          const Divider(height: 32),
          
          const SectionHeader(title: 'App'),
          AppSettingsCard(
             onShowWelcomePage: _showWelcomePage,
          ),
        ],
      ),
    );
  }
}