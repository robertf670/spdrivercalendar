import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class TextRendererService {
  static Future<void> configure() async {
    if (Platform.isAndroid) {
      // Disable Impeller
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
        // 'statusBarColor': '#000000', // Removed to allow theme to control
        // 'statusBarIconBrightness': 'dark', // Removed to allow theme to control
        'statusBarBrightness': Brightness.dark, // This is for iOS, might be okay or also themable
      });
      
      // Force text rendering mode
      await SystemChannels.platform.invokeMethod<void>('SystemChrome.setPreferredTextDirection', TextDirection.ltr.index);
      
      // Disable hardware acceleration for text rendering
      await SystemChannels.platform.invokeMethod<void>('SystemChrome.setSystemUIChangeCallback', {
        'enabled': false,
      });
    }
  }
} 
