import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/inventory_model.dart';
import '../models/order_model.dart';

import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  FirebaseFirestore? _firestore;

  bool get isAvailable => _isInitialized && _firestore != null;

  /// Returns true if Firebase is supported on this platform.
  /// Firebase C++ Windows SDK has known CMake issues — skipped on desktop.
  bool get _isPlatformSupported {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    // Skip Firebase entirely on unsupported desktop platforms (Windows, Linux, macOS)
    if (!_isPlatformSupported) {
      dev.log(
        'Firebase skipped on this platform — app runs in LocalStorage-only mode.',
        name: 'FirebaseService',
      );
      return;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _firestore = FirebaseFirestore.instance;
        dev.log('Firebase already initialized.', name: 'FirebaseService');
      } else {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 5));
          _isInitialized = true;
          _firestore = FirebaseFirestore.instance;
          dev.log('Firebase initialized successfully for cheesypizza-2fc77.',
              name: 'FirebaseService');
        } catch (e) {
          _isInitialized = false;
          _firestore = null;
          dev.log(
              'Firebase initialization skipped or timed out (offline/local mode active): $e',
              name: 'FirebaseService');
        }
      }
    } catch (e) {
      _isInitialized = false;
      _firestore = null;
      dev.log('FirebaseService error: $e', name: 'FirebaseService');
    }
  }

  // Firestore Collections
  CollectionReference? get _categoriesCol =>
      _firestore?.collection('categories');
  CollectionReference? get _productsCol =>
      _firestore?.collection('products');
  CollectionReference? get _inventoryCol =>
      _firestore?.collection('inventory');
  CollectionReference? get _ordersCol =>
      _firestore?.collection('orders');

  // Categories
  Future<void> saveCategory(CategoryModel category) async {
    if (!isAvailable) return;
    try {
      await _categoriesCol!.doc(category.id).set(category.toMap());
    } catch (e) {
      dev.log('Error saving category to Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteCategory(String id) async {
    if (!isAvailable) return;
    try {
      await _categoriesCol!.doc(id).delete();
    } catch (e) {
      dev.log('Error deleting category from Firestore: $e', name: 'FirebaseService');
    }
  }

  // Products
  Future<void> saveProduct(ProductModel product) async {
    if (!isAvailable) return;
    try {
      await _productsCol!.doc(product.id).set(product.toMap());
    } catch (e) {
      dev.log('Error saving product to Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteProduct(String id) async {
    if (!isAvailable) return;
    try {
      await _productsCol!.doc(id).delete();
    } catch (e) {
      dev.log('Error deleting product from Firestore: $e', name: 'FirebaseService');
    }
  }

  // Inventory
  Future<void> saveInventoryItem(InventoryItem item) async {
    if (!isAvailable) return;
    try {
      await _inventoryCol!.doc(item.id).set(item.toMap());
    } catch (e) {
      dev.log('Error saving inventory to Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    if (!isAvailable) return;
    try {
      await _inventoryCol!.doc(id).delete();
    } catch (e) {
      dev.log('Error deleting inventory from Firestore: $e', name: 'FirebaseService');
    }
  }

  // Orders
  Future<void> saveOrder(OrderModel order) async {
    if (!isAvailable) return;
    try {
      await _ordersCol!.doc(order.id).set(order.toMap());
    } catch (e) {
      dev.log('Error saving order to Firestore: $e', name: 'FirebaseService');
    }
  }

  // Bulk sync all local data to Firestore
  Future<bool> syncAllToFirestore({
    required List<CategoryModel> categories,
    required List<ProductModel> products,
    required List<InventoryItem> inventory,
    required List<OrderModel> orders,
  }) async {
    if (!isAvailable) return false;
    try {
      final batch = _firestore!.batch();
      for (final cat in categories) {
        batch.set(_categoriesCol!.doc(cat.id), cat.toMap());
      }
      for (final prod in products) {
        batch.set(_productsCol!.doc(prod.id), prod.toMap());
      }
      for (final inv in inventory) {
        batch.set(_inventoryCol!.doc(inv.id), inv.toMap());
      }
      for (final ord in orders) {
        batch.set(_ordersCol!.doc(ord.id), ord.toMap());
      }
      await batch.commit();
      return true;
    } catch (e) {
      dev.log('Batch sync failed: $e', name: 'FirebaseService');
      return false;
    }
  }
}
