import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class AppSettingsCard extends StatelessWidget {
  final VoidCallback onShowWelcomePage;

  const AppSettingsCard({super.key, required this.onShowWelcomePage});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Show Welcome Page'),
        subtitle: const Text('View app introduction'),
        onTap: onShowWelcomePage,
      ),
    );
  }
} 
