import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reports_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class SalesReportsScreen extends ConsumerWidget {
  const SalesReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(reportTimePeriodProvider);
    final reportData = ref.watch(filteredSalesReportProvider);
    final customRange = ref.watch(customDateRangeProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sales Reports & Analytics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Completed sales reports & item-wise breakdown driven by actual order data',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Period Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReportTimePeriod.values.map((period) {
                  final isSelected = selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(period.label),
                      selected: isSelected,
                      selectedColor: AppColors.primaryRed,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
            const SizedBox(height: 20),

            // Metrics Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;

                // Row 1: Sales + Profit side-by-side (always)
                // Row 2: Expenses + Completed Orders side-by-side (always)
                Widget buildRow(Widget left, Widget right) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 14),
                      Expanded(child: right),
                    ],
                  );
                }

                final profit = reportData.netProfit;
                final isNegativeProfit = profit < 0;
                final profitColor = isNegativeProfit ? Colors.red.shade700 : Colors.teal.shade700;
                final profitBgColor = isNegativeProfit ? Colors.red.shade50 : Colors.teal.shade50;

                // On very narrow screens (<380px) stack cards vertically
                if (!isWide) {
                  return Column(
                    children: [
                      _buildReportMetricCard(
                        title: "Total Sales (${selectedPeriod.label})",
                        value: CurrencyFormatter.format(reportData.totalRevenue),
                        icon: Icons.payments,
                        iconColor: AppColors.primaryRed,
                        bgColor: AppColors.lightRed,
                        subtitle: "Tap for Cash & Account details",
                        onTap: () => _showSalesDetailDialog(context, reportData, selectedPeriod.label),
                      ),
                      const SizedBox(height: 12),
                      _buildReportMetricCard(
                        title: "Net Profit (${selectedPeriod.label})",
                        value: CurrencyFormatter.format(profit),
                        icon: isNegativeProfit ? Icons.trending_down : Icons.trending_up,
                        iconColor: profitColor,
                        bgColor: profitBgColor,
                        subtitle: isNegativeProfit ? "Loss: expenses exceed sales" : "Sales minus expenses",
                      ),
                      const SizedBox(height: 12),
                      _buildReportMetricCard(
                        title: "Total Expenses (${selectedPeriod.label})",
                        value: CurrencyFormatter.format(reportData.totalExpenses),
                        icon: Icons.receipt_long,
                        iconColor: Colors.deepOrange,
                        bgColor: Colors.deepOrange.withAlpha(25),
                      ),
                      const SizedBox(height: 12),
                      _buildReportMetricCard(
                        title: "Completed Orders",
                        value: "${reportData.totalOrdersCount}",
                        icon: Icons.check_circle,
                        iconColor: AppColors.success,
                        bgColor: AppColors.successLight,
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    // Row 1: Sales & Profit
                    buildRow(
                      _buildReportMetricCard(
                        title: "Total Sales (${selectedPeriod.label})",
                        value: CurrencyFormatter.format(reportData.totalRevenue),
                        icon: Icons.payments,
                        iconColor: AppColors.primaryRed,
                        bgColor: AppColors.lightRed,
                        subtitle: "Tap for Cash & Account details",
                        onTap: () => _showSalesDetailDialog(context, reportData, selectedPeriod.label),
                      ),
                      _buildReportMetricCard(
                        title: "Net Profit (${selectedPeriod.label})",
                        value: CurrencyFormatter.format(profit),
                        icon: isNegativeProfit ? Icons.trending_down : Icons.trending_up,
                        iconColor: profitColor,
                        bgColor: profitBgColor,
                        subtitle: isNegativeProfit ? "Loss: expenses exceed sales" : "Sales minus expenses",
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Row 2: Expenses & Completed Orders
                    buildRow(
                      _buildReportMetricCard(
                        title: "Total Expenses (${selectedPeriod.label})",
                        value: CurrencyFormatter.format(reportData.totalExpenses),
                        icon: Icons.receipt_long,
                        iconColor: Colors.deepOrange,
                        bgColor: Colors.deepOrange.withAlpha(25),
                      ),
                      _buildReportMetricCard(
                        title: "Completed Orders",
                        value: "${reportData.totalOrdersCount}",
                        icon: Icons.check_circle,
                        iconColor: AppColors.success,
                        bgColor: AppColors.successLight,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Item-wise Sold Sales Breakdown Card (Excludes cancelled orders, responsive with zero overflow)
            _buildItemSoldBreakdownCard(reportData),

          ],
        ),
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
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 650),
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
              Flexible(
                child: SingleChildScrollView(
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
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(reportData.cashRevenue),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
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
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(reportData.accountRevenue),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
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

  Widget _buildReportMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    String? subtitle,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemSoldBreakdownCard(SalesReportData reportData) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Item-wise Sold Sales Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${reportData.productMetrics.length} Items',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const Divider(height: 18),
            if (reportData.productMetrics.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No completed items sold in this period yet.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reportData.productMetrics.length,
                separatorBuilder: (_, _) => const Divider(height: 14),
                itemBuilder: (_, index) {
                  final metric = reportData.productMetrics[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.lightYellow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fastfood,
                              color: AppColors.cheeseYellow, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                metric.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Quantity sold: ${metric.quantity}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          fit: FlexFit.loose,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              CurrencyFormatter.format(metric.revenue),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
