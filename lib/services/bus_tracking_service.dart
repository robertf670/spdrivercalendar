import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class BusTrackingService {
  static const String _fleetUrl = 'https://bustimes.org/operators/dublin-bus/vehicles';
  static const String _baseVehicleUrl = 'https://bustimes.org/vehicles/';

  /// Gets the bustimes.org URL for a bus without launching it
  /// Returns the URL string if found, null if not found
  static Future<String?> getBusUrl(String busNumber) async {
    try {
      // Clean and normalize the bus number
      final cleanBusNumber = busNumber.trim().toUpperCase().replaceAll(' ', '');
      
      if (kDebugMode) {
        print('🚌 Getting URL for bus: $cleanBusNumber');
      }
      
      // Try multiple approaches in order of preference
      
      // Approach 1: Try common URL patterns first (faster)
      final directUrl = await _tryDirectUrlPatterns(cleanBusNumber);
      if (directUrl != null) {
        if (kDebugMode) {
          print('✅ Found via direct URL: $directUrl');
        }
        return directUrl;
      }
      
      // Approach 2: Search the fleet page
      final vehicleUrl = await _findVehicleUrl(cleanBusNumber);
      if (vehicleUrl != null) {
        if (kDebugMode) {
          print('✅ Found via fleet search: $vehicleUrl');
        }
        return vehicleUrl;
      } else {
        if (kDebugMode) {
          print('❌ Bus $cleanBusNumber not found in fleet search');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting bus URL: $e');
      }
      return null;
    }
  }

  /// Attempts to track a Dublin Bus by searching the fleet page
  /// Returns true if successful, false if fallback was used
  static Future<bool> trackBus(String busNumber) async {
    try {
      // Clean and normalize the bus number
      final cleanBusNumber = busNumber.trim().toUpperCase().replaceAll(' ', '');
      
      if (kDebugMode) {
        print('🚌 Tracking bus: $cleanBusNumber');
      }
      
      // Try multiple approaches in order of preference
      
      // Approach 1: Try common URL patterns first (faster)
      final directUrl = await _tryDirectUrlPatterns(cleanBusNumber);
      if (directUrl != null) {
        if (kDebugMode) {
          print('✅ Found via direct URL: $directUrl');
        }
        await _launchUrl(directUrl);
        return true;
      }
      
      // Approach 2: Search the fleet page
      final vehicleUrl = await _findVehicleUrl(cleanBusNumber);
      if (vehicleUrl != null) {
        if (kDebugMode) {
          print('✅ Found via fleet search: $vehicleUrl');
        }
        try {
          await _launchUrl(vehicleUrl);
          return true;
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Specific vehicle URL failed to launch: $e');
          }
          return false; // Return false since we couldn't open the specific page
        }
      } else {
        if (kDebugMode) {
          print('❌ Bus $cleanBusNumber not found in fleet search');
        }
        // Don't open anything if bus not found
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Error tracking bus: $e');
      }
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
        if (kDebugMode) {
          print('🔍 Testing URL: $testUrl');
        }
        
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
      if (kDebugMode) {
        print('🔍 Downloading fleet page...');
      }
      
      final response = await http.get(
        Uri.parse(_fleetUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final htmlContent = response.body;
        
        if (kDebugMode) {
          print('📄 Fleet page downloaded (${htmlContent.length} chars)');
          // Check if the bus number appears anywhere in the content
          if (htmlContent.contains(busNumber)) {
            print('✅ Bus number $busNumber found in HTML content');
          } else {
            print('❌ Bus number $busNumber NOT found in HTML content');
            // Try case insensitive
            if (htmlContent.toLowerCase().contains(busNumber.toLowerCase())) {
              print('✅ Found case-insensitive match for $busNumber');
            } else {
              print('❌ No case-insensitive match for $busNumber');
            }
          }
        }
        
        // First: Try exact match search with validation
        final exactVehicleId = _searchForExactMatch(htmlContent, busNumber);
        if (exactVehicleId != null) {
          if (kDebugMode) {
            print('🎉 Found exact match: $exactVehicleId');
          }
          return '$_baseVehicleUrl$exactVehicleId';
        }

        // Second: Try table structure search with validation
        final tableVehicleId = _searchInTableStructure(htmlContent, busNumber);
        if (tableVehicleId != null) {
          // Validate this result
          final isValid = await _validateVehicleId(tableVehicleId, busNumber);
          if (isValid) {
            if (kDebugMode) {
              print('🎉 Found via validated table search: $tableVehicleId');
            }
            return '$_baseVehicleUrl$tableVehicleId';
          } else {
            if (kDebugMode) {
              print('❌ Table search result failed validation: $tableVehicleId');
            }
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Error in fleet search: $e');
      }
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
        if (htmlContent.contains(pattern)) {
          if (kDebugMode) {
            print('🎯 Found exact pattern: $pattern');
          }
          
          // Extract vehicle ID from this exact match
          final vehicleId = _extractVehicleIdFromExactMatch(htmlContent, pattern, busNumber);
          if (vehicleId != null) {
            // Validate that this vehicle ID actually corresponds to our bus number
            if (_isVehicleIdValid(vehicleId, busNumber, htmlContent)) {
              return vehicleId;
            } else {
              if (kDebugMode) {
                print('❌ Vehicle ID $vehicleId failed validation for $busNumber');
              }
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Error in exact match search: $e');
      }
      return null;
    }
  }

  /// Extract vehicle ID from exact match with strict validation
  static String? _extractVehicleIdFromExactMatch(String htmlContent, String pattern, String busNumber) {
    try {
      final index = htmlContent.indexOf(pattern);
      if (index == -1) return null;

      // Search in a reasonable area around the match (±800 characters)
      final start = (index - 800).clamp(0, htmlContent.length);
      final end = (index + 800).clamp(0, htmlContent.length);
      final searchArea = htmlContent.substring(start, end);

      // Try multiple regex patterns for vehicle links
      final regexPatterns = [
        RegExp(r'href="[^"]*\/vehicles\/(ie-\d+)"'),
        RegExp(r"href='[^']*\/vehicles\/(ie-\d+)'"),
        RegExp(r'\/vehicles\/(ie-\d+)'),
      ];

      for (final regex in regexPatterns) {
        final matches = regex.allMatches(searchArea);
        for (final match in matches) {
          if (match.groupCount >= 1) {
            final vehicleId = match.group(1);
            if (vehicleId != null) {
              // Ensure this vehicle ID is actually associated with our bus number
              final vehicleContext = _getVehicleContext(htmlContent, vehicleId, 200);
              if (vehicleContext.contains(busNumber)) {
                return vehicleId;
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get context around a vehicle ID to validate it matches our bus number
  static String _getVehicleContext(String htmlContent, String vehicleId, int contextSize) {
    try {
      final vehiclePattern = 'vehicles/$vehicleId';
      final index = htmlContent.indexOf(vehiclePattern);
      if (index == -1) return '';

      final start = (index - contextSize).clamp(0, htmlContent.length);
      final end = (index + contextSize).clamp(0, htmlContent.length);
      return htmlContent.substring(start, end);
    } catch (e) {
      return '';
    }
  }

  /// Validate that a vehicle ID actually corresponds to our bus number
  static bool _isVehicleIdValid(String vehicleId, String busNumber, String htmlContent) {
    try {
      // Get context around this vehicle ID
      final context = _getVehicleContext(htmlContent, vehicleId, 300);
      
      // The context should contain our exact bus number
      if (!context.contains(busNumber)) {
        return false;
      }

      // Make sure it's not just a partial match (e.g., PA155 shouldn't match PA154)
      // Check for word boundaries around our bus number
      final exactPatterns = [
        '>$busNumber<',
        '"$busNumber"',
        "'$busNumber'",
        ' $busNumber ',
        '\t$busNumber\t',
        '\n$busNumber\n',
        '<td>$busNumber</td>',
        '<span>$busNumber</span>',
      ];

      for (final pattern in exactPatterns) {
        if (context.contains(pattern)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
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
            // Found a table row with exact bus number match
            // Look for vehicle links in this row
            final vehiclePattern = RegExp(r'\/vehicles\/(ie-\d+)');
            final vehicleMatch = vehiclePattern.firstMatch(rowContent);
            if (vehicleMatch != null && vehicleMatch.groupCount >= 1) {
              return vehicleMatch.group(1);
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Launch URL using url_launcher
  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    
    if (kDebugMode) {
      print('🌐 Attempting to launch: $url');
      print('📋 Parsed URI: $uri');
      print('🔍 URI scheme: ${uri.scheme}');
      print('🔍 URI host: ${uri.host}');
    }
    
    try {
      // First, check if URL launching works at all with a simple test
      if (url.contains('bustimes.org')) {
        if (kDebugMode) {
          print('🧪 Testing basic URL launcher functionality...');
        }
        final testUri = Uri.parse('https://www.google.com');
        final canLaunchTest = await canLaunchUrl(testUri);
        if (kDebugMode) {
          print('🧪 Can launch test URL (google.com): $canLaunchTest');
        }
        
        if (!canLaunchTest) {
          throw Exception('URL launcher not working - cannot launch any URLs');
        }
      }
      
      // Check if we can launch the specific URL
      final canLaunch = await canLaunchUrl(uri);
      if (kDebugMode) {
        print('🔍 Can launch target URL: $canLaunch');
      }
      
      if (!canLaunch) {
        throw Exception('Cannot launch URL: $url (canLaunchUrl returned false)');
      }
      
      // Try different launch modes in order of preference
      
      // Method 1: Try platform default mode (most compatible)
      try {
        if (kDebugMode) {
          print('🔄 Trying platformDefault mode...');
        }
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.platformDefault,
        );
        if (launched) {
          if (kDebugMode) {
            print('✅ Launched via platform default');
          }
          return;
        } else {
          if (kDebugMode) {
            print('❌ Platform default returned false');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Platform default failed: $e');
        }
      }
      
      // Method 2: Try external application mode
      try {
        if (kDebugMode) {
          print('🔄 Trying externalApplication mode...');
        }
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          if (kDebugMode) {
            print('✅ Launched via external application');
          }
          return;
        } else {
          if (kDebugMode) {
            print('❌ External application returned false');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ External application failed: $e');
        }
      }
      
      // Method 3: Try in-app web view mode
      try {
        if (kDebugMode) {
          print('🔄 Trying inAppWebView mode...');
        }
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.inAppWebView,
        );
        if (launched) {
          if (kDebugMode) {
            print('✅ Launched via in-app web view');
          }
          return;
        } else {
          if (kDebugMode) {
            print('❌ In-app web view returned false');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ In-app web view failed: $e');
        }
      }
      
      // If all methods fail, provide detailed error
      throw Exception('All launch methods failed for $url. URI valid: ${uri.isAbsolute}, Scheme: ${uri.scheme}');
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Launch completely failed: $e');
      }
      throw Exception('Could not launch $url: $e');
    }
  }
} 