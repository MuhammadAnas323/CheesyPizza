import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

void runCommonApp(String environment) {
  // Custom Error Widget setup
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
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    ProviderScope(
      child: CheesyPizzaApp(environment: environment),
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
      debugShowCheckedModeBanner: environment == 'Dev', // Dev me banner dikhayen, Prod me nahi
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

// Default fallback entry point (runs Dev by default if no -t is specified)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runCommonApp('Dev');
}