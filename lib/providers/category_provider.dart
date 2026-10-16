import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../repositories/cafe_repository.dart';
import 'repository_providers.dart';

class CategoryNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CafeRepository _repository;
  StreamSubscription<List<CategoryModel>>? _subscription;

  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initStream();
  }

  void _initStream() {
    _subscription?.cancel();
    _subscription = _repository.categoriesStream().listen(
      (categories) {
        state = AsyncValue.data(categories);
      },
      onError: (err, st) {
        loadCategories();
      },
    );
    loadCategories(isInitial: true);
  }

  Future<void> loadCategories({bool isInitial = false}) async {
    try {
      if (isInitial && state is! AsyncData) {
        state = const AsyncValue.loading();
      }
      final list = await _repository.getCategories();
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (isInitial && state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> saveCategory(CategoryModel category) async {
    await _repository.saveCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  final repo = ref.watch(cafeRepositoryProvider);
  return CategoryNotifier(repo);
});

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);
