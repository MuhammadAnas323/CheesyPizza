import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cheesy_pizza/screens/splash/splash_screen.dart';
import 'package:cheesy_pizza/screens/main_layout.dart';
import 'package:cheesy_pizza/providers/app_initialization_provider.dart';

// ─── Mock notifier: extends the real class so overrideWith type-checks pass ──
class _MockInitNotifier extends AppInitializationNotifier {
  _MockInitNotifier(super.ref);

  @override
  Future<void> initialize() async {
    // Skip real init — set success state immediately, no timers
    state = AsyncValue.data(
      AppInitializationState(
        isInitialized: true,
        isFirebaseConnected: false,
      ),
    );
  }
}

void main() {
  // ── Test 1: Splash screen & welcome text ──────────────────────────────────
  testWidgets('Splash Screen displays photo and welcome text',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appInitializationProvider.overrideWith((ref) => _MockInitNotifier(ref)),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    // Verify Welcome text appears when photo rotation finishes (2.5s into 3s splash)
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.text('Welcome to Aman Khan in Cheesy Pizza'), findsOneWidget);
  });

  // ── Test 2: MainLayout tabs ─────────────────────────────────────────────────
  testWidgets('MainLayout renders cafe management tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainLayout(),
        ),
      ),
    );

    expect(find.text('CHEESY PIZZA'), findsWidgets);
    expect(find.text('Fast Food Cafe Management'), findsOneWidget);
  });
}
