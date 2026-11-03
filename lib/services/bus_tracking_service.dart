import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class BusTrackingService {
  static const String _fleetUrl = 'https://bustimes.org/operators/dublin-bus/vehicles';
  static const String _baseVehicleUrl = 'https://bustimes.org/vehicles/';

  /// Older vehicles are `ie-5503`. Newer ones, including some EA and EW
  /// buses, are `none-7423`.
  static final RegExp _vehicleIdInPath = RegExp(
    r'/vehicles/((?:ie|none)-\d+)(?!\d)',
  );

  /// Gets the bustimes.org URL for a bus without launching it
  /// Returns the URL string if found, null if not found
  static Future<String?> getBusUrl(String busNumber) async {
    try {
      // Clean and normalize the bus number
      final cleanBusNumber = busNumber.trim().toUpperCase().replaceAll(' ', '');
      
      // Try multiple approaches in order of preference
      
      // Approach 1: Try common URL patterns first (faster)
      final directUrl = await _tryDirectUrlPatterns(cleanBusNumber);
      if (directUrl != null) {
        return directUrl;
      }
      
      // Approach 2: Search the fleet page
      final vehicleUrl = await _findVehicleUrl(cleanBusNumber);
      if (vehicleUrl != null) {
        return vehicleUrl;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Attempts to track a Dublin Bus by searching the fleet page
  /// Returns true if successful, false if fallback was used
  static Future<bool> trackBus(String busNumber) async {
    try {
      // Clean and normalize the bus number
      final cleanBusNumber = busNumber.trim().toUpperCase().replaceAll(' ', '');
      
      // Try multiple approaches in order of preference
      
      // Approach 1: Try common URL patterns first (faster)
      final directUrl = await _tryDirectUrlPatterns(cleanBusNumber);
      if (directUrl != null) {
        await _launchUrl(directUrl);
        return true;
      }
      
      // Approach 2: Search the fleet page
      final vehicleUrl = await _findVehicleUrl(cleanBusNumber);
      if (vehicleUrl != null) {
        try {
          await _launchUrl(vehicleUrl);
          return true;
        } catch (e) {
          return false; // Return false since we couldn't open the specific page
        }
      } else {
        // Don't open anything if bus not found
        return false;
      }
    } catch (e) {
      // Don't open anything if error occurred
      return false;
    }
  }

  /// Try common URL patterns for Dublin Bus vehicles
  static Future<String?> _tryDirectUrlPatterns(String busNumber) async {
    // Common patterns for Dublin Bus vehicle URLs
    final patterns = [
      'ie-${busNumber.toLowerCase()}', // ie-ew132
      'ie-${busNumber.toLowerCase().replaceAll(RegExp(r'[^\d]'), '')}-${busNumber.toLowerCase().replaceAll(RegExp(r'[\d]'), '')}', // ie-132-ew
      busNumber.toLowerCase(), // ew132
      '${busNumber.substring(0, 2).toLowerCase()}-${busNumber.substring(2)}', // ew-132
    ];

    for (final pattern in patterns) {
      try {
        final testUrl = '$_baseVehicleUrl$pattern';
        
        final response = await http.head(Uri.parse(testUrl)).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          return testUrl;
        }
      } catch (e) {
        // Continue to next pattern
        continue;
      }
    }
    return null;
  }

  /// Searches the fleet page for the bus number and extracts vehicle URL
  static Future<String?> _findVehicleUrl(String busNumber) async {
    try {
      final response = await http.get(
        Uri.parse(_fleetUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final htmlContent = response.body;
        
        // First: Try exact match search with validation
        final exactVehicleId = _searchForExactMatch(htmlContent, busNumber);
        if (exactVehicleId != null) {
          return '$_baseVehicleUrl$exactVehicleId';
        }

        // Second: Try table structure search with validation
        final tableVehicleId = _searchInTableStructure(htmlContent, busNumber);
        if (tableVehicleId != null) {
          // Validate this result
          final isValid = await _validateVehicleId(tableVehicleId, busNumber);
          if (isValid) {
            return '$_baseVehicleUrl$tableVehicleId';
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Search for exact bus number matches only
  static String? _searchForExactMatch(String htmlContent, String busNumber) {
    try {
      // Only use exact match patterns - no partial matches
      final exactPatterns = [
        '>$busNumber<',           // >PA155<
        '"$busNumber"',           // "PA155"
        "'$busNumber'",           // 'PA155'
        ' $busNumber ',           // PA155 (surrounded by spaces)
        '\t$busNumber\t',         // PA155 (surrounded by tabs)
        '\n$busNumber\n',         // PA155 (surrounded by newlines)
        '<td>$busNumber</td>',    // <td>PA155</td>
        '<td> $busNumber </td>',  // <td> PA155 </td>
        '<span>$busNumber</span>', // <span>PA155</span>
        '<div>$busNumber</div>',  // <div>PA155</div>
      ];

      for (final pattern in exactPatterns) {
        var from = 0;
        while (from < htmlContent.length) {
          final index = htmlContent.indexOf(pattern, from);
          if (index == -1) break;
          final vehicleId = _vehicleIdWrapping(htmlContent, index);
          if (vehicleId != null) return vehicleId;
          from = index + pattern.length;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// The fleet number sits inside `<a href="/vehicles/none-7423">`.
  /// Take that link, not a neighbouring vehicle a few dozen characters away.
  static String? _vehicleIdWrapping(String htmlContent, int fleetIndex) {
    final before = htmlContent.substring(0, fleetIndex);
    final matches = _vehicleIdInPath.allMatches(before);
    if (matches.isEmpty) return null;
    final match = matches.last;
    final between = htmlContent.substring(match.end, fleetIndex);
    if (between.contains('</a>')) return null;
    return match.group(1);
  }

  /// Validate vehicle ID by checking its actual page (async validation)
  static Future<bool> _validateVehicleId(String vehicleId, String busNumber) async {
    try {
      // Quick validation by checking if the vehicle page contains our bus number
      final vehicleUrl = '$_baseVehicleUrl$vehicleId';
      final response = await http.head(Uri.parse(vehicleUrl)).timeout(const Duration(seconds: 3));
      
      // If the page exists (200), we assume it's valid
      // More thorough validation would require downloading the page content
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }





  /// Search for bus number in table structure (HTML tables are common for vehicle lists)
  static String? _searchInTableStructure(String htmlContent, String busNumber) {
    try {
      // Look for table rows that might contain the bus number with exact matching
      final tableRowPattern = RegExp(r'<tr[^>]*>.*?</tr>', multiLine: true, dotAll: true);
      final tableRows = tableRowPattern.allMatches(htmlContent);

      for (final row in tableRows) {
        final rowContent = row.group(0);
        if (rowContent != null) {
          // Check for exact bus number match in this row
          final exactPatterns = [
            '>$busNumber<',
            '"$busNumber"',
            "'$busNumber'",
            '\n$busNumber\n',
            '<td>$busNumber</td>',
            '<td> $busNumber </td>',
          ];

          bool hasExactMatch = false;
          for (final pattern in exactPatterns) {
            if (rowContent.contains(pattern)) {
              hasExactMatch = true;
              break;
            }
          }

          if (hasExactMatch) {
            for (final pattern in exactPatterns) {
              final index = rowContent.indexOf(pattern);
              if (index == -1) continue;
              final vehicleId = _vehicleIdWrapping(rowContent, index);
              if (vehicleId != null) return vehicleId;
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fleet-page lookup used by tests. Does not call the network.
  @visibleForTesting
  static String? findVehicleIdInFleetHtml(String htmlContent, String busNumber) {
    final clean = busNumber.trim().toUpperCase().replaceAll(' ', '');
    return _searchForExactMatch(htmlContent, clean) ??
        _searchInTableStructure(htmlContent, clean);
  }

  /// Launch URL using url_launcher
  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    
    try {
      // First, check if URL launching works at all with a simple test
      if (url.contains('bustimes.org')) {
        final testUri = Uri.parse('https://www.google.com');
        final canLaunchTest = await canLaunchUrl(testUri);
        
        if (!canLaunchTest) {
          throw Exception('URL launcher not working - cannot launch any URLs');
        }
      }
      
      // Check if we can launch the specific URL
      final canLaunch = await canLaunchUrl(uri);
      
      if (!canLaunch) {
        throw Exception('Cannot launch URL: $url (canLaunchUrl returned false)');
      }
      
      // Try different launch modes in order of preference
      
      // Method 1: Try platform default mode (most compatible)
      try {
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.platformDefault,
        );
        if (launched) {
          return;
        }
      } catch (e) {
        // Continue to next method
      }
      
      // Method 2: Try external application mode
      try {
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return;
        }
      } catch (e) {
        // Continue to next method
      }
      
      // Method 3: Try in-app web view mode
      try {
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.inAppWebView,
        );
        if (launched) {
          return;
        }
      } catch (e) {
        // Continue
      }
      
      // If all methods fail, provide detailed error
      throw Exception('All launch methods failed for $url. URI valid: ${uri.isAbsolute}, Scheme: ${uri.scheme}');
      
    } catch (e) {
      throw Exception('Could not launch $url: $e');
    }
  }
} 