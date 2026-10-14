import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/printer_service.dart';

class CartSidebar extends ConsumerStatefulWidget {
  final bool isMobileDrawer;
  const CartSidebar({super.key, this.isMobileDrawer = false});

  @override
  ConsumerState<CartSidebar> createState() => _CartSidebarState();
}

class _CartSidebarState extends ConsumerState<CartSidebar> {
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _tableAddressController = TextEditingController();
  bool _isCheckingOut = false;

  @override
  void dispose() {
    _discountController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _tableAddressController.dispose();
    super.dispose();
  }

  void _syncCustomerInfo() {
    ref.read(cartNotifierProvider.notifier).setCustomerInfo(
          name: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          tableOrAddress: _tableAddressController.text.trim().isNotEmpty
              ? _tableAddressController.text.trim()
              : null,
        );
  }

  Future<void> _handleCheckout() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart.isEmpty) return;

    _syncCustomerInfo();

    setState(() => _isCheckingOut = true);
    try {
      final savedOrder =
          await ref.read(orderNotifierProvider.notifier).checkoutCurrentCart();
      if (savedOrder != null && mounted) {
        _nameController.clear();
        _phoneController.clear();
        _tableAddressController.clear();
        _discountController.clear();

        if (widget.isMobileDrawer) {
          Navigator.of(context).pop(); // Close drawer
        }

        _showOrderSuccessDialog(savedOrder);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  void _showOrderSuccessDialog(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text('Order Placed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ${order.orderNumber} placed successfully.',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text('Type: ${order.orderType.label}'),
            Text('Total Bill: ${CurrencyFormatter.format(order.totalAmount)}'),
            Text('Est. Profit: ${CurrencyFormatter.format(order.estimatedProfit)}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightYellow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cheeseYellow.withAlpha(120)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.inventory, size: 18, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recipe ingredients deducted from inventory automatically.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.restaurant, size: 16),
            label: const Text('Kitchen Slip (KOT)'),
            onPressed: () {
              PrinterService.printKitchenSlip(order);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print Receipt'),
            onPressed: () {
              PrinterService.printReceipt(order);
            },
          ),
          TextButton(
            child: const Text('Done'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: widget.isMobileDrawer
            ? null
            : const Border(left: BorderSide(color: AppColors.borderGrey)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.darkGrey,
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: AppColors.cheeseYellow, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Current Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (cart.items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cart.totalItemCount} items',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (cart.items.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white70, size: 20),
                    tooltip: 'Clear Cart',
                    onPressed: () {
                      ref.read(cartNotifierProvider.notifier).clearCart();
                    },
                  ),
                ],
              ],
            ),
          ),

          // Order Type Selector: Dine-in, Takeaway, Home Delivery
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.lightGrey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Type',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mediumGrey,
                  ),
                ),
                const SizedBox(height: 6),
                SegmentedButton<OrderType>(
                  segments: const [
                    ButtonSegment(
                      value: OrderType.dineIn,
                      label: Text('Dine-in', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.table_restaurant, size: 14),
                    ),
                    ButtonSegment(
                      value: OrderType.takeaway,
                      label: Text('Parcel', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.takeout_dining, size: 14),
                    ),
                    ButtonSegment(
                      value: OrderType.delivery,
                      label: Text('Delivery', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.delivery_dining, size: 14),
                    ),
                  ],
                  selected: {cart.orderType},
                  onSelectionChanged: (Set<OrderType> newSelection) {
                    ref
                        .read(cartNotifierProvider.notifier)
                        .setOrderType(newSelection.first);
                  },
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(height: 8),

                // Table # or Delivery Address
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _tableAddressController,
                        onChanged: (_) => _syncCustomerInfo(),
                        decoration: InputDecoration(
                          hintText: cart.orderType == OrderType.dineIn
                              ? 'Table # (e.g. T4)'
                              : cart.orderType == OrderType.delivery
                                  ? 'Delivery Address'
                                  : 'Pickup Name / Token',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          prefixIcon: Icon(
                            cart.orderType == OrderType.dineIn
                                ? Icons.tag
                                : cart.orderType == OrderType.delivery
                                    ? Icons.location_on
                                    : Icons.person_outline,
                            size: 16,
                          ),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _phoneController,
                        onChanged: (_) => _syncCustomerInfo(),
                        decoration: const InputDecoration(
                          hintText: 'Customer Phone',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          prefixIcon: Icon(Icons.phone, size: 14),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lunch_dining_outlined,
                          size: 48,
                          color: AppColors.mediumGrey.withAlpha(80),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No items in order',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap products on the menu to add',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quantity Controls
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderGrey),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      ref
                                          .read(cartNotifierProvider.notifier)
                                          .incrementQuantity(index);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      child: Icon(Icons.add, size: 14),
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      ref
                                          .read(cartNotifierProvider.notifier)
                                          .decrementQuantity(index);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      child: Icon(Icons.remove, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Item Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.displayName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  if (item.selectedToppings.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.selectedToppings
                                          .map((t) =>
                                              '+${t.name} (${CurrencyFormatter.format(t.price)})')
                                          .join(', '),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                  if (item.notes != null &&
                                      item.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Note: ${item.notes}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.primaryRed,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(item.totalPrice),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Remove Item
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 16, color: AppColors.textMuted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                ref
                                    .read(cartNotifierProvider.notifier)
                                    .removeItem(index);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bill Summary & Checkout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderGrey)),
            ),
            child: Column(
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.mediumGrey)),
                    Text(
                      CurrencyFormatter.format(cart.subtotal),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Discount field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount (PKR)',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.mediumGrey)),
                    SizedBox(
                      width: 90,
                      height: 32,
                      child: TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: '0',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          ref
                              .read(cartNotifierProvider.notifier)
                              .setDiscount(parsed);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Payment Method
                Row(
                  children: [
                    const Text('Payment:',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.mediumGrey)),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 4,
                      children: ['Cash', 'Card', 'Online'].map((method) {
                        final isSelected = cart.paymentMethod == method;
                        return ChoiceChip(
                          label: Text(method, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          selectedColor: AppColors.cheeseYellow,
                          visualDensity: VisualDensity.compact,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(cartNotifierProvider.notifier)
                                  .setPaymentMethod(method);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const Divider(height: 16),

                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL BILL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Est. Profit: ${CurrencyFormatter.format(cart.estimatedProfit)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(cart.totalBill),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed:
                        cart.isEmpty || _isCheckingOut ? null : _handleCheckout,
                    child: _isCheckingOut
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.print, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'PLACE ORDER & PRINT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
