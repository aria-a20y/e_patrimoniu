// File generated based on Firebase project e-patrimoniu
// Registered apps: e-patrimoniu-web, e-patrimoniu-android
// Generated: 2026-06-09

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError('Linux nu este suportat.');
      default:
        throw UnsupportedError('Platformă necunoscută.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD-9oSew-GnMmyetNKxjLTTePFGVZ0NVaE',
    appId: '1:281737753774:web:1c8c6c933085991102a93f',
    messagingSenderId: '281737753774',
    projectId: 'e-patrimoniu',
    authDomain: 'e-patrimoniu.firebaseapp.com',
    storageBucket: 'e-patrimoniu.firebasestorage.app',
    measurementId: 'G-ZVYGLGWEB9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-9oSew-GnMmyetNKxjLTTePFGVZ0NVaE',
    appId: '1:281737753774:android:a64697587fad482402a93f',
    messagingSenderId: '281737753774',
    projectId: 'e-patrimoniu',
    storageBucket: 'e-patrimoniu.firebasestorage.app',
  );

  // iOS/macOS/Windows not yet registered — use Android config as fallback
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-9oSew-GnMmyetNKxjLTTePFGVZ0NVaE',
    appId: '1:281737753774:android:a64697587fad482402a93f',
    messagingSenderId: '281737753774',
    projectId: 'e-patrimoniu',
    storageBucket: 'e-patrimoniu.firebasestorage.app',
    iosBundleId: 'ro.epatrimoniu.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD-9oSew-GnMmyetNKxjLTTePFGVZ0NVaE',
    appId: '1:281737753774:android:a64697587fad482402a93f',
    messagingSenderId: '281737753774',
    projectId: 'e-patrimoniu',
    storageBucket: 'e-patrimoniu.firebasestorage.app',
    iosBundleId: 'ro.epatrimoniu.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD-9oSew-GnMmyetNKxjLTTePFGVZ0NVaE',
    appId: '1:281737753774:web:1c8c6c933085991102a93f',
    messagingSenderId: '281737753774',
    projectId: 'e-patrimoniu',
    authDomain: 'e-patrimoniu.firebaseapp.com',
    storageBucket: 'e-patrimoniu.firebasestorage.app',
    measurementId: 'G-ZVYGLGWEB9',
  );
}
