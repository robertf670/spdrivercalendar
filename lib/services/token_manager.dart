import 'dart:async';

class TokenManager {
  static DateTime? _tokenExpiration;
  static Timer? _refreshTimer;
  static const int _refreshThresholdMinutes = 5; // Refresh 5 minutes before expiration
  
  static void setTokenExpiration(DateTime expiration) {
    _tokenExpiration = expiration;
    _scheduleRefresh();
  }
  
  static bool needsRefresh() {
    if (_tokenExpiration == null) return true;
    return DateTime.now().add(Duration(minutes: _refreshThresholdMinutes))
        .isAfter(_tokenExpiration!);
  }
  
  static void _scheduleRefresh() {
    _refreshTimer?.cancel();
    
    if (_tokenExpiration == null) return;
    
    final timeUntilRefresh = _tokenExpiration!.difference(DateTime.now())
        - Duration(minutes: _refreshThresholdMinutes);
        
    if (timeUntilRefresh.isNegative) {
      // Token already needs refresh
      return;
    }
    
    _refreshTimer = Timer(timeUntilRefresh, () {
      // This will be handled by the GoogleCalendarService
    });
  }
  
  static void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _tokenExpiration = null;
  }
} 