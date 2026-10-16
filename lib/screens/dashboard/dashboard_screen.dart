import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reports_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/printer_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Order ${order.orderNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormatter.formatDateTime(order.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SizedBox(
          width: screenWidth > 550 ? 500 : screenWidth * 0.9,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Responsive Order Status and Order Type Chips (Wrap prevents overflow on Parcel/Takeaway)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: order.status == 'Completed'
                            ? AppColors.successLight
                            : (order.status == 'Cancelled'
                                ? AppColors.danger.withAlpha(30)
                                : AppColors.warningLight),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: order.status == 'Completed'
                              ? AppColors.success
                              : (order.status == 'Cancelled'
                                  ? AppColors.danger
                                  : AppColors.warning),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.orderType == OrderType.takeaway
                                ? Icons.takeout_dining
                                : (order.orderType == OrderType.delivery
                                    ? Icons.delivery_dining
                                    : Icons.restaurant),
                            size: 13,
                            color: AppColors.primaryRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            order.orderType.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.paymentMethod,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.customerName != null && order.customerName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${order.customerName}${order.customerPhone != null && order.customerPhone!.isNotEmpty ? ' (${order.customerPhone})' : ''}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.tableOrAddress != null && order.tableOrAddress!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.tableOrAddress!,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 18),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(
                                  'Note: ${item.notes}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.primaryRed),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.format(item.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 12.5)),
                    Text(CurrencyFormatter.format(order.subtotal), style: const TextStyle(fontSize: 12.5)),
                  ],
                ),
                if (order.discount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(fontSize: 12.5)),
                        Text('- ${CurrencyFormatter.format(order.discount)}',
                            style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                      ],
                    ),
                  ),
                if (order.extraCharges > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.extraChargesNote != null && order.extraChargesNote!.trim().isNotEmpty
                                ? 'Extra Charges (${order.extraChargesNote!.trim()}):'
                                : 'Extra Charges:',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+ ${CurrencyFormatter.format(order.extraCharges)}',
                          style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Bill:',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
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
              ],
            ),
          ),
        ),
        actions: [
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.restaurant, size: 15),
                label: const Text('Kitchen KOT', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  PrinterService.printKitchenSlip(order);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.print, size: 15),
                label: const Text('Print Receipt', style: TextStyle(fontSize: 12)),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(reportTimePeriodProvider);
    final reportData = ref.watch(filteredSalesReportProvider);
    final customRange = ref.watch(customDateRangeProvider);
    final ordersAsync = ref.watch(orderNotifierProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome Bar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.local_pizza,
                                  color: AppColors.primaryRed, size: 22),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cheesy Pizza Cafe Dashboard',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Live summary • ${DateFormatter.format(DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 14 : 20),

                // Period Selector Chips (Daily, Weekly, Monthly, Custom)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ReportTimePeriod.values.map((period) {
                      final isSelected = selectedPeriod == period;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(period.label),
                          selected: isSelected,
                          selectedColor: AppColors.primaryRed,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(reportTimePeriodProvider.notifier).state = period;
                              if (period == ReportTimePeriod.custom) {
                                showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2023),
                                  lastDate: DateTime.now().add(const Duration(days: 1)),
                                  initialDateRange: customRange,
                                ).then((range) {
                                  if (range != null) {
                                    ref.read(customDateRangeProvider.notifier).state = range;
                                  }
                                });
                              }
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 20),

                // 1. Primary Metrics (Completed Sales, Completed Orders)
                GridView.count(
                  crossAxisCount: constraints.maxWidth > 700 ? 2 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth > 700 ? 2.4 : 2.5,
                  children: [
                    _buildMetricCard(
                      title: "Completed Sales (${selectedPeriod.label})",
                      value: CurrencyFormatter.format(reportData.totalRevenue),
                      icon: Icons.payments,
                      iconColor: AppColors.primaryRed,
                      bgColor: AppColors.lightRed,
                      subtitle: "Only includes completed orders",
                    ),
                    _buildMetricCard(
                      title: "Completed Orders (${selectedPeriod.label})",
                      value: "${reportData.totalOrdersCount}",
                      icon: Icons.check_circle,
                      iconColor: AppColors.success,
                      bgColor: AppColors.successLight,
                      subtitle: "Successfully served & paid",
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 20 : 24),

                // 2. Recent Orders List
                _buildRecentOrdersCard(context, ordersAsync),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String subtitle,
  }) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted.withAlpha(220),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersCard(BuildContext context, AsyncValue<List<dynamic>> ordersAsync) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'No orders recorded yet. Create one from the Orders section.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                  );
                }
                final recent = orders.take(6).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (_, index) {
                    final order = recent[index] as OrderModel;
                    final isCompleted = order.status.toLowerCase() == 'completed';

                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showOrderDetailsDialog(context, order),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: isCompleted
                                  ? AppColors.successLight
                                  : AppColors.lightRed,
                              child: Text(
                                order.orderNumber.replaceAll('#CP-', ''),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? AppColors.success
                                      : AppColors.primaryRed,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Use Wrap instead of Row to prevent horizontal pixel overflow
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 2,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        order.orderNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightGrey,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          order.orderType.label,
                                          style: const TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.mediumGrey,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppColors.successLight
                                              : AppColors.warningLight,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          order.status,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted
                                                ? AppColors.success
                                                : AppColors.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${order.totalItemsSold} items • ${DateFormatter.formatRelative(order.createdAt)}',
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
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(order.totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                InkWell(
                                  onTap: () =>
                                      PrinterService.showPrintModal(context, order),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.print,
                                          size: 12, color: AppColors.primaryRed),
                                      SizedBox(width: 2),
                                      Text(
                                        'Print',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.primaryRed,
                                          fontWeight: FontWeight.w600,
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
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Error loading orders'),
            ),
          ],
        ),
      ),
    );
  }
}
