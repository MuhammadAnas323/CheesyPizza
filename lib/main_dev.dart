import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart' as dev_options;
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dev Firebase config with duplicate-app safety check
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: dev_options.DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  } catch (e) {
    // Already initialized or caught safely
  }

  // Common app ko launch karein
  runCommonApp('Dev');
}
