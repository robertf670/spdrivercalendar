import 'package:flutter/material.dart';
import 'package:spdrivercalendar/models/shift_info.dart';

/// Builds the calendar shift-letter → colour map from customization colours.
Map<String, ShiftInfo> buildShiftInfoMap(Map<String, Color> colors) {
  return {
    'E': ShiftInfo('Early', colors['E']!),
    'L': ShiftInfo('Late', colors['L']!),
    'M': ShiftInfo('Middle', colors['M']!),
    'R': ShiftInfo('Rest', colors['R']!),
    'W': ShiftInfo('Work', colors['W']!),
    'WFO': ShiftInfo('Work For Others', colors['WFO']!),
  };
}
