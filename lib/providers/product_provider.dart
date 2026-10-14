import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../repositories/cafe_repository.dart';
import 'repository_providers.dart';
import 'category_provider.dart';

class ProductNotifier extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final CafeRepository _repository;

  ProductNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      final list = await _repository.getProducts();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveProduct(ProductModel product) async {
    await _repository.saveProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _repository.deleteProduct(id);
    await loadProducts();
  }

  Future<void> toggleAvailability(String id) async {
    state.whenData((products) async {
      final index = products.indexWhere((p) => p.id == id);
      if (index >= 0) {
        final current = products[index];
        final updated = current.copyWith(isAvailable: !current.isAvailable);
        await saveProduct(updated);
      }
    });
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<List<ProductModel>>>((ref) {
  final repo = ref.watch(cafeRepositoryProvider);
  return ProductNotifier(repo);
});

final productSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered products based on selected category and search query
final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productNotifierProvider);
  final selectedCat = ref.watch(selectedCategoryIdProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).trim().toLowerCase();

  return productsAsync.maybeWhen(
    data: (products) {
      return products.where((p) {
        final matchesCategory = selectedCat == null || selectedCat.isEmpty || p.categoryId == selectedCat;
        final matchesSearch = searchQuery.isEmpty ||
            p.name.toLowerCase().contains(searchQuery) ||
            p.description.toLowerCase().contains(searchQuery);
        return matchesCategory && matchesSearch;
      }).toList();
    },
    orElse: () => [],
  );
});
