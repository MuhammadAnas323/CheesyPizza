import 'dart:async';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/expense_model.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

class CafeRepository {
  final LocalStorageService _localStorage;
  final FirebaseService _firebaseService;

  CafeRepository(
    this._localStorage,
    this._firebaseService,
  );

  // ---------------- REALTIME STREAMS ---------------- //
  Stream<List<CategoryModel>> categoriesStream() => _firebaseService.categoriesStream();

  Stream<List<ProductModel>> productsStream() => _firebaseService.productsStream();

  Stream<List<OrderModel>> ordersStream() => _firebaseService.ordersStream();

  Stream<List<ExpenseModel>> expensesStream() => _firebaseService.expensesStream();

  // ---------------- CATEGORIES ---------------- //
  Future<List<CategoryModel>> getCategories() async {
    try {
      if (_firebaseService.isAvailable) {
        final remote = await _firebaseService.getCategories();
        await _localStorage.saveCategories(remote);
        return remote;
      }
    } catch (_) {}
    return await _localStorage.getCategories();
  }

  Future<void> saveCategory(CategoryModel category) async {
    if (_firebaseService.isAvailable) {
      try {
        await _firebaseService.saveCategory(category);
      } catch (_) {}
    }
    final list = await _localStorage.getCategories();
    final index = list.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      list[index] = category;
    } else {
      list.add(category);
    }
    await _localStorage.saveCategories(list);
  }

  Future<void> deleteCategory(String id) async {
    if (_firebaseService.isAvailable) {
      try {
        await _firebaseService.deleteCategory(id);
      } catch (_) {}
    }
    final list = await _localStorage.getCategories();
    list.removeWhere((c) => c.id == id);
    await _localStorage.saveCategories(list);
  }

  // ---------------- PRODUCTS ---------------- //
  Future<List<ProductModel>> getProducts() async {
    try {
      if (_firebaseService.isAvailable) {
        final remote = await _firebaseService.getProducts();
        await _localStorage.saveProducts(remote);
        return remote;
      }
    } catch (_) {}
    return await _localStorage.getProducts();
  }

  Future<void> saveProduct(ProductModel product) async {
    if (_firebaseService.isAvailable) {
      try {
        await _firebaseService.saveProduct(product);
      } catch (_) {}
    }
    final list = await _localStorage.getProducts();
    final index = list.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      list[index] = product;
    } else {
      list.add(product);
    }
    await _localStorage.saveProducts(list);
  }

  Future<void> deleteProduct(String id) async {
    if (_firebaseService.isAvailable) {
      try {
        await _firebaseService.deleteProduct(id);
      } catch (_) {}
    }
    final list = await _localStorage.getProducts();
    list.removeWhere((p) => p.id == id);
    await _localStorage.saveProducts(list);
  }

  // ---------------- ORDERS ---------------- //
  Future<List<OrderModel>> getOrders() async {
    try {
      if (_firebaseService.isAvailable) {
        final remote = await _firebaseService.getOrders();
        remote.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _localStorage.saveOrders(remote);
        return remote;
      }
    } catch (_) {}
    return await _localStorage.getOrders();
  }

  Future<String> generateNextOrderNumber() async {
    final orders = await getOrders();
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

  Future<OrderModel> placeOrder(OrderModel order) async {
    if (_firebaseService.isAvailable) {
      try {
        await _firebaseService.saveOrder(order);
      } catch (_) {}
    }
    final orders = await _localStorage.getOrders();
    orders.insert(0, order); // Most recent first
    await _localStorage.saveOrders(orders);
    return order;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final orders = await getOrders();
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      // Use copyWith so extraCharges, notes, and customer details are strictly preserved
      final updated = orders[index].copyWith(status: newStatus);
      orders[index] = updated;
      if (_firebaseService.isAvailable) {
        try {
          await _firebaseService.saveOrder(updated);
        } catch (_) {}
      }
      await _localStorage.saveOrders(orders);
    }
  }

  Future<void> deleteOrder(String id) async {
    if (_firebaseService.isAvailable) {
      try {
        await _firebaseService.deleteOrder(id);
      } catch (_) {}
    }
    final list = await _localStorage.getOrders();
    list.removeWhere((o) => o.id == id);
    await _localStorage.saveOrders(list);
  }

  Future<void> clearAllOrders() async {
    await _localStorage.clearOrders();
  }

  Future<void> clearAllLocalData() async {
    await _localStorage.clearAllLocalData();
  }

  // ---------------- EXPENSES ---------------- //
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      if (_firebaseService.isAvailable) {
        final remote = await _firebaseService.getExpenses();
        remote.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await _localStorage.saveExpenses(remote);
        return remote;
      }
    } catch (_) {}
    return await _localStorage.getExpenses();
  }

  Future<void> saveExpense(ExpenseModel expense) async {
    if (_firebaseService.isAvailable) {
      try {
        await _firebaseService.saveExpense(expense);
      } catch (_) {}
    }
    final list = await _localStorage.getExpenses();
    final index = list.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      list[index] = expense;
    } else {
      list.insert(0, expense);
    }
    await _localStorage.saveExpenses(list);
  }

  Future<void> deleteExpense(String id) async {
    if (_firebaseService.isAvailable) {
      try {
        await _firebaseService.deleteExpense(id);
      } catch (_) {}
    }
    final list = await _localStorage.getExpenses();
    list.removeWhere((e) => e.id == id);
    await _localStorage.saveExpenses(list);
  }

  Future<void> resetAllData() async {
    await _localStorage.resetToDefaults();
  }
}
