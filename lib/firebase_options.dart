// PLACEHOLDER - replace by running:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// in the project root. That command overwrites this file with your own
// Firebase project's keys and registers the Android/iOS/web apps.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Firebase is not configured yet. Run `flutterfire configure` '
        'in the project root (see README).',
      );
}
