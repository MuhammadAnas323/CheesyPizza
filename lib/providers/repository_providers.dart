import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';
import '../services/update_service.dart';
import '../repositories/cafe_repository.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final cafeRepositoryProvider = Provider<CafeRepository>((ref) {
  final local = ref.watch(localStorageServiceProvider);
  final firebase = ref.watch(firebaseServiceProvider);
  return CafeRepository(local, firebase);
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});
