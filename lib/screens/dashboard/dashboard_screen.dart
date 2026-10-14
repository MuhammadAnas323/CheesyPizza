import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reports_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/printer_service.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback onNavigateToPos;
  final VoidCallback onNavigateToInventory;

  const DashboardScreen({
    super.key,
    required this.onNavigateToPos,
    required this.onNavigateToInventory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayData = ref.watch(todayDashboardMetricsProvider);
    final lowStockCount = ref.watch(lowStockCountProvider);
    final ordersAsync = ref.watch(orderNotifierProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome & Quick Action Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.local_pizza, color: AppColors.primaryRed, size: 26),
                          SizedBox(width: 8),
                          Text(
                            'Cheesy Pizza Dashboard',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live operational summary for today, ${DateFormatter.format(DateTime.now())}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('New Order'),
                  onPressed: onNavigateToPos,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Low Stock Alert Banner (if any)
            if (lowStockCount > 0) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$lowStockCount Item(s) are running low on stock!',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.warning,
                            ),
                          ),
                          const Text(
                            'Replenish inventory to avoid running out during peak hours.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.warning,
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View Stock'),
                      onPressed: onNavigateToInventory,
                    ),
                  ],
                ),
              ),
            ],

            // 1. Primary Metrics (Sales, Profit, Orders, Items)
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : (constraints.maxWidth > 550 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: constraints.maxWidth > 900 ? 1.8 : 2.2,
                  children: [
                    _buildMetricCard(
                      title: "Today's Total Sales",
                      value: CurrencyFormatter.format(todayData.totalRevenue),
                      icon: Icons.payments,
                      iconColor: AppColors.primaryRed,
                      bgColor: AppColors.lightRed,
                      subtitle: "Gross receipts",
                    ),
                    _buildMetricCard(
                      title: "Estimated Profit",
                      value: CurrencyFormatter.format(todayData.estimatedProfit),
                      icon: Icons.trending_up,
                      iconColor: AppColors.success,
                      bgColor: AppColors.successLight,
                      subtitle: "Sales minus ingredient cost",
                    ),
                    _buildMetricCard(
                      title: "Total Orders",
                      value: "${todayData.totalOrdersCount}",
                      icon: Icons.receipt_long,
                      iconColor: AppColors.info,
                      bgColor: AppColors.infoLight,
                      subtitle: "Completed orders today",
                    ),
                    _buildMetricCard(
                      title: "Total Items Sold",
                      value: "${todayData.totalItemsSold}",
                      icon: Icons.fastfood,
                      iconColor: AppColors.cheeseYellow,
                      bgColor: AppColors.lightYellow,
                      subtitle: "Units served",
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // 2. Fast Food Categories Sold Breakdown
            const Text(
              "Fast Food Items Sold Today",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 900
                    ? 5
                    : (constraints.maxWidth > 500 ? 3 : 2);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildCategorySoldCard(
                      label: "Pizzas Sold",
                      count: todayData.pizzaSoldCount,
                      icon: Icons.local_pizza,
                      color: AppColors.primaryRed,
                    ),
                    _buildCategorySoldCard(
                      label: "Burgers Sold",
                      count: todayData.burgersSoldCount,
                      icon: Icons.lunch_dining,
                      color: const Color(0xFFE65100),
                    ),
                    _buildCategorySoldCard(
                      label: "Deals Sold",
                      count: todayData.dealsSoldCount,
                      icon: Icons.local_offer,
                      color: const Color(0xFF6A1B9A),
                    ),
                    _buildCategorySoldCard(
                      label: "Fries Sold",
                      count: todayData.friesSoldCount,
                      icon: Icons.fastfood,
                      color: AppColors.cheeseYellow,
                    ),
                    _buildCategorySoldCard(
                      label: "Drinks Sold",
                      count: todayData.drinksSoldCount,
                      icon: Icons.local_drink,
                      color: const Color(0xFF0277BD),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // 3. Category Sales Summary & Recent Orders side by side
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 850) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Summary
                      Expanded(
                        flex: 5,
                        child: _buildCategorySummaryCard(todayData),
                      ),
                      const SizedBox(width: 16),
                      // Recent Orders
                      Expanded(
                        flex: 6,
                        child: _buildRecentOrdersCard(ordersAsync),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildCategorySummaryCard(todayData),
                      const SizedBox(height: 20),
                      _buildRecentOrdersCard(ordersAsync),
                    ],
                  );
                }
              },
            ),
          ],
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
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted.withAlpha(200),
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

  Widget _buildCategorySoldCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySummaryCard(SalesReportData data) {
    final catList = data.categoryMetrics.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category-wise Sales Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${catList.length} Categories',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (catList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No category sales recorded today yet.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ...catList.map((cat) {
                final double percent = data.totalRevenue > 0
                    ? (cat.revenue / data.totalRevenue).clamp(0.0, 1.0)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat.categoryName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${cat.quantity} sold • ${CurrencyFormatter.format(cat.revenue)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: AppColors.lightGrey,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryRed),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(percent * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersCard(AsyncValue<List<dynamic>> ordersAsync) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Orders & Bill Printing',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const Divider(height: 20),
            ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No orders recorded yet.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                  );
                }
                final recent = orders.take(5).toList();
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final order = recent[index];
                    return Row(
                      children: [
                        // Order number avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.lightRed,
                          child: Text(
                            order.orderNumber.replaceAll('#CP-', ''),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    order.orderNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGrey,
                                      borderRadius: BorderRadius.circular(4),
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
                              const SizedBox(height: 2),
                              Text(
                                '${order.totalItemsSold} items • ${DateFormatter.formatRelative(order.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Amount & Print Button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(order.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                                      size: 13, color: AppColors.primaryRed),
                                  SizedBox(width: 3),
                                  Text(
                                    'Print',
                                    style: TextStyle(
                                      fontSize: 11,
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
