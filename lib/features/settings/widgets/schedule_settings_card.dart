import 'package:flutter/material.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

class ScheduleSettingsCard extends StatelessWidget {
  final VoidCallback onResetRestDays;

  const ScheduleSettingsCard({Key? key, required this.onResetRestDays}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: ListTile(
        leading: const Icon(Icons.refresh),
        title: const Text('Reset Rest Days'),
        subtitle: const Text('Change your shift pattern'),
        onTap: onResetRestDays,
      ),
    );
  }
} 
