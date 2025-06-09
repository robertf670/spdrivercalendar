import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class NotificationSettingsGroup extends StatelessWidget {
  final bool notificationsEnabled;
  final int notificationOffsetHours;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int?> onOffsetChanged;
  final VoidCallback onTestNotification;

  const NotificationSettingsGroup({
    Key? key,
    required this.notificationsEnabled,
    required this.notificationOffsetHours,
    required this.onEnabledChanged,
    required this.onOffsetChanged,
    required this.onTestNotification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color? disabledColor = Colors.grey;
    const Color? disabledIconColor = Colors.grey;
    const bool isGloballyDisabled = true;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
            child: Text(
              'Shift notifications are temporarily disabled due to technical issues. We are working on a fix.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SwitchListTile(
            title: Text('Enable Shift Notifications'),
            subtitle: Text('Get notified before your shift starts'),
            secondary: Icon(
              Icons.notifications_off,
              color: disabledIconColor,
            ),
            value: false,
            onChanged: null,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            enabled: !isGloballyDisabled,
            leading: const Icon(
              Icons.timer_outlined,
              color: disabledIconColor,
            ),
            title: const Text(
              'Notify Before Shift',
              style: TextStyle(color: disabledColor),
            ),
            trailing: DropdownButton<int>(
              value: notificationOffsetHours,
              onChanged: null,
              items: <int>[1, 2, 4]
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    '$value hour${value > 1 ? 's' : ''}',
                    style: const TextStyle(color: disabledColor),
                  ),
                );
              }).toList(),
              disabledHint: Text(
                '$notificationOffsetHours hour${notificationOffsetHours > 1 ? 's' : ''}',
                style: const TextStyle(color: disabledColor),
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            enabled: !isGloballyDisabled,
            leading: const Icon(
              Icons.notification_important_outlined,
              color: disabledIconColor,
            ),
            title: const Text(
              'Test Notification',
              style: TextStyle(color: disabledColor),
            ),
            trailing: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('Send Test'),
            ),
          ),
        ],
      ),
    );
  }
} 
