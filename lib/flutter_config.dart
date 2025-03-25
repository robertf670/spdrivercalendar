import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class FlutterConfig {
  static Future<void> configure() async {
    if (Platform.isAndroid) {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();
      
      // Disable Impeller and force Skia renderer
      await SystemChannels.platform.invokeMethod<void>('SystemNavigator.cleanUp');
      
      // Force Skia renderer
      await SystemChannels.platform.invokeMethod<void>('SystemChrome.setPreferredOrientations', [
        DeviceOrientation.portraitUp.index,
        DeviceOrientation.portraitDown.index,
      ]);
      
      // Configure system UI
      await SystemChannels.platform.invokeMethod<void>('SystemChrome.setSystemUIOverlayStyle', {
        'systemNavigationBarColor': '#000000',
        'systemNavigationBarIconBrightness': 'dark',
      });
      
      // Force text rendering mode
      await SystemChannels.platform.invokeMethod<void>('SystemChrome.setPreferredTextDirection', TextDirection.ltr.index);
      
      // Disable hardware acceleration for text rendering
      await SystemChannels.platform.invokeMethod<void>('SystemChrome.setSystemUIChangeCallback', {
        'enabled': false,
      });
      
      // Force text rendering mode
      await SystemChannels.platform.invokeMethod<void>('SystemChrome.setSystemUIOverlayStyle', {
        'systemNavigationBarColor': '#000000',
        'systemNavigationBarIconBrightness': 'dark',
        'statusBarColor': '#000000',
        'statusBarIconBrightness': 'dark',
        'statusBarBrightness': Brightness.dark,
      });
    }
  }
} 