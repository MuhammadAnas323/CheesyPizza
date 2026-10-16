import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_initialization_provider.dart';
import '../main_layout.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 3 seconds duration for splash screen
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0, // Exactly 2 complete rotations, stopping when finished
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubicEmphasized),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Fade-in animation for welcome text when photo stops rotating
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appInitializationProvider.notifier).initialize();
    });

    _animationController.forward().whenComplete(() {
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainLayout(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppInitializationState>>(
      appInitializationProvider,
      (previous, next) {
        if (_animationController.isCompleted && !_hasNavigated) {
          _checkAndNavigate();
        }
      },
    );

    final size = MediaQuery.of(context).size;
    final imageSize = math.min(size.width * 0.48, 190.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E2124),
              Color(0xFF2B1B17),
              Color(0xFF141618),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated rotating and scaling photo
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * 2 * math.pi,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withAlpha(120),
                            blurRadius: 28,
                            spreadRadius: 4,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: AppColors.cheeseYellow.withAlpha(90),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.cheeseYellow,
                          width: 3.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/photo.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.primaryRed,
                              child: const Icon(
                                Icons.local_pizza,
                                size: 60,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Welcome text below photo appearing when rotation stops
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_pizza,
                          color: AppColors.cheeseYellow,
                          size: 28,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Welcome to Aman Khan in Cheesy Pizza',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fast Food Cafe Management & POS',
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 13,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
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
