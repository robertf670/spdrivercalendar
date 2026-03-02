// Firebase options for Web platform.
// For production: run `dart run flutterfire_cli:flutterfire configure` to regenerate
// with your Web app config from Firebase Console (add Web app if not exists).
//
// This file provides Web config for local testing. Android uses google-services.json.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Web requires explicit options; Android uses google-services.json
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC43Rda105qz66YP1B4PSMEBFBG5MJxMxY',
    authDomain: 'spdrivercalendar.firebaseapp.com',
    projectId: 'spdrivercalendar',
    storageBucket: 'spdrivercalendar.firebasestorage.app',
    messagingSenderId: '1051329330296',
    appId: '1:1051329330296:web:local-dev-placeholder',
    measurementId: null,
  );
}
