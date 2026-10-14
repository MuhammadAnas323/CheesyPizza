import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
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
  OrderType? _selectedTypeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOrderDetailsDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  DateFormatter.formatDateTime(order.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                order.orderType.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (order.customerName != null && order.customerName!.isNotEmpty) ...[
                  Text('Customer: ${order.customerName} (${order.customerPhone ?? "No phone"})'),
                ],
                if (order.tableOrAddress != null && order.tableOrAddress!.isNotEmpty) ...[
                  Text('Table / Address: ${order.tableOrAddress}'),
                ],
                const Divider(height: 20),
                const Text('Items Ordered:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.quantity}x ',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (item.selectedToppings.isNotEmpty)
                                Text(
                                  '+ ${item.selectedToppings.map((t) => t.name).join(', ')}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textMuted),
                                ),
                              if (item.notes != null)
                                Text(
                                  'Note: ${item.notes}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.primaryRed),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text(CurrencyFormatter.format(order.subtotal)),
                  ],
                ),
                if (order.discount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount:'),
                      Text('- ${CurrencyFormatter.format(order.discount)}',
                          style: const TextStyle(color: AppColors.danger)),
                    ],
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Bill:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Profit:',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(
                      CurrencyFormatter.format(order.estimatedProfit),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Orders History & Invoices',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Detailed order logs, customer details, and thermal receipt reprints',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter row
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;
                final chips = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Types'),
                        selected: _selectedTypeFilter == null,
                        selectedColor: AppColors.primaryRed,
                        labelStyle: TextStyle(
                          color: _selectedTypeFilter == null
                              ? Colors.white
                              : AppColors.textDark,
                          fontWeight: _selectedTypeFilter == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedTypeFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ...OrderType.values.map((type) {
                        final isSelected = _selectedTypeFilter == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type.label),
                            selected: isSelected,
                            selectedColor: AppColors.primaryRed,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textDark,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) =>
                                setState(() => _selectedTypeFilter = type),
                          ),
                        );
                      }),
                    ],
                  ),
                );

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

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      chips,
                      const SizedBox(height: 10),
                      searchBox,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: chips),
                    const SizedBox(width: 14),
                    searchBox,
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
                    final matchType = _selectedTypeFilter == null ||
                        order.orderType == _selectedTypeFilter;
                    final matchQuery = query.isEmpty ||
                        order.orderNumber.toLowerCase().contains(query) ||
                        (order.customerName != null &&
                            order.customerName!.toLowerCase().contains(query)) ||
                        (order.customerPhone != null &&
                            order.customerPhone!.toLowerCase().contains(query)) ||
                        (order.tableOrAddress != null &&
                            order.tableOrAddress!.toLowerCase().contains(query));
                    return matchType && matchQuery;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: AppColors.mediumGrey),
                          SizedBox(height: 12),
                          Text(
                            'No matching orders found.',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 650;

                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];

                          if (isMobile) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showOrderDetailsDialog(order),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: AppColors.lightRed,
                                            child: Text(
                                              order.orderNumber.replaceAll('#CP-', ''),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: AppColors.primaryRed,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
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
                                                        fontSize: 14,
                                                        color: AppColors.textDark,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.lightGrey,
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        order.orderType.label,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.mediumGrey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${DateFormatter.formatDateTime(order.createdAt)} • ${order.paymentMethod}',
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    color: AppColors.textMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(order.totalAmount),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${order.totalItemsSold} Items: ${order.items.map((i) => '${i.quantity}x ${i.productName}').join(', ')}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textDark),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Profit: ${CurrencyFormatter.format(order.estimatedProfit)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.success,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.print,
                                                size: 18, color: AppColors.primaryRed),
                                            tooltip: 'Print Bill',
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () =>
                                                PrinterService.showPrintModal(
                                                    context, order),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showOrderDetailsDialog(order),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Order Number badge
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.lightRed,
                                      child: Text(
                                        order.orderNumber.replaceAll('#CP-', ''),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.primaryRed,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Order Details
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
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${DateFormatter.formatDateTime(order.createdAt)} • ${order.paymentMethod}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          if (order.customerName != null ||
                                              order.tableOrAddress != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${order.customerName ?? "Customer"}  ${order.tableOrAddress != null ? "• ${order.tableOrAddress}" : ""}',
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

                                    // Items summary
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

                                    // Pricing & Profit
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(
                                              order.totalAmount),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryRed,
                                          ),
                                        ),
                                        Text(
                                          'Profit: ${CurrencyFormatter.format(order.estimatedProfit)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),

                                    // Print Buttons
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.print, size: 16),
                                      label: const Text('Print Bill'),
                                      onPressed: () =>
                                          PrinterService.showPrintModal(
                                              context, order),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
