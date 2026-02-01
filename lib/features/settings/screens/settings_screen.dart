import 'package:flutter/material.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/google_calendar_service.dart';
import 'package:spdrivercalendar/features/settings/screens/google_calendar_settings_screen.dart';
import 'package:spdrivercalendar/features/settings/screens/google_calendar_help_screen.dart';
import 'package:spdrivercalendar/features/settings/screens/admin_dashboard_screen.dart';
import 'package:spdrivercalendar/features/settings/screens/live_updates_preferences_screen.dart';
import 'package:spdrivercalendar/features/feedback/screens/feedback_screen.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';
import 'package:spdrivercalendar/calendar_test_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spdrivercalendar/services/backup_service.dart';
import 'dart:io'; // For File type in auto-backup list
import 'package:intl/intl.dart'; // For DateFormat
import 'package:spdrivercalendar/features/settings/widgets/color_customization_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spdrivercalendar/features/calendar/services/event_service.dart';
import 'package:spdrivercalendar/services/pay_scale_service.dart';
import '../../../config/app_config.dart';
import 'package:spdrivercalendar/services/universal_board_service.dart';
import 'package:spdrivercalendar/models/universal_board.dart';
import 'package:spdrivercalendar/services/days_in_lieu_service.dart';
import 'package:spdrivercalendar/services/annual_leave_service.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';

// Define Preference Keys for Notifications (Consider moving to AppConstants if not already there)
const String kNotificationsEnabledKey = 'notificationsEnabled';
const String kNotificationOffsetHoursKey = 'notificationOffsetHours';

class SettingsScreen extends StatefulWidget {
  final VoidCallback resetRestDaysCallback;
  final ValueNotifier<bool> isDarkModeNotifier;

  const SettingsScreen({
    super.key,
    required this.resetRestDaysCallback,
    required this.isDarkModeNotifier,
  });

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;
  bool _isGoogleSignedIn = false;
  String _googleAccount = '';
  bool _syncToGoogleCalendar = false;
  bool _includeBusAssignmentsInGoogleCalendar = true;
  bool _includeBustimesLinksInGoogleCalendar = true;
  bool _isLoading = false;
  String _appVersion = '';
  final ScrollController _scrollController = ScrollController();

  // Notification state variables - Temporarily disabled
  // int _notificationOffsetHours = 1; // Default offset

  // Auto-Backup state variable
  bool _autoBackupEnabled = false;
  
  // Display settings
  bool _showOvernightDutiesOnBothDays = true; // Default to true to preserve current behavior
  bool _showDutyCodesOnCalendar = true; // Default to true (ON)
  bool _animatedSelectedDay = true; // Default to true (ON) - animated border
  
  // Pay rate setting
  String _spreadPayRate = 'year1+2'; // Default to Year 1/2
  
  // Marked In settings
  String _markedInStatus = 'Spare'; // Spare, Shift, or M-F
  String _markedInZone = 'Zone 1'; // Zone selection when Shift is selected
  
  // Days in lieu balance
  int _daysInLieuBalance = 0;
  int _daysInLieuUsed = 0;
  int _daysInLieuRemaining = 0;
  
  // Annual leave balance
  int _annualLeaveBalance = 0;
  int _annualLeaveUsed = 0;
  int _annualLeaveRemaining = 0;
  
  // Expandable sections state
  final Map<String, bool> _expandedSections = {
    'Appearance': true,
    'App': true,
    'Holidays & Leave': false,
    'Google Calendar': false,
    'Backup & Restore': false,
    'Notifications': false,
    'Admin': false,
  };

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkModeNotifier.value;
    _loadSettings();
    _checkGoogleSignIn();
    _loadAppVersion();
    _loadExpandedSections();
    _loadDaysInLieuBalance();
    _loadAnnualLeaveBalance();
    _loadMarkedInSettings();
  }
  
  Future<void> _loadExpandedSections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _expandedSections['Appearance'] = prefs.getBool('settings_expanded_appearance') ?? true;
      _expandedSections['App'] = prefs.getBool('settings_expanded_app') ?? true;
      _expandedSections['Holidays & Leave'] = prefs.getBool('settings_expanded_holidays') ?? false;
      _expandedSections['Google Calendar'] = prefs.getBool('settings_expanded_google') ?? false;
      _expandedSections['Backup & Restore'] = prefs.getBool('settings_expanded_backup') ?? false;
      _expandedSections['Notifications'] = prefs.getBool('settings_expanded_notifications') ?? false;
      _expandedSections['Admin'] = prefs.getBool('settings_expanded_admin') ?? false;
    });
  }
  
  Future<void> _saveExpandedSection(String section, bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (section) {
      case 'Appearance':
        key = 'settings_expanded_appearance';
        break;
      case 'App':
        key = 'settings_expanded_app';
        break;
      case 'Holidays & Leave':
        key = 'settings_expanded_holidays';
        break;
      case 'Google Calendar':
        key = 'settings_expanded_google';
        break;
      case 'Backup & Restore':
        key = 'settings_expanded_backup';
        break;
      case 'Notifications':
        key = 'settings_expanded_notifications';
        break;
      case 'Admin':
        key = 'settings_expanded_admin';
        break;
      default:
        return;
    }
    await prefs.setBool(key, expanded);
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(AppConstants.isDarkModeKey) ?? widget.isDarkModeNotifier.value;
    _syncToGoogleCalendar = prefs.getBool(AppConstants.syncToGoogleCalendarKey) ?? false;
    _includeBusAssignmentsInGoogleCalendar = prefs.getBool(AppConstants.includeBusAssignmentsInGoogleCalendarKey) ?? true;
    _includeBustimesLinksInGoogleCalendar = prefs.getBool(AppConstants.includeBustimesLinksInGoogleCalendarKey) ?? true;
    
    // Load notification settings
    // Temporarily disabled - Notifications section removed
    // _notificationOffsetHours = prefs.getInt(kNotificationOffsetHoursKey) ?? 1;

    // Load auto-backup setting - default to true
    _autoBackupEnabled = prefs.getBool(AppConstants.autoBackupEnabledKey) ?? true;
    
    // Load display settings - default to true to preserve current behavior
    _showOvernightDutiesOnBothDays = prefs.getBool(AppConstants.showOvernightDutiesOnBothDaysKey) ?? true;
    _showDutyCodesOnCalendar = prefs.getBool(AppConstants.showDutyCodesOnCalendarKey) ?? true;
    _animatedSelectedDay = prefs.getBool(AppConstants.animatedSelectedDayKey) ?? true;
    
    // Load pay rate setting - default to Year 1/2
    _spreadPayRate = prefs.getString(AppConstants.spreadPayRateKey) ?? 'year1+2';

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMarkedInSettings() async {
    // Check if marked-in was previously enabled (for migration)
    final markedInEnabled = await StorageService.getBool(AppConstants.markedInEnabledKey);
    final oldStatus = await StorageService.getString(AppConstants.markedInStatusKey) ?? 'Shift';
    final zone = await StorageService.getString(AppConstants.markedInZoneKey) ?? 'Zone 1';
    
    setState(() {
      if (markedInEnabled) {
        // Migrate old settings: if M-F or 4 Day, keep as M-F; otherwise set to Shift
        if (oldStatus == 'M-F' || oldStatus == '4 Day') {
          _markedInStatus = 'M-F';
        } else {
          _markedInStatus = 'Shift';
        }
      } else {
        _markedInStatus = 'Spare';
      }
      _markedInZone = zone;
    });
  }

  Future<void> _saveMarkedInSettings() async {
    // Save marked-in enabled state (true if not Spare)
    final enabled = _markedInStatus != 'Spare';
    await StorageService.saveBool(AppConstants.markedInEnabledKey, enabled);
    
    // Save status (use 'M-F' for M-F, 'Shift' for Shift)
    if (_markedInStatus == 'M-F') {
      await StorageService.saveString(AppConstants.markedInStatusKey, 'M-F');
    } else if (_markedInStatus == 'Shift') {
      await StorageService.saveString(AppConstants.markedInStatusKey, 'Shift');
    } else {
      // Spare - clear the status
      await StorageService.saveString(AppConstants.markedInStatusKey, '');
    }
    
    // Save zone if Shift is selected
    if (_markedInStatus == 'Shift') {
      await StorageService.saveString(AppConstants.markedInZoneKey, _markedInZone);
    }
  }

  Future<void> _loadDaysInLieuBalance() async {
    final balance = await DaysInLieuService.getBalance();
    final used = await DaysInLieuService.getUsedDays();
    final remaining = await DaysInLieuService.getRemainingDays();
    
    setState(() {
      _daysInLieuBalance = balance;
      _daysInLieuUsed = used;
      _daysInLieuRemaining = remaining;
    });
  }

  Future<void> _loadAnnualLeaveBalance() async {
    final balance = await AnnualLeaveService.getBalance();
    final used = await AnnualLeaveService.getUsedDays();
    final remaining = await AnnualLeaveService.getRemainingDays();
    
    setState(() {
      _annualLeaveBalance = balance;
      _annualLeaveUsed = used;
      _annualLeaveRemaining = remaining;
    });
  }

  Future<void> _checkGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final isSignedIn = await GoogleCalendarService.isSignedIn();
    final user = await GoogleCalendarService.getCurrentUserEmail();

    setState(() {
      _isGoogleSignedIn = isSignedIn;
      _googleAccount = user ?? '';
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

  Future<void> _toggleBusAssignments(bool value) async {
    setState(() {
      _includeBusAssignmentsInGoogleCalendar = value;
    });
    await StorageService.saveBool(AppConstants.includeBusAssignmentsInGoogleCalendarKey, value);
  }

  Future<void> _toggleBustimesLinks(bool value) async {
    setState(() {
      _includeBustimesLinksInGoogleCalendar = value;
    });
    await StorageService.saveBool(AppConstants.includeBustimesLinksInGoogleCalendarKey, value);
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // Handle error gracefully
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }

  Future<void> _toggleOvernightDutiesDisplay(bool value) async {
    setState(() {
      _showOvernightDutiesOnBothDays = value;
    });
    await StorageService.saveBool(AppConstants.showOvernightDutiesOnBothDaysKey, value);
    
    // Update the EventService cache so the change takes effect immediately
    EventService.updateOvernightDutiesPreference(value);
  }

  Future<void> _toggleDutyCodesDisplay(bool value) async {
    setState(() {
      _showDutyCodesOnCalendar = value;
    });
    await StorageService.saveBool(AppConstants.showDutyCodesOnCalendarKey, value);
    
    // The calendar will refresh automatically when navigating back to it
    // via didChangeDependencies or when the setting is checked in _getCalendarDayDisplayText
  }

  Future<void> _toggleAnimatedSelectedDay(bool value) async {
    setState(() {
      _animatedSelectedDay = value;
    });
    await StorageService.saveBool(AppConstants.animatedSelectedDayKey, value);
    
    // The calendar will refresh automatically when navigating back to it
  }

  void _onColorsChanged() {
    // Trigger a rebuild to refresh any UI that depends on colors
    setState(() {});
    
    // Show a snackbar to confirm the change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Shift colors updated successfully'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(3),
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width < 600 ? 8.0 : 16.0,
                    16.0,
                    MediaQuery.of(context).size.width < 600 ? 8.0 : 16.0,
                    32.0,
                  ),
                  children: [
                  // Version label at the top
                  if (_appVersion.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Center(
                        child: Text(
                          'Version $_appVersion',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 12,
                          ),
                        ),
                      ),
                    ),
                  
                  _buildExpandableSection(
                    title: 'Appearance',
                    icon: Icons.palette,
                    children: [
                      _buildDarkModeSwitch(),
                      ColorCustomizationWidget(
                        onColorsChanged: _onColorsChanged,
                      ),
                      _buildOvernightDutiesToggle(),
                      _buildDutyCodesToggle(),
                      _buildAnimatedSelectedDayToggle(),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildExpandableSection(
                    title: 'App',
                    icon: Icons.apps,
                    children: [
                      _buildMarkedInSettings(),
                      _buildPayRateDropdown(),
                      _buildFeedbackButton(),
                      _buildLiveUpdatesPreferencesButton(),
                      _buildVersionHistoryButton(),
                      _buildResetRestDaysButton(),
                      _buildTestBoardButton(),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildExpandableSection(
                    title: 'Holidays & Leave',
                    icon: Icons.event_available,
                    children: [
                      const SizedBox(height: 8),
                      _buildLeaveBalancesCard(),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildExpandableSection(
                    title: 'Google Calendar',
                    icon: Icons.calendar_today,
                    children: [
                      // Add disclaimer about Google Calendar access
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: MediaQuery.of(context).size.width < 600 ? 18 : 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Google Calendar access requires test user approval. Please use the feedback section to request access with your email address.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: MediaQuery.of(context).size.width < 600 ? 12 : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildGoogleAccountSection(),
                      _buildGoogleSyncOption(),
                      _buildManualSyncOption(),
                      _buildGoogleCalendarHelpButton(),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildExpandableSection(
                    title: 'Backup & Restore',
                    icon: Icons.backup,
                    children: [
                      _buildBackupButton(),
                      _buildRestoreButton(),
                      _buildAutoBackupToggle(),
                      _buildRestoreFromAutoBackupButton(),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildExpandableSection(
                    title: 'Admin',
                    icon: Icons.admin_panel_settings,
                    children: [
                      _buildAdminPanelButton(),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    final isExpanded = _expandedSections[title] ?? false;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: isSmallScreen ? 0.0 : 4.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: icon != null
              ? Icon(icon, color: AppTheme.primaryColor)
              : null,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontSize: isSmallScreen ? 18 : 20,
            ),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedSections[title] = expanded;
            });
            _saveExpandedSection(title, expanded);
          },
          tilePadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12.0 : 16.0,
            vertical: 8.0,
          ),
          childrenPadding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.borderRadius),
                  bottomRight: Radius.circular(AppTheme.borderRadius),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8.0 : 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: children,
                ),
              ),
            ),
          ],
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
      ],
    );
  }



  Widget _buildGoogleSyncOption() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Auto-sync to Google Calendar'),
            subtitle: const Text('Automatically add new events to Google Calendar'),
            secondary: const Icon(Icons.sync),
            value: _syncToGoogleCalendar,
            onChanged: _isGoogleSignedIn ? _toggleGoogleSync : null,
          ),
          // Sub-options (only show when sync is enabled)
          if (_syncToGoogleCalendar && _isGoogleSignedIn) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: SwitchListTile(
                title: const Text('Include Bus Assignments'),
                subtitle: const Text('Add bus numbers to Google Calendar descriptions'),
                secondary: const Icon(Icons.directions_bus),
                value: _includeBusAssignmentsInGoogleCalendar,
                onChanged: _toggleBusAssignments,
              ),
            ),
            // Bustimes.org links sub-option (only show when bus assignments are enabled)
            if (_includeBusAssignmentsInGoogleCalendar) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.only(left: 32.0),
                child: SwitchListTile(
                  title: const Text('Include Bustimes.org Links'),
                  subtitle: const Text('Add clickable tracking links for buses'),
                  secondary: const Icon(Icons.link),
                  value: _includeBustimesLinksInGoogleCalendar,
                  onChanged: _toggleBustimesLinks,
                ),
              ),
            ],
          ],
        ],
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

  Widget _buildGoogleCalendarHelpButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.help_outline, color: AppTheme.primaryColor),
        title: const Text('How to Share Google Calendar'),
        subtitle: const Text('Learn how to share your work schedule with family'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showGoogleCalendarHelpScreen(context),
      ),
    );
  }

  void _showGoogleCalendarHelpScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GoogleCalendarHelpScreen(),
      ),
    );
  }

  Widget _buildMarkedInSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('Marked In Status'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Status Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _markedInStatus,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Spare', child: Text('Spare')),
                      DropdownMenuItem(value: 'Shift', child: Text('Shift')),
                      DropdownMenuItem(value: 'M-F', child: Text('M-F')),
                    ],
                    onChanged: (String? newValue) async {
                      if (newValue != null && newValue != _markedInStatus) {
                        setState(() {
                          _markedInStatus = newValue;
                        });
                        await _saveMarkedInSettings();
                      }
                    },
                  ),
                  if (_markedInStatus == 'Shift') ...[
                    const SizedBox(height: 16),
                    const Text('Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _markedInZone,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Zone 1', child: Text('Zone 1')),
                        DropdownMenuItem(value: 'Zone 3', child: Text('Zone 3')),
                        DropdownMenuItem(value: 'Zone 4', child: Text('Zone 4')),
                      ],
                      onChanged: (String? newValue) async {
                        if (newValue != null && newValue != _markedInZone) {
                          setState(() {
                            _markedInZone = newValue;
                          });
                          await _saveMarkedInSettings();
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Coming soon notice
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bogey, 4 Day and Night Shift coming soon',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayRateDropdown() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.attach_money),
        title: const Text('Spread Pay Rate'),
        subtitle: const Text('Select your pay rate for spread calculations'),
        trailing: DropdownButton<String>(
          value: _spreadPayRate,
          onChanged: (String? newValue) async {
            if (newValue != null && newValue != _spreadPayRate) {
              setState(() {
                _spreadPayRate = newValue;
              });
              await StorageService.saveString(AppConstants.spreadPayRateKey, newValue);
            }
          },
          items: PayScaleService.getYearLevelOptions()
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(PayScaleService.getYearLevelDisplayName(value)),
            );
          }).toList(),
        ),
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

  Widget _buildFeedbackButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.feedback_outlined),
        title: const Text('Submit Feedback'),
        subtitle: const Text('Share suggestions or report issues'),
        onTap: _showFeedbackPage,
      ),
    );
  }

  void _showFeedbackPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FeedbackScreen()),
    );
  }

  Widget _buildLeaveBalancesCard() {
    final dayInLieuColor = ColorCustomizationService.getColorForShift('DAY_IN_LIEU');
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Annual Leave Section
            _buildBalanceSection(
              icon: Icons.beach_access,
              iconColor: primaryColor,
              title: 'Annual Leave',
              balance: _annualLeaveBalance,
              remaining: _annualLeaveRemaining,
              used: _annualLeaveUsed,
              usedLabel: 'Booked',
              onDecrement: () async {
                if (_annualLeaveBalance > 0) {
                  await AnnualLeaveService.decrementBalance(1);
                  await _loadAnnualLeaveBalance();
                }
              },
              onIncrement: () async {
                await AnnualLeaveService.incrementBalance(1);
                await _loadAnnualLeaveBalance();
              },
              warningText: _annualLeaveRemaining == 0
                ? 'No days remaining. Only future holidays count toward booked days.'
                : null,
            ),
            
            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
            
            // Days In Lieu Section
            _buildBalanceSection(
              icon: Icons.event_available,
              iconColor: dayInLieuColor,
              title: 'Days In Lieu',
              balance: _daysInLieuBalance,
              remaining: _daysInLieuRemaining,
              used: _daysInLieuUsed,
              onDecrement: () async {
                if (_daysInLieuBalance > 0) {
                  await DaysInLieuService.decrementBalance(1);
                  await _loadDaysInLieuBalance();
                }
              },
              onIncrement: () async {
                await DaysInLieuService.incrementBalance(1);
                await _loadDaysInLieuBalance();
              },
              warningText: _daysInLieuRemaining == 0 
                ? 'No days remaining. Remember to add days when you earn them.'
                : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int balance,
    required int remaining,
    required int used,
    String usedLabel = 'Booked',
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    String? warningText,
  }) {
    final hasWarning = warningText != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                label: 'Today',
                value: balance.toString(),
                valueColor: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                label: 'Remaining',
                value: remaining.toString(),
                valueColor: remaining == 0 ? Colors.orange : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                label: usedLabel,
                value: used.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              icon: Icons.remove,
              onPressed: onDecrement,
              tooltip: 'Decrease',
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Balance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildControlButton(
              icon: Icons.add,
              onPressed: onIncrement,
              tooltip: 'Increase',
            ),
          ],
        ),
        
        // Warning
        if (hasWarning)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
      ),
    );
  }

  // Temporarily disabled - Notifications section removed while working on a fix
  // Widget _buildShiftNotificationToggle() {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(vertical: 4.0),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(AppTheme.borderRadius),
  //     ),
  //     child: SwitchListTile(
  //       title: const Text('Enable Shift Notifications'),
  //       subtitle: const Text('Get notified before your shift starts'),
  //       secondary: const Icon(
  //         Icons.notifications_off, // Force off icon
  //         color: Colors.grey, // Force grey
  //       ),
  //       value: false, // Force off value
  //       onChanged: null, // *** Disable the switch ***
  //     ),
  //   );
  // }

  // Widget _buildNotificationOffsetDropdown() {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(vertical: 4.0),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(AppTheme.borderRadius),
  //     ),
  //     child: ListTile(
  //       enabled: false, // Disable the ListTile visually
  //       leading: const Icon(
  //         Icons.timer_outlined,
  //         color: Colors.grey, // Force grey
  //       ),
  //       title: const Text(
  //         'Notify Before Shift',
  //         style: TextStyle(color: Colors.grey), // Force grey text
  //       ),
  //       trailing: DropdownButton<int>(
  //         value: _notificationOffsetHours,
  //         onChanged: null, // *** Disable the dropdown ***
  //         items: <int>[1, 2, 4]
  //             .map<DropdownMenuItem<int>>((int value) {
  //           return DropdownMenuItem<int>(
  //             value: value,
  //             child: Text(
  //                '$value hour${value > 1 ? 's' : ''}',
  //                style: const TextStyle(color: Colors.grey), // Force grey item text
  //             ),
  //           );
  //         }).toList(),
  //         disabledHint: Text( // Show hint when disabled
  //            '$_notificationOffsetHours hour${_notificationOffsetHours > 1 ? 's' : ''}',
  //            style: const TextStyle(color: Colors.grey), 
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildTestNotificationButton() {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(vertical: 4.0),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(AppTheme.borderRadius),
  //     ),
  //     child: ListTile(
  //       enabled: false, // Disable the ListTile visually
  //       leading: const Icon(
  //         Icons.notification_important_outlined,
  //         color: Colors.grey, // Force grey
  //       ),
  //       title: const Text(
  //         'Test Notification',
  //         style: TextStyle(color: Colors.grey), // Force grey text
  //       ),
  //       trailing: ElevatedButton(
  //         onPressed: null, // *** Disable the button ***
  //         style: ElevatedButton.styleFrom(
  //            backgroundColor: Colors.grey[300],
  //            foregroundColor: Colors.grey[600],
  //         ),
  //         child: const Text('Send Test'),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildViewPendingNotificationsButton() {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(vertical: 4.0),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(AppTheme.borderRadius),
  //     ),
  //     child: ListTile(
  //       enabled: false, // Disable the ListTile visually
  //       leading: const Icon(
  //         Icons.pending_actions_outlined,
  //         color: Colors.grey, // Force grey
  //       ),
  //       title: const Text(
  //         'View Pending Notifications',
  //         style: TextStyle(color: Colors.grey), // Force grey text
  //       ),
  //       trailing: IconButton(
  //         icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
  //         onPressed: null, // *** Disable the button ***
  //       ),
  //     ),
  //   );
  // }

  Future<void> _handleGoogleSignIn() async {
    // Capture ScaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isLoading = true;
    });
    
    final account = await GoogleCalendarService.signInWithGoogle();
    
    setState(() {
      _isGoogleSignedIn = account != null;
      _googleAccount = account ?? '';
      _isLoading = false;
    });
    
    if (account != null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully connected to Google Calendar')),
      );
    }
  }

  Future<void> _handleGoogleSignOut() async {
    // Capture ScaffoldMessenger before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    setState(() {
      _isLoading = true;
    });
    
    await GoogleCalendarService.signOut();
    
    setState(() {
      _isGoogleSignedIn = false;
      _googleAccount = '';
      _isLoading = false;
      _syncToGoogleCalendar = false;
      _includeBusAssignmentsInGoogleCalendar = true;
      _includeBustimesLinksInGoogleCalendar = true;
    });

    await StorageService.saveBool(AppConstants.syncToGoogleCalendarKey, false);
    await StorageService.saveBool(AppConstants.includeBusAssignmentsInGoogleCalendarKey, true);
    await StorageService.saveBool(AppConstants.includeBustimesLinksInGoogleCalendarKey, true);
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Disconnected from Google Calendar')),
    );
  }











  Future<void> _showSyncDialog(BuildContext context) async {
    // Capture Navigator and ScaffoldMessenger before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
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
      
      // Check if context is still valid before using it
      if (!context.mounted) return;
      
      // Close loading dialog
      navigator.pop();
      
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
              onPressed: () => navigator.pop(),
              child: const Text('Close'),
            ),
            if ((syncResult['missingEvents'] ?? 0) > 0)
              TextButton(
                onPressed: () async {
                  navigator.pop();
                  await _syncMissingEvents(context);
                },
                child: const Text('Sync Missing Events'),
              ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog
      navigator.pop();
      
      // Show error
      scaffoldMessenger.showSnackBar(
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
        return PopScope(
          canPop: false,
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
      if (dialogContext != null && dialogContext!.mounted) {
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
      if (dialogContext != null && dialogContext!.mounted) {
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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(value ? 'Automatic backups enabled' : 'Automatic backups disabled')),
          );
          // Optionally trigger an initial backup if enabling for the first time
          if (value) {
             _showLoadingDialog("Creating initial auto-backup...");
            bool success = await BackupService.createAutoBackup();
            if (!mounted) return;
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
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

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
    if (!mounted) return;
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
    if (!mounted) return;
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

  Widget _buildLiveUpdatesPreferencesButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.tune),
        title: const Text('Live Updates Preferences'),
        subtitle: const Text('Configure your preferred routes and notifications'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LiveUpdatesPreferencesScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminPanelButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: Icon(
          Icons.admin_panel_settings,
          color: Colors.red.shade600,
        ),
        title: const Text('Admin Panel'),
        subtitle: const Text('Manage live updates and diversions'),
        onTap: _checkAdminAccess,
      ),
    );
  }

  Future<void> _checkAdminAccess() async {
    // Check if device is remembered
    final isRemembered = await StorageService.getBool(AppConstants.adminRememberDeviceKey);
    if (isRemembered) {
      // Device is remembered, skip password dialog
      _navigateToAdminPanel();
      return;
    }
    // Show password dialog
    _showAdminPasswordDialog();
  }

  void _showAdminPasswordDialog() {
    final passwordController = TextEditingController();
    bool rememberDevice = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Admin Access'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter admin password to access the control panel:'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (value) {
                  if (AppConfig.isValidAdminPassword(value)) {
                    _handleAdminLogin(rememberDevice);
                    Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                    _showIncorrectPasswordDialog();
                  }
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Remember this device'),
                subtitle: const Text('Skip password on this device'),
                value: rememberDevice,
                onChanged: (value) {
                  setState(() {
                    rememberDevice = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (AppConfig.isValidAdminPassword(passwordController.text)) {
                  _handleAdminLogin(rememberDevice);
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                  _showIncorrectPasswordDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Access'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdminLogin(bool rememberDevice) async {
    if (rememberDevice) {
      // Store remember device flag (indefinitely)
      await StorageService.saveBool(
        AppConstants.adminRememberDeviceKey,
        true,
      );
    }
    _navigateToAdminPanel();
  }

  void _showIncorrectPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Access Denied'),
          ],
        ),
        content: const Text('Incorrect password. Admin access is restricted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminDashboardScreen(),
      ),
    );
  }

  Widget _buildOvernightDutiesToggle() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: SwitchListTile(
        title: const Text('Show overnight duties on both days'),
        subtitle: const Text('When enabled, duties spanning midnight will appear on both start and end dates'),
        secondary: const Icon(Icons.schedule),
        value: _showOvernightDutiesOnBothDays,
        onChanged: _toggleOvernightDutiesDisplay,
      ),
    );
  }

  Widget _buildDutyCodesToggle() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: SwitchListTile(
        title: const Text('Show Duty Codes on Calendar'),
        subtitle: const Text('Display assigned duty codes instead of shift letters (E/L/M/R)'),
        secondary: const Icon(Icons.calendar_view_day),
        value: _showDutyCodesOnCalendar,
        onChanged: _toggleDutyCodesDisplay,
      ),
    );
  }

  Widget _buildAnimatedSelectedDayToggle() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: SwitchListTile(
        title: const Text('Animated Selected Day Border'),
        subtitle: const Text('Show animated pulsing border for selected day (disabled shows static border)'),
        secondary: const Icon(Icons.animation),
        value: _animatedSelectedDay,
        onChanged: _toggleAnimatedSelectedDay,
      ),
    );
  }

  Widget _buildTestBoardButton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.route),
        title: const Text('Test Board Viewer'),
        subtitle: const Text('View boards in JSON format'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _showBoardSelection,
      ),
    );
  }

  Future<void> _showBoardSelection() async {
    try {
      final boards = await UniversalBoardService.loadBoards();
      if (boards.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No boards found')),
          );
        }
        return;
      }

      // Filter to only show boards that have sections (not empty)
      final boardsWithData = boards.where((b) => b.sections.isNotEmpty).toList();
      
      if (boardsWithData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No boards with data found')),
          );
        }
        return;
      }

      if (mounted) {
        // Show selection dialog
        final selectedBoard = await showDialog<UniversalBoard>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Board'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: boardsWithData.length,
                itemBuilder: (context, index) {
                  final board = boardsWithData[index];
                  return ListTile(
                    title: Text('Board ${board.shift}'),
                    subtitle: board.duty != null ? Text('Duty ${board.duty}') : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(board),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );

        if (selectedBoard != null) {
          _showBoard(selectedBoard);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading boards: $e')),
        );
      }
    }
  }

  void _showBoard(UniversalBoard board) {
    showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.95,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Board ${board.shift}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (board.duty != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Duty ${board.duty}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: board.sections.map((section) {
                          final sectionType = section.type;
                          final isFirstHalf = sectionType == 'firstHalf';
                          final sectionColor = isFirstHalf ? Colors.orange : Colors.blue;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section header with subtle background
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: sectionColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: sectionColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isFirstHalf ? 'First Half' : 'Second Half',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          color: sectionColor.shade800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Entries with subtle timeline
                                ...section.entries.asMap().entries.map((entryEntry) {
                                  final entry = entryEntry.value;
                                  final isLast = entryEntry.key == section.entries.length - 1;
                                  
                                  // Calculate if this entry has content below the action
                                  final hasDetails = entry.location != null || 
                                                     entry.notes != null || 
                                                     (entry.action.toLowerCase() != 'route' && entry.route != null);
                                  
                                  // Check if action is Route (to combine with route badge)
                                  final isRouteAction = entry.action.toLowerCase() == 'route' && entry.route != null;
                                  
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Time column - fixed width and alignment
                                        SizedBox(
                                          width: 70,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (entry.time != null)
                                                Container(
                                                  width: 70,
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: sectionColor.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: sectionColor.withValues(alpha: 0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    entry.time!,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: sectionColor.shade800,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                )
                                              else
                                                SizedBox(
                                                  width: 70,
                                                  height: 30, // Match badge height
                                                ),
                                              if (!isLast) ...[
                                                const SizedBox(height: 6),
                                                Container(
                                                  width: 2,
                                                  height: hasDetails ? 35 : 15,
                                                  color: sectionColor.withValues(alpha: 0.2),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Content column
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Action - aligned with time badge by matching height
                                              SizedBox(
                                                height: entry.time != null ? 30 : null,
                                                child: Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: isRouteAction
                                                      ? Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Text(
                                                              'Route ',
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 16,
                                                                color: Theme.of(context).colorScheme.onSurface,
                                                              ),
                                                            ),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: Colors.blue.shade50,
                                                                borderRadius: BorderRadius.circular(6),
                                                              ),
                                                              child: Text(
                                                                entry.route!,
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  color: Colors.blue.shade700,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : Text(
                                                          entry.action,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 16,
                                                            color: Theme.of(context).colorScheme.onSurface,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              if (hasDetails) const SizedBox(height: 6),
                                              // Route path information - just "From [location]"
                                              if (isRouteAction && entry.location != null) ...[
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.location_on,
                                                        size: 16,
                                                        color: Theme.of(context)
                                                            .colorScheme.onSurface
                                                            .withValues(alpha: 0.5),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          'From ${entry.location}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Theme.of(context)
                                                                .colorScheme.onSurface
                                                                .withValues(alpha: 0.7),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Show notes if they exist (like "via Celbridge")
                                                if (entry.notes != null) ...[
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.info_outline,
                                                          size: 16,
                                                          color: Theme.of(context)
                                                              .colorScheme.onSurface
                                                              .withValues(alpha: 0.5),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            entry.notes!,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontStyle: FontStyle.italic,
                                                              color: Theme.of(context)
                                                                  .colorScheme.onSurface
                                                                  .withValues(alpha: 0.7),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ] else ...[
                                                // Route badge (only if action is not "Route")
                                                if (entry.route != null) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Route ${entry.route}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.blue.shade700,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                ],
                                                // Location (for non-Route entries)
                                                if (entry.location != null) ...[
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.location_on,
                                                          size: 16,
                                                          color: Theme.of(context)
                                                              .colorScheme.onSurface
                                                              .withValues(alpha: 0.5),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            entry.location!,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Theme.of(context)
                                                                  .colorScheme.onSurface
                                                                  .withValues(alpha: 0.7),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                              // Notes (exclude Route entries as they're handled above)
                                              if (entry.notes != null && !isRouteAction) ...[
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    top: entry.location != null ? 4 : 2,
                                                  ),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme.surfaceContainerHighest
                                                          .withValues(alpha: 0.5),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Icon(
                                                          Icons.info_outline,
                                                          size: 16,
                                                          color: Theme.of(context)
                                                              .colorScheme.onSurface
                                                              .withValues(alpha: 0.5),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            entry.notes!,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: Theme.of(context)
                                                                  .colorScheme.onSurface
                                                                  .withValues(alpha: 0.7),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }

}
