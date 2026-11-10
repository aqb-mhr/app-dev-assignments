import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Only web is configured. Run flutterfire configure for other platforms.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBaxK2hjReRKaRsvNAD3fcBQqgrmrEamP8',
    appId: '1:62125443087:web:c1645a44a95e688dd6fb7a',
    messagingSenderId: '62125443087',
    projectId: 'lost-found-1d8cb',
    authDomain: 'lost-found-1d8cb.firebasestorage.app',
    storageBucket: 'PASTE_storageBucket',
  );
}