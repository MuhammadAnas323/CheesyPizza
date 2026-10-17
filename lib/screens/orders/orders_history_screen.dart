import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/repository_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/printer_service.dart';

class OrdersHistoryScreen extends ConsumerStatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  ConsumerState<OrdersHistoryScreen> createState() =>
      _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends ConsumerState<OrdersHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewOrderDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const NewOrderDialog(),
    );
  }

  void _showOrderStatusDialog(OrderModel order) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Order Details & Actions (${order.orderNumber})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: screenWidth > 550 ? 500 : screenWidth * 0.9,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: ${order.status}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: order.status == 'Completed'
                                ? AppColors.success
                                : AppColors.warning)),
                    Text('Type: ${order.orderType.label}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (order.customerName != null && order.customerName!.isNotEmpty)
                  Text('Customer: ${order.customerName}'),
                const Divider(height: 16),
                const Text('Items:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text('${item.quantity}x ${item.displayName}')),
                          Text(CurrencyFormatter.format(item.totalPrice)),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text(CurrencyFormatter.format(order.subtotal)),
                  ],
                ),
                if (order.discountPercentage > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Discount (${order.discountPercentage.toStringAsFixed(0)}%):',
                          style: const TextStyle(color: AppColors.danger)),
                      Text('- ${CurrencyFormatter.format(order.discount)}',
                          style: const TextStyle(color: AppColors.danger)),
                    ],
                  ),
                if (order.extraCharges > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${order.extraChargesNote ?? "Extra Charges"}:',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('+ ${CurrencyFormatter.format(order.extraCharges)}',
                          style: const TextStyle(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Bill:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(CurrencyFormatter.format(order.totalAmount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryRed)),
                  ],
                ),
                const Divider(height: 20),
                const Text('Update Status:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (order.status.toLowerCase() != 'completed')
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Complete'),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await ref
                                .read(orderNotifierProvider.notifier)
                                .updateStatus(order.id, 'Completed');
                          },
                        ),
                      ),
                    if (order.status.toLowerCase() != 'completed' &&
                        order.status.toLowerCase() != 'cancelled')
                      const SizedBox(width: 8),
                    if (order.status.toLowerCase() != 'cancelled')
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Cancel'),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await ref
                                .read(orderNotifierProvider.notifier)
                                .updateStatus(order.id, 'Cancelled');
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.restaurant, size: 16),
            label: const Text('Kitchen Slip'),
            onPressed: () => PrinterService.printKitchenSlip(order),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Customer Slip'),
            onPressed: () => PrinterService.printReceipt(order),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderNotifierProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          return Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & New Order Button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orders & Invoices Management',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap any order to Complete or Cancel',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 10 : 12),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text('New Order', style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold)),
                      onPressed: _openNewOrderDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final searchBox = SizedBox(
                      width: isMobile ? double.infinity : 260,
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search order # or customer...',
                          prefixIcon: Icon(Icons.search, size: 18),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    );

                    final statusDropdown = DropdownButton<String?>(
                      value: _selectedStatusFilter,
                      hint: const Text('Filter Status'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Statuses')),
                        const DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        const DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                        const DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                      ],
                      onChanged: (val) => setState(() => _selectedStatusFilter = val),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchBox,
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: statusDropdown,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: searchBox),
                        const SizedBox(width: 14),
                        statusDropdown,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Orders list
                Expanded(
                  child: ordersAsync.when(
                    data: (allOrders) {
                      final query = _searchController.text.trim().toLowerCase();
                      final filtered = allOrders.where((order) {
                        final matchStatus = _selectedStatusFilter == null ||
                            order.status.toLowerCase() == _selectedStatusFilter!.toLowerCase();
                        final matchQuery = query.isEmpty ||
                            order.orderNumber.toLowerCase().contains(query) ||
                            (order.customerName != null &&
                                order.customerName!.toLowerCase().contains(query)) ||
                            (order.customerPhone != null &&
                                order.customerPhone!.toLowerCase().contains(query));
                        return matchStatus && matchQuery;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No orders found. Click "New Order" to create one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 14),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          final isCompleted = order.status.toLowerCase() == 'completed';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showOrderStatusDialog(order),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 10 : 14),
                                child: isMobile
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: isCompleted
                                                    ? AppColors.successLight
                                                    : AppColors.lightRed,
                                                child: Text(
                                                  order.orderNumber.replaceAll('#CP-', ''),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                    color: isCompleted
                                                        ? AppColors.success
                                                        : AppColors.primaryRed,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  order.orderNumber,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                CurrencyFormatter.format(order.totalAmount),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.lightGrey,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(order.orderType.label,
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isCompleted
                                                      ? AppColors.successLight
                                                      : AppColors.warningLight,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(order.status,
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isCompleted ? AppColors.success : AppColors.warning)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${order.totalItemsSold} Items • ${DateFormatter.formatDateTime(order.createdAt)} (Tap to Complete/Cancel)',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: isCompleted
                                                ? AppColors.successLight
                                                : AppColors.lightRed,
                                            child: Text(
                                              order.orderNumber.replaceAll('#CP-', ''),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: isCompleted
                                                    ? AppColors.success
                                                    : AppColors.primaryRed,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      order.orderNumber,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: AppColors.textDark,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.lightGrey,
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        order.orderType.label,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.mediumGrey,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: isCompleted
                                                            ? AppColors.successLight
                                                            : (order.status == 'Cancelled'
                                                                ? AppColors.danger.withAlpha(30)
                                                                : AppColors.warningLight),
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        order.status,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: isCompleted
                                                              ? AppColors.success
                                                              : (order.status == 'Cancelled'
                                                                  ? AppColors.danger
                                                                  : AppColors.warning),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${DateFormatter.formatDateTime(order.createdAt)} • ${order.paymentMethod} • Tap to Complete/Cancel',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                                if (order.customerName != null) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Customer: ${order.customerName}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${order.totalItemsSold} Items',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  order.items
                                                      .map((i) =>
                                                          '${i.quantity}x ${i.productName}')
                                                      .take(2)
                                                      .join(', '),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                CurrencyFormatter.format(order.totalAmount),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 14),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 8),
                                            ),
                                            icon: const Icon(Icons.print, size: 16),
                                            label: const Text('Print Bill'),
                                            onPressed: () =>
                                                PrinterService.showPrintModal(context, order),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(child: Text('Error loading orders')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// New Order Dialog / Screen
class NewOrderDialog extends ConsumerStatefulWidget {
  const NewOrderDialog({super.key});

  @override
  ConsumerState<NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends ConsumerState<NewOrderDialog> {
  final List<OrderItem> _cartItems = [];
  OrderType _orderType = OrderType.dineIn;
  final String _paymentMethod = 'Cash';
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _extraChargesController = TextEditingController(text: '0');
  final TextEditingController _extraChargesNoteController = TextEditingController();
  final TextEditingController _discountPercentController = TextEditingController(text: '0');
  String? _selectedCategoryFilter; // null means 'All'

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _extraChargesController.dispose();
    _extraChargesNoteController.dispose();
    _discountPercentController.dispose();
    super.dispose();
  }

  double get _subtotal => _cartItems.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get _discountPercentage => double.tryParse(_discountPercentController.text) ?? 0.0;
  double get _discountAmount => _subtotal * (_discountPercentage / 100);
  double get _extraCharges => double.tryParse(_extraChargesController.text) ?? 0.0;
  double get _totalBill => (_subtotal - _discountAmount + _extraCharges).clamp(0.0, 999999.0);
  double get _totalCost => _cartItems.fold(0.0, (sum, i) => sum + i.totalCost);

  void _selectProductSizeAndAdd(ProductModel product) {
    if (product.sizes.length <= 1) {
      final size = product.sizes.isNotEmpty ? product.sizes.first : ProductSize(name: '', price: product.basePrice, costPrice: 0);
      _addToCart(product, size.name, size.price);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Select Size for ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: product.sizes.map((s) {
              return ListTile(
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(CurrencyFormatter.format(s.price), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addToCart(product, s.name, s.price);
                },
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  void _addToCart(ProductModel product, String sizeName, double price) {
    final existingIndex = _cartItems.indexWhere((i) => i.productId == product.id && i.selectedSize == sizeName);
    if (existingIndex >= 0) {
      final existing = _cartItems[existingIndex];
      setState(() {
        _cartItems[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
      });
    } else {
      setState(() {
        _cartItems.add(OrderItem(
          productId: product.id,
          productName: product.name,
          categoryId: product.categoryId,
          categoryName: '',
          selectedSize: sizeName,
          unitPrice: price,
          unitCostPrice: 0.0,
          quantity: 1,
        ));
      });
    }
  }

  Future<void> _submitOrder({required bool printSlip}) async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to the order')),
      );
      return;
    }

    final extraCharges = double.tryParse(_extraChargesController.text) ?? 0.0;
    if (extraCharges > 0 && _extraChargesNoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reason/note for the extra charges'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final repo = ref.read(cafeRepositoryProvider);
    final orderNumber = await repo.generateNextOrderNumber();

    final order = OrderModel(
      id: const Uuid().v4(),
      orderNumber: orderNumber,
      createdAt: DateTime.now(),
      orderType: _orderType,
      items: List.from(_cartItems),
      subtotal: _subtotal,
      discountPercentage: _discountPercentage,
      discount: _discountAmount,
      extraCharges: extraCharges,
      extraChargesNote: _extraChargesNoteController.text.trim().isNotEmpty ? _extraChargesNoteController.text.trim() : null,
      totalAmount: _totalBill,
      totalCost: _totalCost,
      estimatedProfit: _totalBill - _totalCost,
      customerName: _customerNameController.text.trim().isNotEmpty
          ? _customerNameController.text.trim()
          : null,
      customerPhone: _customerPhoneController.text.trim().isNotEmpty
          ? _customerPhoneController.text.trim()
          : null,
      tableOrAddress: null,
      status: 'Pending',
      paymentMethod: _paymentMethod,
    );

    await ref.read(orderNotifierProvider.notifier).checkoutCurrentCartOverride(order);

    if (printSlip) {
      try {
        await PrinterService.printReceipt(order);
      } catch (e) {
        debugPrint('Printing failed (order was successfully saved): $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order saved successfully, but printing encountered an issue.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order.orderNumber} placed as Pending!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final productsAsync = ref.watch(productNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 750),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.point_of_sale, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'New Cafe Order Placement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body: Left = Menu Browser (Categories as Filter Chips -> Filtered Items), Right = Current Order & Checkout
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 750;

                  final categories = categoriesAsync.asData?.value ?? [];
                  final effectiveCatId = (_selectedCategoryFilter != null &&
                          categories.any((c) => c.id == _selectedCategoryFilter))
                      ? _selectedCategoryFilter
                      : (categories.isNotEmpty ? categories.first.id : null);

                  final menuBrowser = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categories as Filter Chips (NO "All Categories" filter chip)
                      categoriesAsync.when(
                        data: (catList) {
                          if (catList.isEmpty) {
                            return const SizedBox(
                              height: 48,
                              child: Center(
                                child: Text('No categories found',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ),
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border(
                                bottom: BorderSide(color: AppColors.borderGrey.withAlpha(128)),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: catList.map((cat) {
                                  final isSelected = effectiveCatId == cat.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      showCheckmark: false,
                                      avatar: Icon(
                                        Icons.fastfood,
                                        size: 14,
                                        color: isSelected ? Colors.white : AppColors.primaryRed,
                                      ),
                                      label: Text(cat.name),
                                      selected: isSelected,
                                      selectedColor: AppColors.primaryRed,
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected ? AppColors.primaryRed : AppColors.borderGrey,
                                        ),
                                      ),
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textDark,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      onSelected: (_) =>
                                          setState(() => _selectedCategoryFilter = cat.id),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox(),
                      ),

                      // Filtered Products Grid
                      Expanded(
                        child: productsAsync.when(
                          data: (products) {
                            final filtered = products.where((p) {
                              final matchCat = effectiveCatId == null ||
                                  p.categoryId == effectiveCatId;
                              return matchCat && p.isAvailable;
                            }).toList();

                            if (filtered.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightRed.withAlpha(40),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.lunch_dining_outlined,
                                            size: 36, color: AppColors.primaryRed),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No items in this category',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textDark),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Select another category or add items in the Menu section.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 210,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.05,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final product = filtered[index];
                                return Card(
                                  elevation: 1.5,
                                  shadowColor: Colors.black.withAlpha(15),
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: AppColors.borderGrey.withAlpha(150)),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _selectProductSizeAndAdd(product),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: AppColors.lightRed.withAlpha(50),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.fastfood,
                                                  size: 16,
                                                  color: AppColors.primaryRed,
                                                ),
                                              ),
                                              if (product.sizes.length > 1)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.lightYellow,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '${product.sizes.length} Sizes',
                                                    style: const TextStyle(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.cheeseYellow,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                    color: AppColors.textDark,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (product.description.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    product.description,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.textMuted,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                CurrencyFormatter.format(
                                                    product.basePrice),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: AppColors.primaryRed,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryRed,
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.add,
                                                        size: 12, color: Colors.white),
                                                    SizedBox(width: 2),
                                                    Text(
                                                      'Add',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (_, _) =>
                              const Center(child: Text('Error loading products')),
                        ),
                      ),
                    ],
                  );

                  final orderSidebar = Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(
                          color: isWide ? AppColors.borderGrey.withAlpha(150) : Colors.transparent,
                        ),
                        top: BorderSide(
                          color: !isWide ? AppColors.borderGrey.withAlpha(150) : Colors.transparent,
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Current Order Checkout',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.lightRed.withAlpha(50),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_cartItems.length} items',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Customer Name (Optional) field
                          TextField(
                            controller: _customerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Customer Name (Optional)',
                              prefixIcon: Icon(Icons.person_outline, size: 18),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Order Type selector
                          DropdownButtonFormField<OrderType>(
                            initialValue: _orderType,
                            decoration: const InputDecoration(
                              labelText: 'Order Type',
                              prefixIcon: Icon(Icons.room_service_outlined, size: 18),
                              isDense: true,
                            ),
                            items: OrderType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _orderType = val);
                            },
                          ),
                          const SizedBox(height: 8),

                          // Discount Percentage & Quick Chips
                          TextField(
                            controller: _discountPercentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Discount %',
                              hintText: '0',
                              prefixIcon: Icon(Icons.discount_outlined, size: 18),
                              suffixText: '%',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 4),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [0, 5, 10, 15, 20, 25].map((pct) {
                                final isSelected = _discountPercentage == pct.toDouble();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: ChoiceChip(
                                    label: Text('$pct%'),
                                    selected: isSelected,
                                    selectedColor: AppColors.primaryRed,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textDark,
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (_) {
                                      setState(() {
                                        _discountPercentController.text = pct.toString();
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Additional / Extra Charges
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _extraChargesNoteController,
                                  decoration: const InputDecoration(
                                    labelText: 'Extra Reason',
                                    hintText: 'Delivery / Parcel',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _extraChargesController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount',
                                    hintText: '0',
                                    prefixText: 'Rs. ',
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Cart Items List
                          const Text('Cart Items:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          if (_cartItems.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              alignment: Alignment.center,
                              child: Column(
                                children: const [
                                  Icon(Icons.shopping_cart_outlined,
                                      size: 26, color: AppColors.textMuted),
                                  SizedBox(height: 4),
                                  Text(
                                    'Cart is empty.\nTap any item from the menu to add.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _cartItems.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 6),
                              itemBuilder: (_, index) {
                                final cartItem = _cartItems[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGrey.withAlpha(60),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.borderGrey.withAlpha(128)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cartItem.displayName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 11.5),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              CurrencyFormatter.format(cartItem.unitPrice),
                                              style: const TextStyle(
                                                  fontSize: 10, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Quantity adjustment stepper
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(4),
                                            onTap: () {
                                              setState(() {
                                                if (cartItem.quantity > 1) {
                                                  _cartItems[index] = cartItem.copyWith(
                                                      quantity: cartItem.quantity - 1);
                                                } else {
                                                  _cartItems.removeAt(index);
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Icon(
                                                cartItem.quantity > 1
                                                    ? Icons.remove
                                                    : Icons.delete_outline,
                                                size: 13,
                                                color: cartItem.quantity > 1
                                                    ? AppColors.textDark
                                                    : AppColors.danger,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6),
                                            child: Text(
                                              '${cartItem.quantity}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(4),
                                            onTap: () {
                                              setState(() {
                                                _cartItems[index] = cartItem.copyWith(
                                                    quantity: cartItem.quantity + 1);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryRed,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Icon(
                                                Icons.add,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        CurrencyFormatter.format(cartItem.totalPrice),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                          color: AppColors.primaryRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          const Divider(height: 16),

                          // Totals & Pricing Breakdown
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:', style: TextStyle(fontSize: 11.5)),
                              Text(CurrencyFormatter.format(_subtotal),
                                  style: const TextStyle(fontSize: 11.5)),
                            ],
                          ),
                          if (_discountAmount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount (${_discountPercentage.toStringAsFixed(0)}%):',
                                    style: const TextStyle(
                                        fontSize: 11.5, color: AppColors.danger)),
                                Text('- ${CurrencyFormatter.format(_discountAmount)}',
                                    style: const TextStyle(
                                        fontSize: 11.5, color: AppColors.danger)),
                              ],
                            ),
                          if (_extraCharges > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${_extraChargesNoteController.text.trim().isNotEmpty ? _extraChargesNoteController.text.trim() : "Extra Charges"}:',
                                    style: const TextStyle(fontSize: 11.5)),
                                Text('+ ${CurrencyFormatter.format(_extraCharges)}',
                                    style: const TextStyle(fontSize: 11.5)),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Bill:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                CurrencyFormatter.format(_totalBill),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Checkout Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    side: const BorderSide(color: AppColors.primaryRed),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.check_circle_outline,
                                      size: 14, color: AppColors.primaryRed),
                                  onPressed: _cartItems.isEmpty
                                      ? null
                                      : () => _submitOrder(printSlip: false),
                                  label: const Text('Place Order',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: AppColors.primaryRed)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryRed,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.print, size: 14),
                                  onPressed: _cartItems.isEmpty
                                      ? null
                                      : () => _submitOrder(printSlip: true),
                                  label: const Text('Place & Print',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(flex: 7, child: menuBrowser),
                        Expanded(flex: 5, child: orderSidebar),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(flex: 6, child: menuBrowser),
                      Expanded(flex: 6, child: orderSidebar),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
