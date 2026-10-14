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

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final bool isInitialized = _prefs!.getBool(_initializedKey) ?? false;
    if (!isInitialized) {
      await _seedDefaultData();
      await _prefs!.setBool(_initializedKey, true);
    }
  }

  Future<void> _seedDefaultData() async {
    await saveCategories(DefaultData.defaultCategories);
    await saveProducts(DefaultData.defaultProducts);
    await saveInventory(DefaultData.defaultInventory);
    await saveOrders(DefaultData.samplePastOrders);
  }

  // Categories
  Future<List<CategoryModel>> getCategories() async {
    await init();
    final jsonStr = _prefs!.getString(_categoriesKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return DefaultData.defaultCategories;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => CategoryModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return DefaultData.defaultCategories;
    }
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    await init();
    final jsonStr = jsonEncode(categories.map((c) => c.toMap()).toList());
    await _prefs!.setString(_categoriesKey, jsonStr);
  }

  // Products
  Future<List<ProductModel>> getProducts() async {
    await init();
    final jsonStr = _prefs!.getString(_productsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return DefaultData.defaultProducts;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => ProductModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return DefaultData.defaultProducts;
    }
  }

  Future<void> saveProducts(List<ProductModel> products) async {
    await init();
    final jsonStr = jsonEncode(products.map((p) => p.toMap()).toList());
    await _prefs!.setString(_productsKey, jsonStr);
  }

  // Inventory
  Future<List<InventoryItem>> getInventory() async {
    await init();
    final jsonStr = _prefs!.getString(_inventoryKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return DefaultData.defaultInventory;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => InventoryItem.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return DefaultData.defaultInventory;
    }
  }

  Future<void> saveInventory(List<InventoryItem> items) async {
    await init();
    final jsonStr = jsonEncode(items.map((i) => i.toMap()).toList());
    await _prefs!.setString(_inventoryKey, jsonStr);
  }

  // Orders
  Future<List<OrderModel>> getOrders() async {
    await init();
    final jsonStr = _prefs!.getString(_ordersKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return DefaultData.samplePastOrders;
    }
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return DefaultData.samplePastOrders;
    }
  }

  Future<void> saveOrders(List<OrderModel> orders) async {
    await init();
    final jsonStr = jsonEncode(orders.map((o) => o.toMap()).toList());
    await _prefs!.setString(_ordersKey, jsonStr);
  }

  Future<void> resetToDefaults() async {
    await init();
    await _seedDefaultData();
  }
}
