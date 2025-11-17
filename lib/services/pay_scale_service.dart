import 'package:flutter/services.dart';

class PayScaleService {
  static Map<String, double>? _cachedRates;
  
  /// Get the spread over hourly rate for a given year level
  /// Returns null if the rate cannot be found
  static Future<double?> getSpreadRate(String yearLevel) async {
    try {
      final rates = await _loadPayRates();
      return rates[yearLevel.toLowerCase()];
    } catch (e) {
      return null;
    }
  }
  
  /// Load all spread over rates from the CSV file
  static Future<Map<String, double>> _loadPayRates() async {
    // Return cached rates if available
    if (_cachedRates != null) {
      return _cachedRates!;
    }
    
    try {
      final csvData = await rootBundle.loadString('pay/payscale.csv');
      final lines = csvData.split('\n');
      
      // Find the spreadover row (should be the last row)
      String? spreadRow;
      List<String>? headers;
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        
        final parts = trimmed.split(',').where((p) => p.trim().isNotEmpty).toList();
        
        // First line is headers
        if (headers == null) {
          headers = parts.map((h) => h.trim().toLowerCase()).toList();
          continue;
        }
        
        // Check if this is the spreadover row (type column contains "spreadover")
        if (parts.isNotEmpty && parts[0].trim().toLowerCase().contains('spreadover')) {
          spreadRow = trimmed;
          break;
        }
      }
      
      if (spreadRow == null || headers == null) {
        throw Exception('Spread over row not found in pay scale CSV');
      }
      
      final spreadParts = spreadRow.split(',').where((p) => p.trim().isNotEmpty).toList();
      final Map<String, double> rates = {};
      
      // Parse each year column (skip index 0 which is the type)
      for (int i = 1; i < headers.length && i < spreadParts.length; i++) {
        final yearKey = headers[i].trim();
        final rateStr = spreadParts[i].trim();
        
        if (rateStr.isNotEmpty) {
          final rate = double.tryParse(rateStr);
          if (rate != null) {
            rates[yearKey] = rate;
          }
        }
      }
      
      // Cache the rates
      _cachedRates = rates;
      
      return rates;
    } catch (e) {
      // Return empty map on error
      return {};
    }
  }
  
  /// Clear the cached rates (useful if CSV is updated)
  static void clearCache() {
    _cachedRates = null;
  }
  
  /// Get available year level options
  static List<String> getYearLevelOptions() {
    return ['year1+2', 'year3+4', 'year5', 'year6'];
  }
  
  /// Get display name for a year level
  static String getYearLevelDisplayName(String yearLevel) {
    switch (yearLevel.toLowerCase()) {
      case 'year1+2':
        return 'Year 1/2';
      case 'year3+4':
        return 'Year 3/4';
      case 'year5':
        return 'Year 5';
      case 'year6':
        return 'Year 6';
      default:
        return yearLevel;
    }
  }
}

