import 'package:spdrivercalendar/core/constants/location_constants.dart';

String mapLocationName(String location) {
  if (location.isEmpty) return '';
  
  final loc = location.toUpperCase().trim();
  
  // Try exact match first
  if (locationMappings.containsKey(loc)) {
    return locationMappings[loc]!;
  }
  
  // Handle locations with route numbers in parentheses (e.g., "PSQE-PQ(122)")
  if (loc.contains('(') && loc.contains(')')) {
    // Remove the route number part
    final baseLocation = loc.split('(')[0].trim();
    
    // Try to map the base location
    if (locationMappings.containsKey(baseLocation)) {
      return locationMappings[baseLocation]!;
    }
  }
  
  // Handle locations with route numbers (e.g., "39A-ASTONQ")
  if (loc.contains('-')) {
    // Get the part after the dash (the actual location)
    final locationPart = loc.split('-').last.trim();
    
    // Try to map just the location part
    if (locationMappings.containsKey(locationPart)) {
      return locationMappings[locationPart]!;
    }
    
    // Try to map the full location with route
    if (locationMappings.containsKey(loc)) {
      return locationMappings[loc]!;
    }
  }
  
  // Handle compound locations (e.g., "C1/C2-BWALK")
  if (loc.contains('/')) {
    final parts = loc.split('-');
    if (parts.length > 1) {
      final locationPart = parts.last.trim();
      if (locationMappings.containsKey(locationPart)) {
        return locationMappings[locationPart]!;
      }
    }
  }
  
  return location;
}
