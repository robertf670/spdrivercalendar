import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class GoogleSyncSettingsCard extends StatelessWidget {
  final bool isGoogleSignedIn;
  final bool syncToGoogleCalendar;
  final ValueChanged<bool> onSyncToggleChanged;
  final VoidCallback onSyncStatusCheck;

  const GoogleSyncSettingsCard({
    Key? key,
    required this.isGoogleSignedIn,
    required this.syncToGoogleCalendar,
    required this.onSyncToggleChanged,
    required this.onSyncStatusCheck,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a Column within a single Card for grouping
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Auto-sync to Google Calendar'),
            subtitle: const Text('Automatically add new events'), // Shortened subtitle
            secondary: const Icon(Icons.sync),
            value: syncToGoogleCalendar,
            // Disable toggle if not signed in
            onChanged: isGoogleSignedIn ? onSyncToggleChanged : null,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('Check/Sync All Events Now'), // Updated title
            subtitle: const Text('Verify and upload local shifts'), // Updated subtitle
            trailing: isGoogleSignedIn ? const Icon(Icons.chevron_right) : null,
            enabled: isGoogleSignedIn,
            onTap: isGoogleSignedIn ? onSyncStatusCheck : null,
          ),
        ],
      ),
    );
  }
} 
