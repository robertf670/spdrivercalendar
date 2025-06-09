import 'dart:async';

class CacheEntry<T> {
  final T data;
  final DateTime expirationTime;

  CacheEntry(this.data, {Duration? expiration}) 
      : expirationTime = DateTime.now().add(expiration ?? const Duration(hours: 1));
}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, CacheEntry<dynamic>> _cache = {};
  final Map<String, Timer> _expirationTimers = {};

  void set<T>(String key, T data, {Duration? expiration}) {
    // Cancel existing timer if any
    _expirationTimers[key]?.cancel();
    _expirationTimers.remove(key);

    // Create new cache entry
    final entry = CacheEntry<T>(data, expiration: expiration);
    _cache[key] = entry;

    // Set up expiration timer if duration is specified
    if (expiration != null) {
      _expirationTimers[key] = Timer(expiration, () => remove(key));
    }
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expirationTime)) {
      remove(key);
      return null;
    }

    return entry.data as T;
  }

  void remove(String key) {
    _cache.remove(key);
    _expirationTimers[key]?.cancel();
    _expirationTimers.remove(key);
  }

  void clear() {
    _cache.clear();
    for (var timer in _expirationTimers.values) {
      timer.cancel();
    }
    _expirationTimers.clear();
  }

  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (DateTime.now().isAfter(entry.expirationTime)) {
      remove(key);
      return false;
    }
    
    return true;
  }
} 
