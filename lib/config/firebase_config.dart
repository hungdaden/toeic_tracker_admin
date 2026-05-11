import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAcVee3KSgMaQTmaTFLTuLQ-RQRQOQTIJs',
    appId: '1:865926846836:web:41c05df2187af6ef01b421',
    messagingSenderId: '865926846836',
    projectId: 'toeic-tracker-52828',
    authDomain: 'toeic-tracker-52828.firebaseapp.com',
    storageBucket: 'toeic-tracker-52828.firebasestorage.app',
    measurementId: 'G-EP3452XDMC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAZmNJifjm8a6hYa9A6XP4qfrqqEE2OICM',
    appId: '1:865926846836:android:143e5a9dbc039b2b01b421',
    messagingSenderId: '865926846836',
    projectId: 'toeic-tracker-52828',
    storageBucket: 'toeic-tracker-52828.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDkk1fGvIf8FWSEYBlemQlsTQ6PuFzIy0w',
    appId: '1:865926846836:ios:8aa7a6acc1fa68f001b421',
    messagingSenderId: '865926846836',
    projectId: 'toeic-tracker-52828',
    storageBucket: 'toeic-tracker-52828.firebasestorage.app',
    iosBundleId: 'com.toeic.tracker.admin',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDkk1fGvIf8FWSEYBlemQlsTQ6PuFzIy0w',
    appId: '1:865926846836:ios:8aa7a6acc1fa68f001b421',
    messagingSenderId: '865926846836',
    projectId: 'toeic-tracker-52828',
    storageBucket: 'toeic-tracker-52828.firebasestorage.app',
    iosBundleId: 'com.toeic.tracker.admin',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAcVee3KSgMaQTmaTFLTuLQ-RQRQOQTIJs',
    appId: '1:865926846836:web:41c05df2187af6ef01b421',
    messagingSenderId: '865926846836',
    projectId: 'toeic-tracker-52828',
    authDomain: 'toeic-tracker-52828.firebaseapp.com',
    storageBucket: 'toeic-tracker-52828.firebasestorage.app',
    measurementId: 'G-EP3452XDMC',
  );
}
