import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ColorCustomizationService {
  static const String _earlyColorKey = 'custom_early_color';
  static const String _lateColorKey = 'custom_late_color';
  static const String _middleColorKey = 'custom_middle_color';
  static const String _restColorKey = 'custom_rest_color';
  static const String _workColorKey = 'custom_work_color';
  static const String _wfoColorKey = 'custom_wfo_color';
  static const String _dayInLieuColorKey = 'custom_day_in_lieu_color';
  static const String _sickNormalColorKey = 'custom_sick_normal_color';
  static const String _sickSelfCertifiedColorKey = 'custom_sick_self_certified_color';
  static const String _sickForceMajeureColorKey = 'custom_sick_force_majeure_color';

  // Default colors from AppTheme
  static const Color _defaultEarlyColor = Color(0xFF66BB6A);  // Green
  static const Color _defaultLateColor = Color(0xFFFF9800);   // Orange
  static const Color _defaultMiddleColor = Color(0xFF9575CD); // Purple
  static const Color _defaultRestColor = Color(0xFF42A5F5);   // Blue
  static const Color _defaultWorkColor = Color(0xFF66BB6A);   // Green (same as Early)
  static const Color _defaultWfoColor = Color(0xFFFF6B6B);   // Coral/Red-Pink for Work For Others (distinct from holidays)
  static const Color _defaultDayInLieuColor = Color(0xFF3F51B5);   // Indigo for Day In Lieu (distinct from unpaid leave purple)
  static const Color _defaultSickNormalColor = Color(0xFFE53935);   // Red for Normal Sick (distinct from Late orange)
  static const Color _defaultSickSelfCertifiedColor = Color(0xFFFFB300);   // Amber/Yellow for Self-Certified (distinct from all shift colors)
  static const Color _defaultSickForceMajeureColor = Color(0xFFC2185B);   // Deep Pink/Magenta for Force Majeure (distinct from all)

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
      'W': Color(prefs.getInt(_workColorKey) ?? _defaultWorkColor.toARGB32()),
      'WFO': Color(prefs.getInt(_wfoColorKey) ?? _defaultWfoColor.toARGB32()),
      'DAY_IN_LIEU': Color(prefs.getInt(_dayInLieuColorKey) ?? _defaultDayInLieuColor.toARGB32()),
      'SICK_NORMAL': Color(prefs.getInt(_sickNormalColorKey) ?? _defaultSickNormalColor.toARGB32()),
      'SICK_SELF_CERTIFIED': Color(prefs.getInt(_sickSelfCertifiedColorKey) ?? _defaultSickSelfCertifiedColor.toARGB32()),
      'SICK_FORCE_MAJEURE': Color(prefs.getInt(_sickForceMajeureColorKey) ?? _defaultSickForceMajeureColor.toARGB32()),
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
      final defaultColors = Map<String, Color>.from(AppTheme.shiftColors);
      defaultColors['W'] = _defaultWorkColor;
      defaultColors['WFO'] = _defaultWfoColor;
      defaultColors['DAY_IN_LIEU'] = _defaultDayInLieuColor;
      defaultColors['SICK_NORMAL'] = _defaultSickNormalColor;
      defaultColors['SICK_SELF_CERTIFIED'] = _defaultSickSelfCertifiedColor;
      defaultColors['SICK_FORCE_MAJEURE'] = _defaultSickForceMajeureColor;
      return defaultColors;
    }
    return Map.from(_customColors);
  }

  /// Get color for a specific shift type
  static Color getColorForShift(String shiftType) {
    if (!_isInitialized) {
      if (shiftType == 'W') return _defaultWorkColor;
      if (shiftType == 'WFO') return _defaultWfoColor;
      if (shiftType == 'DAY_IN_LIEU') return _defaultDayInLieuColor;
      if (shiftType == 'SICK_NORMAL') return _defaultSickNormalColor;
      if (shiftType == 'SICK_SELF_CERTIFIED') return _defaultSickSelfCertifiedColor;
      if (shiftType == 'SICK_FORCE_MAJEURE') return _defaultSickForceMajeureColor;
      return AppTheme.shiftColors[shiftType] ?? _defaultRestColor;
    }
    return _customColors[shiftType] ?? AppTheme.shiftColors[shiftType] ?? 
      (shiftType == 'W' ? _defaultWorkColor : 
       (shiftType == 'WFO' ? _defaultWfoColor : 
        (shiftType == 'DAY_IN_LIEU' ? _defaultDayInLieuColor :
         (shiftType == 'SICK_NORMAL' ? _defaultSickNormalColor :
          (shiftType == 'SICK_SELF_CERTIFIED' ? _defaultSickSelfCertifiedColor :
           (shiftType == 'SICK_FORCE_MAJEURE' ? _defaultSickForceMajeureColor : _defaultRestColor))))));
  }
  
  /// Get color for a sick day type (converts from event sickDayType to color key)
  static Color getColorForSickType(String? sickDayType) {
    if (sickDayType == null) return _defaultRestColor;
    switch (sickDayType) {
      case 'normal':
        return getColorForShift('SICK_NORMAL');
      case 'self-certified':
        return getColorForShift('SICK_SELF_CERTIFIED');
      case 'force-majeure':
        return getColorForShift('SICK_FORCE_MAJEURE');
      default:
        return _defaultSickNormalColor;
    }
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
      case 'W':
        await prefs.setInt(_workColorKey, color.toARGB32());
        break;
      case 'WFO':
        await prefs.setInt(_wfoColorKey, color.toARGB32());
        break;
      case 'DAY_IN_LIEU':
        await prefs.setInt(_dayInLieuColorKey, color.toARGB32());
        break;
      case 'SICK_NORMAL':
        await prefs.setInt(_sickNormalColorKey, color.toARGB32());
        break;
      case 'SICK_SELF_CERTIFIED':
        await prefs.setInt(_sickSelfCertifiedColorKey, color.toARGB32());
        break;
      case 'SICK_FORCE_MAJEURE':
        await prefs.setInt(_sickForceMajeureColorKey, color.toARGB32());
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
    await prefs.remove(_workColorKey);
    await prefs.remove(_wfoColorKey);
    await prefs.remove(_dayInLieuColorKey);
    await prefs.remove(_sickNormalColorKey);
    await prefs.remove(_sickSelfCertifiedColorKey);
    await prefs.remove(_sickForceMajeureColorKey);
    
    // Reset to default colors
    _customColors = {
      'E': _defaultEarlyColor,
      'L': _defaultLateColor,
      'M': _defaultMiddleColor,
      'R': _defaultRestColor,
      'W': _defaultWorkColor,
      'WFO': _defaultWfoColor,
      'DAY_IN_LIEU': _defaultDayInLieuColor,
      'SICK_NORMAL': _defaultSickNormalColor,
      'SICK_SELF_CERTIFIED': _defaultSickSelfCertifiedColor,
      'SICK_FORCE_MAJEURE': _defaultSickForceMajeureColor,
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
           _customColors['R'] != _defaultRestColor ||
           _customColors['W'] != _defaultWorkColor ||
           _customColors['WFO'] != _defaultWfoColor ||
           _customColors['DAY_IN_LIEU'] != _defaultDayInLieuColor ||
           _customColors['SICK_NORMAL'] != _defaultSickNormalColor ||
           _customColors['SICK_SELF_CERTIFIED'] != _defaultSickSelfCertifiedColor ||
           _customColors['SICK_FORCE_MAJEURE'] != _defaultSickForceMajeureColor;
  }

  /// Get default colors map
  static Map<String, Color> getDefaultColors() {
    return {
      'E': _defaultEarlyColor,
      'L': _defaultLateColor,
      'M': _defaultMiddleColor,
      'R': _defaultRestColor,
      'W': _defaultWorkColor,
      'WFO': _defaultWfoColor,
      'DAY_IN_LIEU': _defaultDayInLieuColor,
      'SICK_NORMAL': _defaultSickNormalColor,
      'SICK_SELF_CERTIFIED': _defaultSickSelfCertifiedColor,
      'SICK_FORCE_MAJEURE': _defaultSickForceMajeureColor,
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
      'W': _customColors['W']?.toARGB32(),
      'WFO': _customColors['WFO']?.toARGB32(),
      'DAY_IN_LIEU': _customColors['DAY_IN_LIEU']?.toARGB32(),
      'SICK_NORMAL': _customColors['SICK_NORMAL']?.toARGB32(),
      'SICK_SELF_CERTIFIED': _customColors['SICK_SELF_CERTIFIED']?.toARGB32(),
      'SICK_FORCE_MAJEURE': _customColors['SICK_FORCE_MAJEURE']?.toARGB32(),
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
      if (colorData['W'] != null) await setShiftColor('W', Color(colorData['W']));
      if (colorData['WFO'] != null) await setShiftColor('WFO', Color(colorData['WFO']));
      if (colorData['DAY_IN_LIEU'] != null) await setShiftColor('DAY_IN_LIEU', Color(colorData['DAY_IN_LIEU']));
      if (colorData['SICK_NORMAL'] != null) await setShiftColor('SICK_NORMAL', Color(colorData['SICK_NORMAL']));
      if (colorData['SICK_SELF_CERTIFIED'] != null) await setShiftColor('SICK_SELF_CERTIFIED', Color(colorData['SICK_SELF_CERTIFIED']));
      if (colorData['SICK_FORCE_MAJEURE'] != null) await setShiftColor('SICK_FORCE_MAJEURE', Color(colorData['SICK_FORCE_MAJEURE']));
    }
  }
} 
