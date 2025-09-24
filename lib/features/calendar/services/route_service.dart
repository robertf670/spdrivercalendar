import 'package:flutter/services.dart';

class RouteService {
  // Cache for parsed CSV route data: Key = filename, Value = Map<ShiftCode, RouteInfo>
  static final Map<String, Map<String, RouteInfo>> _routeCache = {};

  /// Get route information for a duty
  /// Returns null if no route information is available
  static Future<RouteInfo?> getRouteInfo(String shiftCode) async {
    try {
      // Handle different shift types
      if (shiftCode.startsWith('PZ1/')) {
        return await _getPZ1RouteInfo(shiftCode);
      } else if (shiftCode.startsWith('PZ4/')) {
        return await _getPZ4RouteInfo(shiftCode);
      } else if (RegExp(r'^\d+/').hasMatch(shiftCode)) {
        // UNI duties (e.g., 307/01, 807/90) - no route info available
        return null;
      } else {
        // Other duty types (BusCheck, etc.) - no route info
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Extract route info for PZ1 duties from location codes
  static Future<RouteInfo?> _getPZ1RouteInfo(String shiftCode) async {
    try {
      const fileName = 'M-F_DUTIES_PZ1.csv';
      
      // Check cache first
      if (_routeCache.containsKey(fileName)) {
        return _routeCache[fileName]![shiftCode];
      }

      // Load and parse CSV
      final csvData = await rootBundle.loadString('assets/$fileName');
      final lines = csvData.split('\n');
      final Map<String, RouteInfo> parsedRoutes = {};

      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length >= 12) {
          final currentShiftCode = parts[0].trim();
          
          // Extract route from break and finish locations
          // Column 5: startbreak, Column 6: startbreaklocation, Column 9: finishbreaklocation, Column 11: finishlocation
          final startBreak = parts.length > 5 ? parts[5].trim() : '';
          final breakLocation = parts.length > 6 ? parts[6].trim() : '';
          final afterBreakLocation = parts.length > 9 ? parts[9].trim() : '';
          final finishLocation = parts.length > 11 ? parts[11].trim() : '';

          final firstRoute = _extractRouteFromLocation(breakLocation);
          final secondRoute = _extractRouteFromLocation(afterBreakLocation) ?? 
                            _extractRouteFromLocation(finishLocation);

          // Determine if this is a WORKOUT duty (startbreak is 'nan')
          final isWorkout = startBreak.toLowerCase() == 'nan';

          RouteInfo? routeInfo;
          if (isWorkout) {
            // For WORKOUT duties, only show single route if available
            final singleRoute = secondRoute ?? firstRoute;
            if (singleRoute != null) {
              routeInfo = RouteInfo(
                firstRoute: singleRoute,
                secondRoute: null,
                isWorkout: true,
              );
            }
          } else {
            // For regular duties, show both routes
            if (firstRoute != null || secondRoute != null) {
              routeInfo = RouteInfo(
                firstRoute: firstRoute,
                secondRoute: secondRoute,
                isWorkout: false,
              );
            }
          }

          if (routeInfo != null) {
            parsedRoutes[currentShiftCode] = routeInfo;
          }
        }
      }

      // Cache the results
      _routeCache[fileName] = parsedRoutes;
      return parsedRoutes[shiftCode];
    } catch (e) {
      return null;
    }
  }

  /// Extract route info for PZ4 duties from location codes with route numbers in parentheses
  static Future<RouteInfo?> _getPZ4RouteInfo(String shiftCode) async {
    try {
      const fileName = 'M-F_DUTIES_PZ4.csv';
      
      // Check cache first
      if (_routeCache.containsKey(fileName)) {
        return _routeCache[fileName]![shiftCode];
      }

      // Load and parse CSV
      final csvData = await rootBundle.loadString('assets/$fileName');
      final lines = csvData.split('\n');
      final Map<String, RouteInfo> parsedRoutes = {};

      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length >= 12) {
          final currentShiftCode = parts[0].trim();
          
          // Extract route from break and after-break locations
          // Column 5: startbreak, Column 6: startbreaklocation, Column 9: finishbreaklocation, Column 11: finishlocation
          final startBreak = parts.length > 5 ? parts[5].trim() : '';
          final breakLocation = parts.length > 6 ? parts[6].trim() : '';
          final afterBreakLocation = parts.length > 9 ? parts[9].trim() : '';
          final finishLocation = parts.length > 11 ? parts[11].trim() : '';

          final firstRoute = _extractRouteFromPZ4Location(breakLocation);
          final secondRoute = _extractRouteFromPZ4Location(afterBreakLocation) ?? 
                            _extractRouteFromPZ4Location(finishLocation);

          // Determine if this is a WORKOUT duty
          final isWorkout = startBreak.toUpperCase() == 'WORKOUT';

          RouteInfo? routeInfo;
          if (isWorkout) {
            // For WORKOUT duties, only show single route if available
            final singleRoute = secondRoute ?? firstRoute;
            if (singleRoute != null) {
              routeInfo = RouteInfo(
                firstRoute: singleRoute,
                secondRoute: null,
                isWorkout: true,
              );
            }
          } else {
            // For regular duties, show both routes
            if (firstRoute != null || secondRoute != null) {
              routeInfo = RouteInfo(
                firstRoute: firstRoute,
                secondRoute: secondRoute,
                isWorkout: false,
              );
            }
          }

          if (routeInfo != null) {
            parsedRoutes[currentShiftCode] = routeInfo;
          }
        }
      }

      // Cache the results
      _routeCache[fileName] = parsedRoutes;
      return parsedRoutes[shiftCode];
    } catch (e) {
      return null;
    }
  }

  /// Extract route from PZ1 location code (e.g., "39A-BWALK" -> "39A")
  static String? _extractRouteFromLocation(String location) {
    if (location.isEmpty || 
        location.toLowerCase() == 'nan' || 
        location.toUpperCase() == 'GARAGE') {
      return null;
    }

    final dashIndex = location.indexOf('-');
    if (dashIndex > 0) {
      return location.substring(0, dashIndex).replaceAll('/', '-');
    }

    return null;
  }

  /// Extract route from PZ4 location code (e.g., "PSQW-PE(9)" -> "9")
  static String? _extractRouteFromPZ4Location(String location) {
    if (location.isEmpty || 
        location.toLowerCase() == 'nan' || 
        location.toUpperCase() == 'GARAGE' ||
        location.toUpperCase() == 'WORKOUT') {
      return null;
    }

    // Look for route number in parentheses
    final match = RegExp(r'\((\d+)\)').firstMatch(location);
    if (match != null) {
      return match.group(1);
    }

    return null;
  }

  /// Clear the route cache (useful for testing or memory management)
  static void clearCache() {
    _routeCache.clear();
  }
}

/// Class to hold route information for a duty
class RouteInfo {
  final String? firstRoute;
  final String? secondRoute;
  final bool isWorkout;

  RouteInfo({
    this.firstRoute,
    this.secondRoute,
    required this.isWorkout,
  });

  /// Format route information for display
  String formatForDisplay() {
    if (isWorkout) {
      // Single route format for WORKOUT duties
      final route = _formatRouteDisplay(firstRoute);
      return route ?? '';
    } else {
      // First/Second route format for regular duties
      final first = _formatRouteDisplay(firstRoute) ?? '';
      final second = _formatRouteDisplay(secondRoute) ?? '';
      
      // Don't show route info if both are empty
      if (first.isEmpty && second.isEmpty) {
        return '';
      }
      
      return '$first • $second';
    }
  }

  /// Format individual route for display (e.g., "C1-C2" -> "C")
  String? _formatRouteDisplay(String? route) {
    if (route == null) return null;
    
    // Convert "C1-C2" or "C1/C2" to "C"
    if (route.startsWith('C') && (route.contains('-') || route.contains('/'))) {
      return "C";
    }
    
    return route;
  }

  @override
  String toString() {
    return 'RouteInfo(first: $firstRoute, second: $secondRoute, isWorkout: $isWorkout)';
  }
}
