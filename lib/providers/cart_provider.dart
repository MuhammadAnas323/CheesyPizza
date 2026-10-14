import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

class CartState {
  final List<OrderItem> items;
  final OrderType orderType;
  final double discount;
  final String? customerName;
  final String? customerPhone;
  final String? tableOrAddress;
  final String paymentMethod;

  const CartState({
    this.items = const [],
    this.orderType = OrderType.dineIn,
    this.discount = 0.0,
    this.customerName,
    this.customerPhone,
    this.tableOrAddress,
    this.paymentMethod = 'Cash',
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get totalCost => items.fold(0.0, (sum, i) => sum + i.totalCost);
  double get totalBill {
    final net = subtotal - discount;
    return net < 0 ? 0.0 : net;
  }
  double get estimatedProfit => totalBill - totalCost;
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<OrderItem>? items,
    OrderType? orderType,
    double? discount,
    String? customerName,
    String? customerPhone,
    String? tableOrAddress,
    String? paymentMethod,
  }) {
    return CartState(
      items: items ?? this.items,
      orderType: orderType ?? this.orderType,
      discount: discount ?? this.discount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      tableOrAddress: tableOrAddress ?? this.tableOrAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(OrderItem newItem) {
    final currentItems = List<OrderItem>.from(state.items);

    // Look for duplicate item with exact same size and toppings
    final index = currentItems.indexWhere((item) {
      if (item.productId != newItem.productId) return false;
      if (item.selectedSize != newItem.selectedSize) return false;
      if (item.selectedToppings.length != newItem.selectedToppings.length) return false;

      final itemToppingNames = item.selectedToppings.map((t) => t.name).toSet();
      final newItemToppingNames = newItem.selectedToppings.map((t) => t.name).toSet();
      return itemToppingNames.containsAll(newItemToppingNames);
    });

    if (index >= 0) {
      final existing = currentItems[index];
      currentItems[index] = existing.copyWith(
        quantity: existing.quantity + newItem.quantity,
      );
    } else {
      currentItems.add(newItem);
    }

    state = state.copyWith(items: currentItems);
  }

  void incrementQuantity(int index) {
    if (index < 0 || index >= state.items.length) return;
    final currentItems = List<OrderItem>.from(state.items);
    final item = currentItems[index];
    currentItems[index] = item.copyWith(quantity: item.quantity + 1);
    state = state.copyWith(items: currentItems);
  }

  void decrementQuantity(int index) {
    if (index < 0 || index >= state.items.length) return;
    final currentItems = List<OrderItem>.from(state.items);
    final item = currentItems[index];
    if (item.quantity > 1) {
      currentItems[index] = item.copyWith(quantity: item.quantity - 1);
    } else {
      currentItems.removeAt(index);
    }
    state = state.copyWith(items: currentItems);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final currentItems = List<OrderItem>.from(state.items);
    currentItems.removeAt(index);
    state = state.copyWith(items: currentItems);
  }

  void setOrderType(OrderType type) {
    state = state.copyWith(orderType: type);
  }

  void setDiscount(double discount) {
    state = state.copyWith(discount: discount < 0 ? 0.0 : discount);
  }

  void setCustomerInfo({
    String? name,
    String? phone,
    String? tableOrAddress,
  }) {
    state = state.copyWith(
      customerName: name,
      customerPhone: phone,
      tableOrAddress: tableOrAddress,
    );
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
