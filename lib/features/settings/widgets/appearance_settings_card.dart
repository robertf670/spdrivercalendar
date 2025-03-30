import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class AppearanceSettingsCard extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const AppearanceSettingsCard({
    Key? key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Toggle dark mode theme'),
        secondary: Icon(
          isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: isDarkMode ? Colors.amber : Colors.blueGrey, // Keep original colors for now
        ),
        value: isDarkMode,
        onChanged: onDarkModeChanged,
      ),
    );
  }
} 