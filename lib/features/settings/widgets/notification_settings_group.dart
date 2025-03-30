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
    final Color? enabledColor = notificationsEnabled ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey;
    final Color? enabledIconColor = notificationsEnabled ? Theme.of(context).iconTheme.color : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Shift Notifications'),
            subtitle: const Text('Get notified before your shift starts'),
            secondary: Icon(
              notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: notificationsEnabled ? AppTheme.primaryColor : Colors.grey,
            ),
            value: notificationsEnabled,
            onChanged: onEnabledChanged,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            enabled: notificationsEnabled,
            leading: Icon(
              Icons.timer_outlined,
              color: enabledIconColor,
            ),
            title: Text(
              'Notify Before Shift',
              style: TextStyle(color: enabledColor),
            ),
            trailing: DropdownButton<int>(
              value: notificationOffsetHours,
              // Disable dropdown if notifications are off
              onChanged: notificationsEnabled ? onOffsetChanged : null,
              items: <int>[1, 2, 4] // Allowed hour offsets
                  .map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value hour${value > 1 ? 's' : ''}'),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
           ListTile(
             enabled: notificationsEnabled,
             leading: Icon(
               Icons.notification_important_outlined,
               color: enabledIconColor,
             ),
             title: Text(
               'Test Notification',
               style: TextStyle(color: enabledColor),
             ),
             trailing: ElevatedButton(
               // Disable button if notifications are off
               onPressed: notificationsEnabled ? onTestNotification : null,
               child: const Text('Send Test'),
             ),
           ),
        ],
      ),
    );
  }
} 