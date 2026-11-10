import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    runApp(FirebaseSetupErrorApp(error: error));
    return;
  }

  runApp(LostFoundApp(firestore: FirebaseFirestore.instance));
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key, required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Campus Lost & Found',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('Connected to Firebase')),
      ),
    );
  }
}

/// Shown when Firebase could not be initialised (usually because
/// `flutterfire configure` has not been run yet).
class FirebaseSetupErrorApp extends StatelessWidget {
  const FirebaseSetupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase is not set up',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Run `flutterfire configure` in the project folder, then '
                    'restart the app.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
