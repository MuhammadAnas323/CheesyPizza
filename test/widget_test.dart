import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cheesy_pizza/screens/splash/splash_screen.dart';
import 'package:cheesy_pizza/screens/welcome/welcome_screen.dart';
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
  // ── Test 1: Splash screen branding ─────────────────────────────────────────
  testWidgets('Splash Screen displays Cheesy Pizza branding',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Replace the real notifier with the mock so no real timers fire
          appInitializationProvider.overrideWith((ref) => _MockInitNotifier(ref)),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    // Verify Cheesy Pizza title exists on Splash Screen
    expect(find.text('CHEESY PIZZA'), findsOneWidget);
    expect(find.text('Hot, Fresh & Cheesy Fast Food Cafe'), findsOneWidget);

    // Pump through the rotation animation (2.4 s) without real timers
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
  });

  // ── Test 2: Welcome screen ──────────────────────────────────────────────────
  testWidgets('Welcome Screen displays exact required welcome text and button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    // Verify exact required text: "Welcome to Aman Khan in Cheesy Pizza"
    expect(find.text('Welcome to Aman Khan in Cheesy Pizza'), findsOneWidget);
    expect(find.text('CONTINUE TO CAFE'), findsOneWidget);
  });

  // ── Test 3: MainLayout tabs ─────────────────────────────────────────────────
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
