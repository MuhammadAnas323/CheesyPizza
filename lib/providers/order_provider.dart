import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../repositories/cafe_repository.dart';
import 'repository_providers.dart';

class OrderNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final CafeRepository _repository;
  StreamSubscription<List<OrderModel>>? _subscription;

  OrderNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initStream();
  }

  void _initStream() {
    _subscription?.cancel();
    _subscription = _repository.ordersStream().listen(
      (orders) {
        state = AsyncValue.data(orders);
      },
      onError: (err, st) {
        loadOrders();
      },
    );
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final list = await _repository.getOrders();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<OrderModel> checkoutCurrentCartOverride(OrderModel order) async {
    final savedOrder = await _repository.placeOrder(order);
    // Realtime stream updates state automatically
    return savedOrder;
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    await _repository.updateOrderStatus(orderId, newStatus);
  }

  Future<void> deleteOrder(String orderId) async {
    await _repository.deleteOrder(orderId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final orderNotifierProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderModel>>>((ref) {
  final repo = ref.watch(cafeRepositoryProvider);
  return OrderNotifier(repo);
});
