import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_model.dart';
import '../repositories/cafe_repository.dart';
import 'repository_providers.dart';

class InventoryNotifier extends StateNotifier<AsyncValue<List<InventoryItem>>> {
  final CafeRepository _repository;

  InventoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInventory();
  }

  Future<void> loadInventory() async {
    try {
      state = const AsyncValue.loading();
      final list = await _repository.getInventory();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveItem(InventoryItem item) async {
    await _repository.saveInventoryItem(item);
    await loadInventory();
  }

  Future<void> restock(String id, double quantity) async {
    await _repository.restockInventoryItem(id, quantity);
    await loadInventory();
  }

  Future<void> deleteItem(String id) async {
    await _repository.deleteInventoryItem(id);
    await loadInventory();
  }
}

final inventoryNotifierProvider =
    StateNotifierProvider<InventoryNotifier, AsyncValue<List<InventoryItem>>>((ref) {
  final repo = ref.watch(cafeRepositoryProvider);
  return InventoryNotifier(repo);
});

final inventoryFilterLowStockProvider = StateProvider<bool>((ref) => false);
final inventorySearchQueryProvider = StateProvider<String>((ref) => '');

final lowStockCountProvider = Provider<int>((ref) {
  final invAsync = ref.watch(inventoryNotifierProvider);
  return invAsync.maybeWhen(
    data: (items) => items.where((i) => i.isLowStock).length,
    orElse: () => 0,
  );
});

final filteredInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final invAsync = ref.watch(inventoryNotifierProvider);
  final onlyLowStock = ref.watch(inventoryFilterLowStockProvider);
  final query = ref.watch(inventorySearchQueryProvider).trim().toLowerCase();

  return invAsync.maybeWhen(
    data: (items) {
      return items.where((item) {
        if (onlyLowStock && !item.isLowStock) return false;
        if (query.isNotEmpty &&
            !item.name.toLowerCase().contains(query) &&
            !item.category.toLowerCase().contains(query)) {
          return false;
        }
        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
