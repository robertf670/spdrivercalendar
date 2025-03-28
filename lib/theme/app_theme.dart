import 'package:flutter/material.dart';

class AppTheme {
  // Main color palette
  static const Color primaryColor = Color(0xFF1E88E5); // Blue
  static const Color secondaryColor = Color(0xFF26A69A); // Teal
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color warningColor = Color(0xFFFFA000); // Amber
  static const Color successColor = Color(0xFF388E3C); // Green

  // Shift type colors with better contrast
  static const Map<String, Color> shiftColors = {
    'E': Color(0xFF66BB6A), // Early - Green
    'L': Color(0xFFFF9800), // Late - Orange
    'M': Color(0xFF9575CD), // Middle - Purple
    'R': Color(0xFF42A5F5), // Rest - Blue
  };

  // Border radius
  static const double borderRadius = 12.0;
  
  // Create light theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
  
  // Create dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
