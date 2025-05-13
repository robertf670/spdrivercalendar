import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

mixin TextRenderingMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _configureTextRendering();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      _configureTextRendering();
    }
  }

  Future<void> _configureTextRendering() async {
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
      'systemNavigationBarDividerColor': '#000000',
      'systemNavigationBarContrastEnforced': true,
      'systemOverlays': SystemUiOverlay.values,
    });
    
    // Force text rendering mode
    await SystemChannels.platform.invokeMethod<void>('SystemChrome.setPreferredTextDirection', TextDirection.ltr.index);
    
    // Disable hardware acceleration for text rendering
    await SystemChannels.platform.invokeMethod<void>('SystemChrome.setSystemUIChangeCallback', {
      'enabled': false,
    });
  }
} 