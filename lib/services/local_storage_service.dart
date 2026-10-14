import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';
import '../core/constants/default_data.dart';

class LocalStorageService {
  static const String _categoriesKey = 'cheesy_categories_v1';
  static const String _productsKey = 'cheesy_products_v1';
  static const String _inventoryKey = 'cheesy_inventory_v1';
  static const String _ordersKey = 'cheesy_orders_v1';
  static const String _initializedKey = 'cheesy_db_initialized';

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
      final bool isInitialized = prefs.getBool(_initializedKey) ?? false;
      if (!isInitialized) {
        // Mark as initialized first to prevent any potential recursive loop
        await prefs.setBool(_initializedKey, true);
        await _seedDefaultData();
      }
    } catch (_) {
      // Ignore or log error
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
      _inventoryKey,
      jsonEncode(DefaultData.defaultInventory.map((i) => i.toMap()).toList()),
    );
    await prefs.setString(
      _ordersKey,
      jsonEncode(DefaultData.samplePastOrders.map((o) => o.toMap()).toList()),
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

  // Inventory
  Future<List<InventoryItem>> getInventory() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_inventoryKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return DefaultData.defaultInventory;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => InventoryItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return DefaultData.defaultInventory;
    }
  }

  Future<void> saveInventory(List<InventoryItem> items) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(items.map((i) => i.toMap()).toList());
    await prefs.setString(_inventoryKey, jsonStr);
  }

  // Orders
  Future<List<OrderModel>> getOrders() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_ordersKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return DefaultData.samplePastOrders;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return DefaultData.samplePastOrders;
    }
  }

  Future<void> saveOrders(List<OrderModel> orders) async {
    final prefs = await _getPrefs();
    final jsonStr = jsonEncode(orders.map((o) => o.toMap()).toList());
    await prefs.setString(_ordersKey, jsonStr);
  }

  Future<void> resetToDefaults() async {
    await _seedDefaultData();
  }
}
