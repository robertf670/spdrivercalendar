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
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
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
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        // Consider adding surface and background if needed for contrast
      ),
      appBarTheme: AppBarTheme(
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
        color: Colors.grey[850], // Example: Slightly lighter dark grey
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      // Add DropdownMenuTheme for dark mode styling
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: Colors.white), // Ensure dropdown text is white
        inputDecorationTheme: InputDecorationTheme( // Style the dropdown button appearance if needed
          // Example: Add border, change fill color, etc.
          // filled: true,
          // fillColor: Colors.grey[800],
          // border: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(borderRadius),
          //   borderSide: BorderSide.none,
          // ),
          labelStyle: TextStyle(color: Colors.white70), // Style label if applicable
          hintStyle: TextStyle(color: Colors.white70), // Style hint text if applicable
        ),
        menuStyle: MenuStyle(
          backgroundColor: MaterialStateProperty.all(Colors.grey[800]), // Background color of the dropdown menu
          surfaceTintColor: MaterialStateProperty.all(Colors.grey[800]), // Optional: blend color
          shape: MaterialStateProperty.all(RoundedRectangleBorder( // Consistent border radius
             borderRadius: BorderRadius.circular(borderRadius / 2), // Slightly smaller radius for menu
          )),
        ),
      ),
    );
  }
}
