import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    // 'BC': Color(0xFF4DB6AC), // Bus Check - Teal <-- Commented out as BC shifts use standard roster colors
  };

  // Add holiday color constant
  static const Color holidayColor = Color(0xFF00BCD4); // Teal color for holidays

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
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
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
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: Color(0xFF121212),
        surfaceContainerLow: Color(0xFF1A1A1A),
        surfaceContainer: Color(0xFF1E1E1E),
        surfaceContainerHigh: Color(0xFF232323),
        surfaceContainerHighest: Color(0xFF2A2A2A),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFB0B0B0),
        outline: Color(0xFF555555),
        outlineVariant: Color(0xFF333333),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F), // Darker AppBar for contrast
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF121212),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardTheme(
        // Ensure card color provides contrast with background in dark mode
        color: const Color(0xFF1E1E1E), // Better dark card color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      // Add DropdownMenuTheme for dark mode styling
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: Colors.white), // Ensure dropdown text is white
        inputDecorationTheme: const InputDecorationTheme( // Style the dropdown button appearance if needed
          labelStyle: TextStyle(color: Colors.white70), // Style label if applicable
          hintStyle: TextStyle(color: Colors.white70), // Style hint text if applicable
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFF2A2A2A)), // Better dark menu background
          surfaceTintColor: WidgetStateProperty.all(const Color(0xFF2A2A2A)), // Optional: blend color
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(borderRadius / 2),
          )),
        ),
      ),
      // Add snackbar theme for dark mode
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
        ),
      ),
      // Add dialog theme for dark mode
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      // Add input decoration theme for dark mode
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
          borderSide: const BorderSide(color: Color(0xFF555555)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
          borderSide: const BorderSide(color: Color(0xFF555555)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius / 2),
          borderSide: const BorderSide(color: primaryColor),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
    );
  }
}
