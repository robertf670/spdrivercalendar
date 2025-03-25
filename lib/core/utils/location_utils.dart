import 'package:spdrivercalendar/core/constants/location_constants.dart';

String mapLocationName(String location) {
  if (location.isEmpty) return '';
  
  final loc = location.toUpperCase().trim();
  print('DEBUG - Mapping location: $loc');
  
  // Try exact match first
  if (locationMappings.containsKey(loc)) {
    print('DEBUG - Found exact match: ${locationMappings[loc]}');
    return locationMappings[loc]!;
  }
  
  // Handle locations with route numbers in parentheses (e.g., "PSQE-PQ(122)")
  if (loc.contains('(') && loc.contains(')')) {
    // Remove the route number part
    final baseLocation = loc.split('(')[0].trim();
    print('DEBUG - Found location with route number: $baseLocation');
    
    // Try to map the base location
    if (locationMappings.containsKey(baseLocation)) {
      print('DEBUG - Found match for base location: ${locationMappings[baseLocation]}');
      return locationMappings[baseLocation]!;
    }
  }
  
  // Handle locations with route numbers (e.g., "39A-ASTONQ")
  if (loc.contains('-')) {
    // Get the part after the dash (the actual location)
    final locationPart = loc.split('-').last.trim();
    print('DEBUG - Found location with dash: $locationPart');
    
    // Try to map just the location part
    if (locationMappings.containsKey(locationPart)) {
      print('DEBUG - Found match for location part: ${locationMappings[locationPart]}');
      return locationMappings[locationPart]!;
    }
    
    // Try to map the full location with route
    if (locationMappings.containsKey(loc)) {
      print('DEBUG - Found match for full location: ${locationMappings[loc]}');
      return locationMappings[loc]!;
    }
  }
  
  // Handle compound locations (e.g., "C1/C2-BWALK")
  if (loc.contains('/')) {
    final parts = loc.split('-');
    if (parts.length > 1) {
      final locationPart = parts.last.trim();
      print('DEBUG - Found compound location: $locationPart');
      if (locationMappings.containsKey(locationPart)) {
        print('DEBUG - Found match for compound location: ${locationMappings[locationPart]}');
        return locationMappings[locationPart]!;
      }
    }
  }
  
  print('DEBUG - No match found, returning original: $loc');
  return location;
}
