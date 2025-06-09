import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ColorCustomizationService {
  static const String _earlyColorKey = 'custom_early_color';
  static const String _lateColorKey = 'custom_late_color';
  static const String _middleColorKey = 'custom_middle_color';
  static const String _restColorKey = 'custom_rest_color';

  // Default colors from AppTheme
  static const Color _defaultEarlyColor = Color(0xFF66BB6A);  // Green
  static const Color _defaultLateColor = Color(0xFFFF9800);   // Orange
  static const Color _defaultMiddleColor = Color(0xFF9575CD); // Purple
  static const Color _defaultRestColor = Color(0xFF42A5F5);   // Blue

  static Map<String, Color> _customColors = {};
  static bool _isInitialized = false;
  
  // Add callback for color changes
  static VoidCallback? _onColorsChanged;

  /// Initialize the service and load custom colors from SharedPreferences
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    _customColors = {
      'E': Color(prefs.getInt(_earlyColorKey) ?? _defaultEarlyColor.toARGB32()),
      'L': Color(prefs.getInt(_lateColorKey) ?? _defaultLateColor.toARGB32()),
      'M': Color(prefs.getInt(_middleColorKey) ?? _defaultMiddleColor.toARGB32()),
      'R': Color(prefs.getInt(_restColorKey) ?? _defaultRestColor.toARGB32()),
    };
    
    _isInitialized = true;
  }

  /// Set callback to be called when colors change
  static void setColorChangeCallback(VoidCallback callback) {
    _onColorsChanged = callback;
  }

  /// Clear color change callback
  static void clearColorChangeCallback() {
    _onColorsChanged = null;
  }

  /// Get current custom colors or default colors if not customized
  static Map<String, Color> getShiftColors() {
    if (!_isInitialized) {
      // Return default colors if not initialized
      return Map.from(AppTheme.shiftColors);
    }
    return Map.from(_customColors);
  }

  /// Get color for a specific shift type
  static Color getColorForShift(String shiftType) {
    if (!_isInitialized) {
      return AppTheme.shiftColors[shiftType] ?? _defaultRestColor;
    }
    return _customColors[shiftType] ?? AppTheme.shiftColors[shiftType] ?? _defaultRestColor;
  }

  /// Set custom color for a shift type
  static Future<void> setShiftColor(String shiftType, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    
    _customColors[shiftType] = color;
    
    // Save to SharedPreferences
    switch (shiftType) {
      case 'E':
        await prefs.setInt(_earlyColorKey, color.toARGB32());
        break;
      case 'L':
        await prefs.setInt(_lateColorKey, color.toARGB32());
        break;
      case 'M':
        await prefs.setInt(_middleColorKey, color.toARGB32());
        break;
      case 'R':
        await prefs.setInt(_restColorKey, color.toARGB32());
        break;
    }
    
    // Notify listeners of color changes
    _onColorsChanged?.call();
  }

  /// Reset all colors to defaults
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove custom color preferences
    await prefs.remove(_earlyColorKey);
    await prefs.remove(_lateColorKey);
    await prefs.remove(_middleColorKey);
    await prefs.remove(_restColorKey);
    
    // Reset to default colors
    _customColors = {
      'E': _defaultEarlyColor,
      'L': _defaultLateColor,
      'M': _defaultMiddleColor,
      'R': _defaultRestColor,
    };
    
    // Notify listeners of color changes
    _onColorsChanged?.call();
  }

  /// Check if colors have been customized (different from defaults)
  static bool hasCustomColors() {
    if (!_isInitialized) return false;
    
    return _customColors['E'] != _defaultEarlyColor ||
           _customColors['L'] != _defaultLateColor ||
           _customColors['M'] != _defaultMiddleColor ||
           _customColors['R'] != _defaultRestColor;
  }

  /// Get default colors map
  static Map<String, Color> getDefaultColors() {
    return {
      'E': _defaultEarlyColor,
      'L': _defaultLateColor,
      'M': _defaultMiddleColor,
      'R': _defaultRestColor,
    };
  }

  /// Export custom colors for backup
  static Map<String, dynamic> exportColors() {
    return {
      'customShiftColors': {
        'E': _customColors['E']?.toARGB32(),
        'L': _customColors['L']?.toARGB32(),
        'M': _customColors['M']?.toARGB32(),
        'R': _customColors['R']?.toARGB32(),
      }
    };
  }

  /// Import custom colors from backup
  static Future<void> importColors(Map<String, dynamic> data) async {
    if (data['customShiftColors'] != null) {
      final colorData = data['customShiftColors'];
      
      if (colorData['E'] != null) await setShiftColor('E', Color(colorData['E']));
      if (colorData['L'] != null) await setShiftColor('L', Color(colorData['L']));
      if (colorData['M'] != null) await setShiftColor('M', Color(colorData['M']));
      if (colorData['R'] != null) await setShiftColor('R', Color(colorData['R']));
    }
  }
} 
