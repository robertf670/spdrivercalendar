import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static const String _preferredRoutesKey = 'preferred_routes';
  static const String _showAllUpdatesKey = 'show_all_updates';


  // Default preferred routes
  static const List<String> _defaultPreferredRoutes = [
    'C1', 'C2', '39', '39A', '23', '24', 'L58', 'L59'
  ];

  /// Get user's preferred routes for live updates
  static Future<List<String>> getPreferredRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final routes = prefs.getStringList(_preferredRoutesKey);
    return routes ?? _defaultPreferredRoutes;
  }

  /// Set user's preferred routes
  static Future<void> setPreferredRoutes(List<String> routes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_preferredRoutesKey, routes);
  }

  /// Check if user wants to see all updates (not just preferred routes)
  static Future<bool> getShowAllUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showAllUpdatesKey) ?? false;
  }

  /// Set whether to show all updates
  static Future<void> setShowAllUpdates(bool showAll) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAllUpdatesKey, showAll);
  }



  /// Check if an update is relevant to user's preferred routes
  static Future<bool> isUpdateRelevant(List<String> updateRoutes) async {
    final showAll = await getShowAllUpdates();
    if (showAll || updateRoutes.isEmpty) return true;

    final preferredRoutes = await getPreferredRoutes();
    // Check if any of the update routes match user's preferred routes
    return updateRoutes.any((route) => 
      preferredRoutes.any((preferred) => 
        route.toLowerCase().contains(preferred.toLowerCase()) ||
        preferred.toLowerCase().contains(route.toLowerCase())
      )
    );
  }

  /// Get filtered updates based on user preferences
  static Future<List<T>> filterUpdatesByPreference<T>(
    List<T> updates,
    List<String> Function(T) getRoutes,
  ) async {
    final showAll = await getShowAllUpdates();
    if (showAll) return updates;

    final preferredRoutes = await getPreferredRoutes();
    
    return updates.where((update) {
      final updateRoutes = getRoutes(update);
      if (updateRoutes.isEmpty) return true; // Show updates with no specific routes
      
      return updateRoutes.any((route) => 
        preferredRoutes.any((preferred) => 
          route.toLowerCase().contains(preferred.toLowerCase()) ||
          preferred.toLowerCase().contains(route.toLowerCase())
        )
      );
    }).toList();
  }

  /// Reset all preferences to defaults
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_preferredRoutesKey, _defaultPreferredRoutes);
    await prefs.setBool(_showAllUpdatesKey, false);
  }
} 