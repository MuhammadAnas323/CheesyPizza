import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/expense_model.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  FirebaseFirestore? _firestore;

  bool get isAvailable => _isInitialized && _firestore != null;

  bool get _isPlatformSupported {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  bool _isInitStarted = false;
  final Completer<void> _initCompleter = Completer<void>();

  Future<void> ensureInitialized() {
    if (!_isInitStarted || _initCompleter.isCompleted) return Future.value();
    return _initCompleter.future;
  }

  Future<void> init({FirebaseOptions? options}) async {
    _isInitStarted = true;
    if (!_isPlatformSupported) {
      dev.log(
        'Firebase skipped on this platform — app runs in LocalStorage-only mode.',
        name: 'FirebaseService',
      );
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      return;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _firestore = FirebaseFirestore.instance;
        dev.log('Firebase already initialized for project: ${Firebase.app().options.projectId}', name: 'FirebaseService');
      } else {
        try {
          await Firebase.initializeApp(
            options: options ?? DefaultFirebaseOptions.currentPlatform,
          ).timeout(const Duration(seconds: 8));
          _isInitialized = true;
          _firestore = FirebaseFirestore.instance;
          dev.log('Firebase initialized successfully.', name: 'FirebaseService');
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
    } finally {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
    }
  }

  // Firestore Collections
  CollectionReference? get _categoriesCol =>
      _firestore?.collection('categories');
  CollectionReference? get _productsCol =>
      _firestore?.collection('products');
  CollectionReference? get _ordersCol =>
      _firestore?.collection('orders');
  CollectionReference? get _expensesCol =>
      _firestore?.collection('expenses');

  // Categories
  Future<List<CategoryModel>> getCategories() async {
    if (!isAvailable) return [];
    try {
      final snapshot = await _categoriesCol!.get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(
              Map<String, dynamic>.from(doc.data() as Map), doc.id))
          .toList();
    } catch (e) {
      dev.log('Error fetching categories from Firestore: $e', name: 'FirebaseService');
      return [];
    }
  }

  Future<void> saveCategory(CategoryModel category) async {
    if (!isAvailable) {
      dev.log('Firebase not available when saving category', name: 'FirebaseService');
      return;
    }
    try {
      await _categoriesCol!.doc(category.id).set(category.toMap());
      dev.log('Category saved to Firebase: ${category.name}', name: 'FirebaseService');
    } catch (e) {
      dev.log('Error saving category to Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteCategory(String id) async {
    if (!isAvailable) return;
    try {
      await _categoriesCol!.doc(id).delete();
      dev.log('Category deleted from Firebase: $id', name: 'FirebaseService');
    } catch (e) {
      dev.log('Error deleting category from Firestore: $e', name: 'FirebaseService');
    }
  }

  // Products
  Future<List<ProductModel>> getProducts() async {
    if (!isAvailable) return [];
    try {
      final snapshot = await _productsCol!.get();
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(
              Map<String, dynamic>.from(doc.data() as Map), doc.id))
          .toList();
    } catch (e) {
      dev.log('Error fetching products from Firestore: $e', name: 'FirebaseService');
      return [];
    }
  }

  Future<void> saveProduct(ProductModel product) async {
    if (!isAvailable) {
      dev.log('Firebase not available when saving product', name: 'FirebaseService');
      return;
    }
    try {
      await _productsCol!.doc(product.id).set(product.toMap());
      dev.log('Product saved to Firebase: ${product.name}', name: 'FirebaseService');
    } catch (e) {
      dev.log('Error saving product to Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteProduct(String id) async {
    if (!isAvailable) return;
    try {
      await _productsCol!.doc(id).delete();
      dev.log('Product deleted from Firebase: $id', name: 'FirebaseService');
    } catch (e) {
      dev.log('Error deleting product from Firestore: $e', name: 'FirebaseService');
    }
  }

  // Orders
  Future<List<OrderModel>> getOrders() async {
    if (!isAvailable) return [];
    try {
      final snapshot = await _ordersCol!.get();
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(
              Map<String, dynamic>.from(doc.data() as Map), doc.id))
          .toList();
    } catch (e) {
      dev.log('Error fetching orders from Firestore: $e', name: 'FirebaseService');
      return [];
    }
  }

  Future<void> saveOrder(OrderModel order) async {
    if (!isAvailable) {
      dev.log('Firebase not available when saving order', name: 'FirebaseService');
      return;
    }
    try {
      await _ordersCol!.doc(order.id).set(order.toMap());
      dev.log('Order saved to Firebase: ${order.orderNumber}', name: 'FirebaseService');
    } catch (e) {
      dev.log('Error saving order to Firestore: $e', name: 'FirebaseService');
    }
  }

  // Expenses
  Future<List<ExpenseModel>> getExpenses() async {
    if (!isAvailable) return [];
    try {
      final snapshot = await _expensesCol!.get();
      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(
              Map<String, dynamic>.from(doc.data() as Map), doc.id))
          .toList();
    } catch (e) {
      dev.log('Error fetching expenses from Firestore: $e', name: 'FirebaseService');
      return [];
    }
  }

  Future<void> saveExpense(ExpenseModel expense) async {
    if (!isAvailable) {
      dev.log('Firebase not available when saving expense', name: 'FirebaseService');
      return;
    }
    try {
      await _expensesCol!.doc(expense.id).set(expense.toMap());
      dev.log('Expense saved to Firebase: ${expense.note}', name: 'FirebaseService');
    } catch (e) {
      dev.log('Error saving expense to Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteExpense(String id) async {
    if (!isAvailable) return;
    try {
      await _expensesCol!.doc(id).delete();
      dev.log('Expense deleted from Firebase: $id', name: 'FirebaseService');
    } catch (e) {
      dev.log('Error deleting expense from Firestore: $e', name: 'FirebaseService');
    }
  }

  Future<void> deleteOrder(String id) async {
    if (!isAvailable) return;
    try {
      await _ordersCol!.doc(id).delete();
      dev.log('Order deleted from Firebase: $id', name: 'FirebaseService');
    } catch (e) {
      dev.log('Error deleting order from Firestore: $e', name: 'FirebaseService');
    }
  }

  // ---------------- REALTIME STREAMS ---------------- //

  Stream<List<CategoryModel>> categoriesStream() async* {
    if (!isAvailable && _isInitStarted && !_initCompleter.isCompleted) {
      await ensureInitialized().timeout(const Duration(seconds: 3), onTimeout: () {});
    }
    if (!isAvailable || _categoriesCol == null) {
      yield [];
      return;
    }
    yield* _categoriesCol!.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CategoryModel.fromMap(
              Map<String, dynamic>.from(doc.data() as Map), doc.id))
          .toList();
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return list;
    }).handleError((error) {
      dev.log('Error in categoriesStream (Check Firestore security rules): $error', name: 'FirebaseService');
    });
  }

  Stream<List<ProductModel>> productsStream() async* {
    if (!isAvailable && _isInitStarted && !_initCompleter.isCompleted) {
      await ensureInitialized().timeout(const Duration(seconds: 3), onTimeout: () {});
    }
    if (!isAvailable || _productsCol == null) {
      yield [];
      return;
    }
    yield* _productsCol!.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(
              Map<String, dynamic>.from(doc.data() as Map), doc.id))
          .toList();
    }).handleError((error) {
      dev.log('Error in productsStream (Check Firestore security rules): $error', name: 'FirebaseService');
    });
  }

  Stream<List<OrderModel>> ordersStream() async* {
    if (!isAvailable && _isInitStarted && !_initCompleter.isCompleted) {
      await ensureInitialized().timeout(const Duration(seconds: 3), onTimeout: () {});
    }
    if (!isAvailable || _ordersCol == null) {
      yield [];
      return;
    }
    yield* _ordersCol!.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromMap(
              Map<String, dynamic>.from(doc.data() as Map), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) {
      dev.log('Error in ordersStream (Check Firestore security rules): $error', name: 'FirebaseService');
    });
  }

  Stream<List<ExpenseModel>> expensesStream() async* {
    if (!isAvailable && _isInitStarted && !_initCompleter.isCompleted) {
      await ensureInitialized().timeout(const Duration(seconds: 3), onTimeout: () {});
    }
    if (!isAvailable || _expensesCol == null) {
      yield [];
      return;
    }
    yield* _expensesCol!.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExpenseModel.fromMap(
              Map<String, dynamic>.from(doc.data() as Map), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) {
      dev.log('Error in expensesStream (Check Firestore security rules): $error', name: 'FirebaseService');
    });
  }
}
