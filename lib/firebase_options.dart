// Firebase config for project iba-roombook-3057d, copied from the
// Firebase console (Project settings > Your apps). These values are public
// identifiers, not secrets - access is controlled by rules.txt.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
            'Only Android and Web are configured for this project.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAVZ2BAEg1bMwnq84ikcOEQ6y6mq8QhyqI',
    appId: '1:130480855204:web:5bba8733bbd3f0fd0e2e31',
    messagingSenderId: '130480855204',
    projectId: 'iba-roombook-3057d',
    authDomain: 'iba-roombook-3057d.firebaseapp.com',
    storageBucket: 'iba-roombook-3057d.firebasestorage.app',
    measurementId: 'G-P6LHPQJEZV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAVZ2BAEg1bMwnq84ikcOEQ6y6mq8QhyqI',
    appId: '1:130480855204:android:1b77709d63a3bb4a0e2e31',
    messagingSenderId: '130480855204',
    projectId: 'iba-roombook-3057d',
    storageBucket: 'iba-roombook-3057d.firebasestorage.app',
  );
}
