import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

class CafeRepository {
  final LocalStorageService _localStorage;
  final FirebaseService _firebaseService;

  CafeRepository(
    this._localStorage,
    this._firebaseService,
  );

  // ---------------- CATEGORIES ---------------- //
  Future<List<CategoryModel>> getCategories() async {
    return _localStorage.getCategories();
  }

  Future<void> saveCategory(CategoryModel category) async {
    final list = await _localStorage.getCategories();
    final index = list.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      list[index] = category;
    } else {
      list.add(category);
    }
    await _localStorage.saveCategories(list);
    await _firebaseService.saveCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    final list = await _localStorage.getCategories();
    list.removeWhere((c) => c.id == id);
    await _localStorage.saveCategories(list);
    await _firebaseService.deleteCategory(id);
  }

  // ---------------- PRODUCTS ---------------- //
  Future<List<ProductModel>> getProducts() async {
    return _localStorage.getProducts();
  }

  Future<void> saveProduct(ProductModel product) async {
    final list = await _localStorage.getProducts();
    final index = list.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      list[index] = product;
    } else {
      list.add(product);
    }
    await _localStorage.saveProducts(list);
    await _firebaseService.saveProduct(product);
  }

  Future<void> deleteProduct(String id) async {
    final list = await _localStorage.getProducts();
    list.removeWhere((p) => p.id == id);
    await _localStorage.saveProducts(list);
    await _firebaseService.deleteProduct(id);
  }

  // ---------------- INVENTORY ---------------- //
  Future<List<InventoryItem>> getInventory() async {
    return _localStorage.getInventory();
  }

  Future<void> saveInventoryItem(InventoryItem item) async {
    final list = await _localStorage.getInventory();
    final index = list.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      list[index] = item;
    } else {
      list.add(item);
    }
    await _localStorage.saveInventory(list);
    await _firebaseService.saveInventoryItem(item);
  }

  Future<void> restockInventoryItem(String id, double addedQuantity) async {
    final list = await _localStorage.getInventory();
    final index = list.indexWhere((i) => i.id == id);
    if (index >= 0) {
      final old = list[index];
      final updated = old.copyWith(
        currentStock: old.currentStock + addedQuantity,
        lastUpdated: DateTime.now(),
      );
      list[index] = updated;
      await _localStorage.saveInventory(list);
      await _firebaseService.saveInventoryItem(updated);
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    final list = await _localStorage.getInventory();
    list.removeWhere((i) => i.id == id);
    await _localStorage.saveInventory(list);
    await _firebaseService.deleteInventoryItem(id);
  }

  // ---------------- ORDERS & RECIPE STOCK DEDUCTION ---------------- //
  Future<List<OrderModel>> getOrders() async {
    return _localStorage.getOrders();
  }

  Future<String> generateNextOrderNumber() async {
    final orders = await _localStorage.getOrders();
    int highestNum = 1000;

    for (final order in orders) {
      final numStr = order.orderNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final parsed = int.tryParse(numStr);
      if (parsed != null && parsed > highestNum) {
        highestNum = parsed;
      }
    }
    return '#CP-${highestNum + 1}';
  }

  /// Places an order, saves it, and automatically deducts ingredient usage from inventory!
  Future<OrderModel> placeOrder(OrderModel order) async {
    // 1. Deduct ingredients according to product recipes
    try {
      final products = await _localStorage.getProducts();
      final inventory = await _localStorage.getInventory();
      bool inventoryModified = false;

      for (final orderItem in order.items) {
        final product = products.firstWhere(
          (p) => p.id == orderItem.productId,
          orElse: () => ProductModel(
            id: '',
            name: '',
            categoryId: '',
            description: '',
            basePrice: 0,
            baseCostPrice: 0,
          ),
        );

        if (product.id.isNotEmpty && product.recipe.isNotEmpty) {
          for (final recipeItem in product.recipe) {
            final invIndex = inventory.indexWhere(
              (inv) => inv.id == recipeItem.inventoryItemId,
            );
            if (invIndex >= 0) {
              final invItem = inventory[invIndex];
              final totalRequired = recipeItem.quantityRequired * orderItem.quantity;
              final newStock = (invItem.currentStock - totalRequired).clamp(0.0, 999999.0);

              inventory[invIndex] = invItem.copyWith(
                currentStock: newStock,
                lastUpdated: DateTime.now(),
              );
              inventoryModified = true;
            }
          }
        }
      }

      if (inventoryModified) {
        await _localStorage.saveInventory(inventory);
      }
    } catch (e) {
      debugPrint('Error deducting recipe ingredients: $e');
    }

    // 2. Save order
    final orders = await _localStorage.getOrders();
    orders.insert(0, order); // Most recent first
    await _localStorage.saveOrders(orders);
    await _firebaseService.saveOrder(order);

    return order;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final orders = await _localStorage.getOrders();
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      final updated = OrderModel(
        id: orders[index].id,
        orderNumber: orders[index].orderNumber,
        createdAt: orders[index].createdAt,
        orderType: orders[index].orderType,
        items: orders[index].items,
        subtotal: orders[index].subtotal,
        discount: orders[index].discount,
        totalAmount: orders[index].totalAmount,
        totalCost: orders[index].totalCost,
        estimatedProfit: orders[index].estimatedProfit,
        customerName: orders[index].customerName,
        customerPhone: orders[index].customerPhone,
        tableOrAddress: orders[index].tableOrAddress,
        status: newStatus,
        paymentMethod: orders[index].paymentMethod,
      );
      orders[index] = updated;
      await _localStorage.saveOrders(orders);
      await _firebaseService.saveOrder(updated);
    }
  }

  Future<void> resetAllData() async {
    await _localStorage.resetToDefaults();
  }
}
