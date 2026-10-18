import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

class AppInitializationState {
  final bool isInitialized;
  final bool isFirebaseConnected;
  final String? errorMessage;

  const AppInitializationState({
    this.isInitialized = false,
    this.isFirebaseConnected = false,
    this.errorMessage,
  });

  AppInitializationState copyWith({
    bool? isInitialized,
    bool? isFirebaseConnected,
    String? errorMessage,
  }) {
    return AppInitializationState(
      isInitialized: isInitialized ?? this.isInitialized,
      isFirebaseConnected: isFirebaseConnected ?? this.isFirebaseConnected,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AppInitializationNotifier
    extends StateNotifier<AsyncValue<AppInitializationState>> {
  final Ref _ref;

  AppInitializationNotifier(this._ref)
      : super(const AsyncValue.loading());

  Future<void> initialize() async {
    try {
      state = const AsyncValue.loading();

      // 1. Initialize local cache and seed default data
      final localStorage = _ref.read(localStorageServiceProvider);
      await localStorage.init().timeout(const Duration(seconds: 4), onTimeout: () {
        // Continue even if local storage takes longer
      });

      // 2. Initialize Firebase/Firestore with environment project credentials
      final firebaseService = _ref.read(firebaseServiceProvider);
      final firebaseOptions = _ref.read(firebaseOptionsProvider);
      await firebaseService.init(options: firebaseOptions);

      state = AsyncValue.data(
        AppInitializationState(
          isInitialized: true,
          isFirebaseConnected: firebaseService.isAvailable,
        ),
      );
    } catch (e) {
      // Graceful error state to avoid white screen freeze
      state = AsyncValue.data(
        AppInitializationState(
          isInitialized: true,
          isFirebaseConnected: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}

final appInitializationProvider = StateNotifierProvider<
    AppInitializationNotifier, AsyncValue<AppInitializationState>>((ref) {
  return AppInitializationNotifier(ref);
});
