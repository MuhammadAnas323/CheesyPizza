import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reports_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class SalesReportsScreen extends ConsumerStatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  ConsumerState<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends ConsumerState<SalesReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomDateRange() async {
    final currentRange = ref.read(customDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: currentRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(customDateRangeProvider.notifier).state = picked;
      ref.read(reportTimePeriodProvider.notifier).state =
          ReportTimePeriod.custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPeriod = ref.watch(reportTimePeriodProvider);
    final customRange = ref.watch(customDateRangeProvider);
    final reportData = ref.watch(filteredSalesReportProvider);

    final profitMargin = reportData.totalRevenue > 0
        ? (reportData.estimatedProfit / reportData.totalRevenue * 100)
        : 0.0;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Period Selector
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sales & Profit Reports',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Accurate revenue, ingredient cost deductions, and net profit analytics',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time Period Filters
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Period:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    ...ReportTimePeriod.values.map((period) {
                      final isSelected = currentPeriod == period;
                      return ChoiceChip(
                        label: Text(period.label),
                        selected: isSelected,
                        selectedColor: AppColors.primaryRed,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            if (period == ReportTimePeriod.custom) {
                              _selectCustomDateRange();
                            } else {
                              ref
                                  .read(reportTimePeriodProvider.notifier)
                                  .state = period;
                            }
                          }
                        },
                      );
                    }),
                    if (currentPeriod == ReportTimePeriod.custom) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.date_range, size: 16),
                        label: Text(
                          '${DateFormatter.formatShort(customRange.start)} - ${DateFormatter.formatShort(customRange.end)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: _selectCustomDateRange,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Top Metrics Grid
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
                  childAspectRatio: constraints.maxWidth > 900 ? 1.9 : 2.3,
                  children: [
                    _buildMetricCard(
                      title: 'Total Revenue (Sales)',
                      value: CurrencyFormatter.format(reportData.totalRevenue),
                      icon: Icons.payments,
                      iconColor: AppColors.primaryRed,
                      bgColor: AppColors.lightRed,
                      subtitle: '${reportData.totalOrdersCount} Total Orders',
                    ),
                    _buildMetricCard(
                      title: 'Estimated Net Profit',
                      value: CurrencyFormatter.format(reportData.estimatedProfit),
                      icon: Icons.trending_up,
                      iconColor: AppColors.success,
                      bgColor: AppColors.successLight,
                      subtitle:
                          '${profitMargin.toStringAsFixed(1)}% Net Margin',
                    ),
                    _buildMetricCard(
                      title: 'Cost of Ingredients Sold',
                      value: CurrencyFormatter.format(reportData.totalCost),
                      icon: Icons.receipt_long,
                      iconColor: const Color(0xFF6A1B9A),
                      bgColor: const Color(0xFFF3E5F5),
                      subtitle: 'Direct ingredient cost',
                    ),
                    _buildMetricCard(
                      title: 'Total Items Sold',
                      value: '${reportData.totalItemsSold}',
                      icon: Icons.fastfood,
                      iconColor: AppColors.cheeseYellow,
                      bgColor: AppColors.lightYellow,
                      subtitle: 'Total fast food servings',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),

            // Fast Food Sales Count Breakdown (Pizzas, Burgers, Deals, Fries, Drinks)
            const Text(
              'Items Sold Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
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
                  childAspectRatio: 1.6,
                  children: [
                    _buildCountCard(
                      title: 'Pizzas Sold',
                      count: reportData.pizzaSoldCount,
                      icon: Icons.local_pizza,
                      color: AppColors.primaryRed,
                    ),
                    _buildCountCard(
                      title: 'Burgers Sold',
                      count: reportData.burgersSoldCount,
                      icon: Icons.lunch_dining,
                      color: const Color(0xFFE65100),
                    ),
                    _buildCountCard(
                      title: 'Deals Sold',
                      count: reportData.dealsSoldCount,
                      icon: Icons.local_offer,
                      color: const Color(0xFF6A1B9A),
                    ),
                    _buildCountCard(
                      title: 'Fries Sold',
                      count: reportData.friesSoldCount,
                      icon: Icons.fastfood,
                      color: AppColors.cheeseYellow,
                    ),
                    _buildCountCard(
                      title: 'Drinks Sold',
                      count: reportData.drinksSoldCount,
                      icon: Icons.local_drink,
                      color: const Color(0xFF0277BD),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Tab View for Category-wise and Product-wise Reports
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryRed,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primaryRed,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.category, size: 18),
                        text: 'Category-wise Sales & Profit',
                      ),
                      Tab(
                        icon: Icon(Icons.restaurant_menu, size: 18),
                        text: 'Product-wise Sales & Profit',
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: 480,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCategoryReportTable(reportData),
                        _buildProductReportTable(reportData),
                      ],
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
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.mediumGrey,
                      fontWeight: FontWeight.w500,
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

  Widget _buildCountCard({
    required String title,
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
            const SizedBox(height: 4),
            Text(
              title,
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

  Widget _buildCategoryReportTable(SalesReportData data) {
    final list = data.categoryMetrics.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No sales recorded in this period.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.lightGrey),
          columns: const [
            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Qty Sold', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Revenue (PKR)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Cost (PKR)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Estimated Profit (PKR)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Margin %', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          ],
          rows: list.map((cat) {
            final margin = cat.revenue > 0 ? (cat.profit / cat.revenue * 100) : 0.0;
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      const Icon(Icons.fastfood, size: 16, color: AppColors.primaryRed),
                      const SizedBox(width: 8),
                      Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                DataCell(Text('${cat.quantity}')),
                DataCell(Text(CurrencyFormatter.format(cat.revenue))),
                DataCell(Text(CurrencyFormatter.format(cat.cost))),
                DataCell(
                  Text(
                    CurrencyFormatter.format(cat.profit),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
                DataCell(Text('${margin.toStringAsFixed(1)}%')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductReportTable(SalesReportData data) {
    final list = data.productMetrics;

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No product sales recorded in this period.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.lightGrey),
          columns: const [
            DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Qty Sold', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Revenue (PKR)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Cost (PKR)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Estimated Profit (PKR)', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Margin %', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
          ],
          rows: list.map((prod) {
            final margin = prod.revenue > 0 ? (prod.profit / prod.revenue * 100) : 0.0;
            return DataRow(
              cells: [
                DataCell(Text(prod.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(prod.categoryName)),
                DataCell(Text('${prod.quantity}')),
                DataCell(Text(CurrencyFormatter.format(prod.revenue))),
                DataCell(Text(CurrencyFormatter.format(prod.cost))),
                DataCell(
                  Text(
                    CurrencyFormatter.format(prod.profit),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
                DataCell(Text('${margin.toStringAsFixed(1)}%')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
