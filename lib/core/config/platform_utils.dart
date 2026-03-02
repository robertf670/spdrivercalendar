import 'package:flutter/foundation.dart';

/// Platform detection that works on all platforms including Web.
/// Use these instead of dart:io Platform to avoid Web build failures.
class PlatformUtils {
  /// True when running as Flutter Web (browser).
  static bool get isWeb => kIsWeb;

  /// True when running on Android (excluding Web).
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// True when running on iOS (excluding Web).
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
