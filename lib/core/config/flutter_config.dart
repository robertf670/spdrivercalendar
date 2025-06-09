import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class FlutterConfig {
  static Future<void> configure() async {
    if (Platform.isAndroid) {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();
      
      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      
      // Configure basic system UI
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.white,
        ),
      );
    }
  }
} 
