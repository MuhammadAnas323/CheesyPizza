import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../repositories/cafe_repository.dart';
import 'repository_providers.dart';
import 'cart_provider.dart';
import 'inventory_provider.dart';

class OrderNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final CafeRepository _repository;
  final Ref _ref;

  OrderNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      state = const AsyncValue.loading();
      final list = await _repository.getOrders();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<OrderModel?> checkoutCurrentCart() async {
    final cart = _ref.read(cartNotifierProvider);
    if (cart.isEmpty) return null;

    final orderNumber = await _repository.generateNextOrderNumber();
    final newOrder = OrderModel(
      id: const Uuid().v4(),
      orderNumber: orderNumber,
      createdAt: DateTime.now(),
      orderType: cart.orderType,
      items: List.from(cart.items),
      subtotal: cart.subtotal,
      discount: cart.discount,
      totalAmount: cart.totalBill,
      totalCost: cart.totalCost,
      estimatedProfit: cart.estimatedProfit,
      customerName: cart.customerName,
      customerPhone: cart.customerPhone,
      tableOrAddress: cart.tableOrAddress,
      status: 'Completed',
      paymentMethod: cart.paymentMethod,
    );

    // Place order (deducts stock for ingredients)
    final savedOrder = await _repository.placeOrder(newOrder);

    // Refresh inventory and orders
    await _ref.read(inventoryNotifierProvider.notifier).loadInventory();
    await loadOrders();

    // Clear cart
    _ref.read(cartNotifierProvider.notifier).clearCart();

    return savedOrder;
  }

  Future<void> updateStatus(String orderId, String newStatus) async {
    await _repository.updateOrderStatus(orderId, newStatus);
    await loadOrders();
  }
}

final orderNotifierProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderModel>>>((ref) {
  final repo = ref.watch(cafeRepositoryProvider);
  return OrderNotifier(repo, ref);
});
