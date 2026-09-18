import 'package:flutter/material.dart';
import 'package:spdrivercalendar/services/color_customization_service.dart';
import 'package:spdrivercalendar/theme/app_theme.dart';

/// Roster, sick, and a few extra colours for the day-colour sheet.
List<Color> dayColorSwatches() {
  final colors = ColorCustomizationService.getShiftColors();
  final candidates = <Color>[
    colors['E'] ?? AppTheme.shiftColors['E']!,
    colors['L'] ?? AppTheme.shiftColors['L']!,
    colors['M'] ?? AppTheme.shiftColors['M']!,
    colors['R'] ?? AppTheme.shiftColors['R']!,
    colors['W'] ?? const Color(0xFF66BB6A),
    colors['WFO'] ?? const Color(0xFFFF6B6B),
    colors['SICK_NORMAL'] ?? const Color(0xFFE53935),
    colors['SICK_SELF_CERTIFIED'] ?? const Color(0xFFFFB300),
    colors['DAY_IN_LIEU'] ?? const Color(0xFF3F51B5),
    colors['WORKOUT'] ?? const Color(0xFF26A69A),
    AppTheme.holidayColor,
    const Color(0xFF795548),
    const Color(0xFFEC407A),
    const Color(0xFF607D8B),
  ];

  final seen = <int>{};
  final unique = <Color>[];
  for (final color in candidates) {
    if (seen.add(color.toARGB32())) {
      unique.add(color);
    }
  }
  return unique;
}
