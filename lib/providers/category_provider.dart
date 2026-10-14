import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../repositories/cafe_repository.dart';
import 'repository_providers.dart';

class CategoryNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CafeRepository _repository;

  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final list = await _repository.getCategories();
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveCategory(CategoryModel category) async {
    await _repository.saveCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<CategoryModel>>>((ref) {
  final repo = ref.watch(cafeRepositoryProvider);
  return CategoryNotifier(repo);
});

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);
