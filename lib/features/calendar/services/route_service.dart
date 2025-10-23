import 'package:flutter/services.dart';
import 'package:spdrivercalendar/features/calendar/services/roster_service.dart';

class RouteService {
  // Cache for parsed CSV route data: Key = filename, Value = Map<ShiftCode, RouteInfo>
  static final Map<String, Map<String, RouteInfo>> _routeCache = {};

  /// Get route information for a duty
  /// Returns null if no route information is available
  static Future<RouteInfo?> getRouteInfo(String shiftCode, DateTime eventDate) async {
    try {
      // Handle different shift types
      if (shiftCode.startsWith('PZ1/')) {
        return await _getPZ1RouteInfo(shiftCode, eventDate);
      } else if (shiftCode.startsWith('PZ4/')) {
        return await _getPZ4RouteInfo(shiftCode, eventDate);
      } else if (RegExp(r'^\d+/').hasMatch(shiftCode)) {
        // UNI duties (e.g., 307/01, 807/90) - extract route info from CSV
        return await _getUNIRouteInfo(shiftCode, eventDate);
      } else {
        // Other duty types (BusCheck, etc.) - no route info
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Helper method to determine the correct CSV filename based on date and zone
  /// Uses RosterService.getShiftFilename to ensure consistent file selection
  /// including the Zone 4 Route 23/24 changeover logic
  static String _getRouteFilename(String zoneNumber, DateTime eventDate) {
    // Get day of week in RosterService format
    final dayOfWeek = RosterService.getDayOfWeek(eventDate);
    
    // Convert to the abbreviated format expected by getShiftFilename
    String dayOfWeekForFilename;
    if (dayOfWeek == 'Saturday') {
      dayOfWeekForFilename = 'SAT';
    } else if (dayOfWeek == 'Sunday') {
      dayOfWeekForFilename = 'SUN';
    } else {
      dayOfWeekForFilename = 'M-F';
    }
    
    // Use RosterService to get the correct filename
    // This automatically handles Zone 4 Route 23/24 changeover on Oct 19, 2025
    return RosterService.getShiftFilename(zoneNumber, dayOfWeekForFilename, eventDate);
  }

  /// Extract route info for PZ1 duties from location codes
  static Future<RouteInfo?> _getPZ1RouteInfo(String shiftCode, DateTime eventDate) async {
    try {
      final fileName = _getRouteFilename('1', eventDate);
      
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
          
          // Extract route from locations
          // Column 4: location (start location), Column 5: startbreak, Column 6: startbreaklocation, 
          // Column 9: finishbreaklocation, Column 11: finishlocation
          final startLocation = parts.length > 4 ? parts[4].trim() : '';
          final startBreak = parts.length > 5 ? parts[5].trim() : '';
          final breakLocation = parts.length > 6 ? parts[6].trim() : '';
          final afterBreakLocation = parts.length > 9 ? parts[9].trim() : '';
          final finishLocation = parts.length > 11 ? parts[11].trim() : '';

          final firstRoute = _extractRouteFromLocation(breakLocation) ?? 
                           _extractRouteFromLocation(startLocation);
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
  static Future<RouteInfo?> _getPZ4RouteInfo(String shiftCode, DateTime eventDate) async {
    try {
      final fileName = _getRouteFilename('4', eventDate);
      
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
          
          // Extract route from locations
          // Column 4: location, Column 5: startbreak, Column 6: startbreaklocation, Column 9: finishbreaklocation, Column 11: finishlocation
          final location = parts.length > 4 ? parts[4].trim() : '';
          final startBreak = parts.length > 5 ? parts[5].trim() : '';
          final breakLocation = parts.length > 6 ? parts[6].trim() : '';
          final afterBreakLocation = parts.length > 9 ? parts[9].trim() : '';
          final finishLocation = parts.length > 11 ? parts[11].trim() : '';

          // Determine if this is a WORKOUT duty
          final isWorkout = startBreak.toUpperCase() == 'WORKOUT';

          RouteInfo? routeInfo;
          if (isWorkout) {
            // For WORKOUT duties, check location, finishLocation, or breakLocation for route
            final singleRoute = _extractRouteFromPZ4Location(location) ??
                              _extractRouteFromPZ4Location(finishLocation) ??
                              _extractRouteFromPZ4Location(breakLocation);
            if (singleRoute != null) {
              routeInfo = RouteInfo(
                firstRoute: singleRoute,
                secondRoute: null,
                isWorkout: true,
              );
            }
          } else {
            // For regular duties, extract first and second half routes
            final firstRoute = _extractRouteFromPZ4Location(breakLocation) ??
                             _extractRouteFromPZ4Location(location);
            final secondRoute = _extractRouteFromPZ4Location(afterBreakLocation) ?? 
                              _extractRouteFromPZ4Location(finishLocation);
            
            // Show both routes
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

  /// Extract route from PZ1 location code (e.g., "39A-BWALK" -> "39A", "C1/C2-ASTONQ" -> "C")
  static String? _extractRouteFromLocation(String location) {
    if (location.isEmpty || 
        location.toLowerCase() == 'nan' || 
        location.toUpperCase() == 'GARAGE') {
      return null;
    }

    final dashIndex = location.indexOf('-');
    if (dashIndex > 0) {
      String route = location.substring(0, dashIndex);
      
      // Simplify compound routes like "C1/C2" to just "C" or "1/C2" to just "C"
      if (route.contains('/')) {
        // Extract the letter part (e.g., "C" from "C1/C2" or "1/C2")
        final match = RegExp(r'([A-Z]+)').firstMatch(route);
        if (match != null) {
          return match.group(1);
        }
      }
      
      return route;
    }

    return null;
  }

  /// Extract route from PZ4 location code (e.g., "PSQW-PE(9)" -> "9", "Garage(24)" -> "24")
  static String? _extractRouteFromPZ4Location(String location) {
    if (location.isEmpty || location.toLowerCase() == 'nan') {
      return null;
    }

    // Look for route number in parentheses
    final match = RegExp(r'\((\d+)\)').firstMatch(location);
    if (match != null) {
      return match.group(1);
    }

    // No route found - return null for locations without route numbers
    // (e.g., plain "Garage", "WORKOUT", "ConHill #1619" without parentheses)
    return null;
  }

  /// Extract route info for UNI duties from routes column
  static Future<RouteInfo?> _getUNIRouteInfo(String shiftCode, DateTime eventDate) async {
    try {
      // Determine which file(s) to check based on day of week
      final dayOfWeek = RosterService.getDayOfWeek(eventDate);
      final isWeekend = dayOfWeek == 'Saturday' || dayOfWeek == 'Sunday';
      
      List<String> filesToTry = ['UNI_7DAYs.csv'];
      if (!isWeekend) {
        filesToTry.add('UNI_M-F.csv');
      }
      
      for (final fileName in filesToTry) {
        // Check cache first
        if (_routeCache.containsKey(fileName)) {
          final cached = _routeCache[fileName]![shiftCode];
          if (cached != null) {
            return cached;
          }
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
          if (parts.length >= 15) {
            final currentShiftCode = parts[0].trim();
            
            // New 17-column format: shift,duty,report,depart,location,startbreak,startbreaklocation,breakreport,finishbreak,finishbreaklocation,finish,finishlocation,signoff,spread,work,relief,routes
            final startBreak = parts.length > 5 ? parts[5].trim() : '';
            final routesStr = parts.length > 16 ? parts[16].trim() : '';
            
            // Determine if this is a WORKOUT duty
            final isWorkout = startBreak.toUpperCase() == 'WORKOUT';

            RouteInfo? routeInfo;
            if (routesStr.isNotEmpty && routesStr.toLowerCase() != 'nan') {
              // For UNI duties, the routes column might contain single route or multiple routes separated by /
              if (isWorkout) {
                // WORKOUT duties typically have one route
                routeInfo = RouteInfo(
                  firstRoute: routesStr,
                  secondRoute: null,
                  isWorkout: true,
                );
              } else {
                // Regular duties with breaks - check if there are multiple routes
                final routeParts = routesStr.split('/');
                if (routeParts.length >= 3) {
                  // Three or more routes (e.g., "L58/L59/C3") - store all routes in firstRoute
                  routeInfo = RouteInfo(
                    firstRoute: routesStr,  // Keep all routes together
                    secondRoute: null,
                    isWorkout: false,
                  );
                } else if (routeParts.length == 2) {
                  // Two routes (e.g., "X26/C1")
                  routeInfo = RouteInfo(
                    firstRoute: routeParts[0].trim(),
                    secondRoute: routeParts[1].trim(),
                    isWorkout: false,
                  );
                } else {
                  // Single route for both halves
                  routeInfo = RouteInfo(
                    firstRoute: routesStr,
                    secondRoute: routesStr,
                    isWorkout: false,
                  );
                }
              }
            }

            if (routeInfo != null) {
              parsedRoutes[currentShiftCode] = routeInfo;
            }
          }
        }

        // Cache the parsed routes
        _routeCache[fileName] = parsedRoutes;

        // If we found the shift in this file, return it
        if (parsedRoutes.containsKey(shiftCode)) {
          return parsedRoutes[shiftCode];
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
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
    } else if (firstRoute != null && firstRoute!.contains('/') && secondRoute == null) {
      // Handle duties with 3+ routes (e.g., "L58/L59/C3")
      // Split, format each route, and join with bullet separator
      final routeParts = firstRoute!.split('/');
      final formattedRoutes = routeParts
          .map((r) => _formatRouteDisplay(r.trim()))
          .where((r) => r != null && r.isNotEmpty)
          .join(' • ');
      return formattedRoutes;
    } else {
      // First/Second route format for regular duties with 2 routes
      final first = _formatRouteDisplay(firstRoute) ?? '';
      final second = _formatRouteDisplay(secondRoute) ?? '';
      
      // Don't show route info if both are empty
      if (first.isEmpty && second.isEmpty) {
        return '';
      }
      
      // Special handling for routes 23 and 24 - always show as "23/24"
      if ((first == '23' || first == '24') && (second == '23' || second == '24')) {
        return '23/24';
      }
      
      // Always show both routes with bullet separator (even if they're the same)
      return '$first • $second';
    }
  }

  /// Format individual route for display (e.g., "C1-C2" -> "C")
  String? _formatRouteDisplay(String? route) {
    if (route == null) return null;
    
    // Remove " N-Service" suffix
    String cleanRoute = route.replaceAll(' N-Service', '').trim();
    
    // Convert "C1-C2" or "C1/C2" to "C"
    if (cleanRoute.startsWith('C') && (cleanRoute.contains('-') || cleanRoute.contains('/'))) {
      return "C";
    }
    
    return cleanRoute;
  }

  @override
  String toString() {
    return 'RouteInfo(first: $firstRoute, second: $secondRoute, isWorkout: $isWorkout)';
  }
}
