// PLACEHOLDER: replace this file by running `flutterfire configure`
// from the project root. The FlutterFire CLI overwrites it with the real
// options for your Firebase project (one FirebaseOptions per platform).
//
// Until then the app starts on a "Firebase not configured" screen instead of
// crashing, so the rest of the project still builds and analyses cleanly.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured yet. Run `flutterfire configure` in the '
      'project root to generate lib/firebase_options.dart.',
    );
  }
}
