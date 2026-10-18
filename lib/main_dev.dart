import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/repository_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final targetOptions = DefaultFirebaseOptions.currentPlatform;

  // Dev Firebase initialization with auto-mismatch resolution
  try {
    if (Firebase.apps.isNotEmpty) {
      final currentApp = Firebase.app();
      if (currentApp.options.projectId != targetOptions.projectId) {
        debugPrint(
          '[DevMain] Firebase project mismatch! Current: ${currentApp.options.projectId}, Expected: ${targetOptions.projectId}. Resetting...',
        );
        try {
          await currentApp.delete();
        } catch (_) {}
      }
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: targetOptions,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  } catch (e) {
    debugPrint('[DevMain] Firebase init note: $e');
  }

  // Error Widget Setup
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 48),
              const SizedBox(height: 16),
              const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(details.exceptionAsString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    ProviderScope(
      overrides: [
        firebaseOptionsProvider.overrideWithValue(targetOptions),
      ],
      child: const CheesyPizzaApp(environment: 'Dev'),
    ),
  );
}

class CheesyPizzaApp extends StatelessWidget {
  final String environment;
  const CheesyPizzaApp({super.key, required this.environment});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cheesy Pizza ($environment)',
      debugShowCheckedModeBanner: true, // Dev mein banner rahega
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}