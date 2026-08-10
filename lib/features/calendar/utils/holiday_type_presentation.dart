import 'package:flutter/material.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';

/// Display metadata for a holiday type in list UIs.
class HolidayTypePresentation {
  const HolidayTypePresentation({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

HolidayTypePresentation holidayTypePresentation(String type) {
  switch (type) {
    case 'winter':
      return const HolidayTypePresentation(
        label: 'Winter Holiday',
        color: Colors.blue,
        icon: Icons.ac_unit,
      );
    case 'summer':
      return const HolidayTypePresentation(
        label: 'Summer Holiday',
        color: Colors.orange,
        icon: Icons.wb_sunny,
      );
    case 'day_in_lieu':
      return HolidayTypePresentation(
        label: 'Day In Lieu',
        color: ColorCustomizationService.getColorForShift('DAY_IN_LIEU'),
        icon: Icons.event_available,
      );
    case 'unpaid':
    case 'unpaid_leave':
      return const HolidayTypePresentation(
        label: 'Unpaid Leave',
        color: Colors.purple,
        icon: Icons.money_off,
      );
    default:
      return const HolidayTypePresentation(
        label: 'Holiday',
        color: Colors.grey,
        icon: Icons.event,
      );
  }
}
