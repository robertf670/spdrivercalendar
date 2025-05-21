import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:spdrivercalendar/core/constants/app_constants.dart';
import 'package:spdrivercalendar/core/services/storage_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class WhatsNewScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WhatsNewScreen({
    Key? key,
    required this.onContinue,
  }) : super(key: key);

  @override
  State<WhatsNewScreen> createState() => _WhatsNewScreenState();
}

class _WhatsNewScreenState extends State<WhatsNewScreen> {
  String _currentVersion = '';
  bool _isLoading = true;

  // This map contains the changelog for each version
  // The key is the version number, and the value is a map of feature title and description
  final Map<String, List<Map<String, String>>> _changelogData = {
    '2.7.1': [
      {
        'title': 'Improved Pay Scale Table',
        'description': 'Enhanced the pay scale screen with better vertical scrolling that works on all screen sizes, with synchronized scrolling between columns.',
      },
    ],
    '2.7.0': [
      {
        'title': 'Overtime Shifts Support',
        'description': 'Added full support for overtime shifts, including special formatting for first and second half duties.',
      },
      {
        'title': 'Improved Overtime Display',
        'description': 'Overtime shifts now show accurate work time calculation, proper locations, and bold formatting for better visibility.',
      },
      {
        'title': 'UNI/Euro Overtime Support',
        'description': 'Added support for UNI/Euro overtime shifts with correct time and location display for both first and second half shifts.',
      },
    ],
    '2.6.1': [
      {
        'title': 'Restore Fix',
        'description': 'Fixed an issue where events spanning midnight might not display correctly on all relevant days after restoring from a backup.',
      },
    ],
    '2.6.0': [
      {
        'title': 'Automatic Backups Implemented',
        'description': 'The app now automatically backs up your data when it is backgrounded. This feature is enabled by default.',
      },
      {
        'title': 'Auto-Backup Management',
        'description': 'You can toggle auto-backups in Settings and restore from the last 5 internal backups. Timestamps in the restore list are now more user-friendly.',
      },
    ],
    '2.5.1': [
      {
        'title': 'Payscale UI Enhancements',
        'description': 'Improved the layout and styling of the Payscale screen, including a fixed header column and alternating row colors for better readability.',
      },
      {
        'title': 'Fix: Resolved issue where bank holidays were not consistently highlighted on the calendar after initial load.',
      },
    ],
    '2.5.0': [
      {
        'title': 'Pay Scale Menu Item',
        'description': 'Added a "Pay Scale" item to the settings menu for quick access to pay scale information.',
      },
    ],
    '2.4.0': [
      {
        'title': 'Pay Scales Feature',
        'description': 'Added Dublin Bus pay scales with rates for different years of service and payment types',
      },
      {
        'title': 'UI Improvements',
        'description': 'Added Driver Resources section to Settings menu for accessing driver-related information',
      },
    ],
    '2.3.1': [
      {
        'title': 'Bug Fixes',
        'description': 'Fixed issues with Google Calendar synchronization',
      },
      {
        'title': 'Performance Improvements',
        'description': 'Improved app loading and calendar rendering speed',
      },
      {
        'title': 'UI Enhancements',
        'description': 'Enhanced visual appearance for better readability',
      },
    ],
    '2.3.0': [
      {
        'title': 'New Settings Panel',
        'description': 'Redesigned settings panel for easier configuration',
      },
      {
        'title': 'Dark Mode Improvements',
        'description': 'Enhanced dark mode with better contrast and colors',
      },
    ],
    '2.2.0': [
      {
        'title': 'What\'s New Screen',
        'description': 'Added this screen to keep you informed about new features',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentVersion = AppConstants.appVersion;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateLastSeenVersion() async {
    await StorageService.saveString(AppConstants.lastSeenVersionKey, _currentVersion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What\'s New'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Version $_currentVersion',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'We\'ve made some updates to improve your experience:',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ..._buildChangelogItems(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _updateLastSeenVersion().then((_) {
                          widget.onContinue();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildChangelogItems() {
    // Find the changelog for the current version
    final List<Map<String, String>> versionChanges = _changelogData[_currentVersion] ?? [];
    
    // If no changelog for this specific version, show a default message
    if (versionChanges.isEmpty) {
      return [
        _buildChangeItem(
          'General Improvements',
          'Various bug fixes and performance improvements',
        ),
      ];
    }

    // Otherwise, show the specific changes for this version
    return versionChanges.map((item) {
      return _buildChangeItem(item['title']!, item['description']!);
    }).toList();
  }

  Widget _buildChangeItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 