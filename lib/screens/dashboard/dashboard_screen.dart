import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reports_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/printer_service.dart';
import '../orders/widgets/order_details_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    OrderDetailsDialog.show(context, order);
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
                      subtitle: "Tap for Cash & Account details",
                      onTap: () => _showSalesDetailDialog(context, reportData, selectedPeriod.label),
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

  void _showSalesDetailDialog(BuildContext context, SalesReportData reportData, String periodLabel) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: AppColors.primaryRed,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.point_of_sale, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sales Summary & Breakdown',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Period: $periodLabel',
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total Sales Highlight
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.lightRed.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryRed.withAlpha(50)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Completed Sales',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              CurrencyFormatter.format(reportData.totalRevenue),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${reportData.totalOrdersCount} Completed Order(s)',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cash Received Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50.withAlpha(120),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.payments_outlined, color: Colors.green, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Received via Cash',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  '${reportData.cashOrdersCount} Cash Order(s)',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(reportData.cashRevenue),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Account Received Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withAlpha(120),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_balance_outlined, color: Colors.blue, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Received via Account',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  '${reportData.accountOrdersCount} Account / Digital Order(s)',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(reportData.accountRevenue),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (reportData.otherRevenue > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderGrey.withAlpha(150)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Other Payments:', style: TextStyle(fontSize: 12.5)),
                            Text(
                              CurrencyFormatter.format(reportData.otherRevenue),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom Close
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: AppColors.borderGrey.withAlpha(100))),
                ),
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
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
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                        color: onTap != null ? iconColor : AppColors.textMuted.withAlpha(220),
                        fontWeight: onTap != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
            ],
          ),
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
