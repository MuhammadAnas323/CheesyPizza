import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/expense_model.dart';
import '../core/constants/default_data.dart';

class LocalStorageService {
  static const String _categoriesKey = 'cheesy_categories_v1';
  static const String _productsKey = 'cheesy_products_v1';
  static const String _ordersKey = 'cheesy_orders_v1';
  static const String _expensesKey = 'cheesy_expenses_v1';
  static const String _dbVersionKey = 'cheesy_db_version_v8_clear_recent_local_data';

  SharedPreferences? _prefs;
  bool _isInitializing = false;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> init() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      final prefs = await _getPrefs();
      final bool isCleared = prefs.getBool(_dbVersionKey) ?? false;
      if (!isCleared) {
        await prefs.setBool(_dbVersionKey, true);
        await prefs.setString(_categoriesKey, jsonEncode([]));
        await prefs.setString(_productsKey, jsonEncode([]));
        await prefs.setString(_ordersKey, jsonEncode([]));
        await prefs.setString(_expensesKey, jsonEncode([]));
      }
    } catch (_) {
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _seedDefaultData() async {
    final prefs = await _getPrefs();
    await prefs.setString(
      _categoriesKey,
      jsonEncode(DefaultData.defaultCategories.map((c) => c.toMap()).toList()),
    );
    await prefs.setString(
      _productsKey,
      jsonEncode(DefaultData.defaultProducts.map((p) => p.toMap()).toList()),
    );
    await prefs.setString(
      _ordersKey,
      jsonEncode([]),
    );
    await prefs.setString(
      _expensesKey,
      jsonEncode([]),
    );
  }

  // Categories
  Future<List<CategoryModel>> getCategories() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_categoriesKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return DefaultData.defaultCategories;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => CategoryModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return DefaultData.defaultCategories;
    }
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(categories.map((c) => c.toMap()).toList());
    await prefs.setString(_categoriesKey, jsonStr);
  }

  // Products
  Future<List<ProductModel>> getProducts() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_productsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return DefaultData.defaultProducts;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return DefaultData.defaultProducts;
    }
  }

  Future<void> saveProducts(List<ProductModel> products) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(products.map((p) => p.toMap()).toList());
    await prefs.setString(_productsKey, jsonStr);
  }

  // Orders
  Future<List<OrderModel>> getOrders() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_ordersKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOrders(List<OrderModel> orders) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(orders.map((o) => o.toMap()).toList());
    await prefs.setString(_ordersKey, jsonStr);
  }

  Future<void> clearOrders() async {
    final prefs = await _getPrefs();
    await prefs.setString(_ordersKey, jsonEncode([]));
  }

  Future<void> clearProducts() async {
    final prefs = await _getPrefs();
    await prefs.setString(_productsKey, jsonEncode([]));
  }

  Future<void> clearCategories() async {
    final prefs = await _getPrefs();
    await prefs.setString(_categoriesKey, jsonEncode([]));
  }

  Future<void> clearAllLocalData() async {
    final prefs = await _getPrefs();
    await prefs.setString(_ordersKey, jsonEncode([]));
    await prefs.setString(_productsKey, jsonEncode([]));
    await prefs.setString(_categoriesKey, jsonEncode([]));
    await prefs.setString(_expensesKey, jsonEncode([]));
  }

  // Expenses
  Future<List<ExpenseModel>> getExpenses() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_expensesKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => ExpenseModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExpenses(List<ExpenseModel> expenses) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(expenses.map((e) => e.toMap()).toList());
    await prefs.setString(_expensesKey, jsonStr);
  }

  Future<void> resetToDefaults() async {
    await _seedDefaultData();
  }
}
