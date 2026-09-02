import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6EwKyrybXYAoJnPGyD5fBrQvjGRO9hjc',
    appId: '1:250886498046:android:ba4ce49918110b825f27af',
    messagingSenderId: '250886498046',
    projectId: 'fixmates-v2',
    storageBucket: 'fixmates-v2.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA6EwKyrybXYAoJnPGyD5fBrQvjGRO9hjc',
    appId: '1:250886498046:web:ba4ce49918110b825f27af',
    messagingSenderId: '250886498046',
    projectId: 'fixmates-v2',
    storageBucket: 'fixmates-v2.firebasestorage.app',
  );
}