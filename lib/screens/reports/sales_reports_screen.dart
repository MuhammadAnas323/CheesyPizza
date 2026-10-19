import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/reports_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/paginated_orders_provider.dart';
import '../../models/order_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../orders/widgets/order_details_dialog.dart';

class SalesReportsScreen extends ConsumerStatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  ConsumerState<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends ConsumerState<SalesReportsScreen> {
  final ScrollController _scrollController = ScrollController();
  ReportTimePeriod? _lastPeriod;
  DateTimeRange? _lastCustomRange;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final threshold = _scrollController.position.maxScrollExtent - 200;
      if (_scrollController.position.pixels >= threshold) {
        ref.read(reportsOrdersPaginationProvider.notifier).fetchNextBatch();
      }
    }
  }

  void _loadInitialData() {
    final period = ref.read(reportTimePeriodProvider);
    final customRange = ref.read(customDateRangeProvider);
    _lastPeriod = period;
    _lastCustomRange = customRange;
    final filter = DateRangeFilter.forPeriod(period, customRange);
    ref.read(reportsOrdersPaginationProvider.notifier).fetchFirstBatch(filter);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showOrderDetailsDialog(BuildContext context, OrderModel order) {
    OrderDetailsDialog.show(context, order);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(reportTimePeriodProvider);
    final reportData = ref.watch(filteredSalesReportProvider);
    final customRange = ref.watch(customDateRangeProvider);
    final paginatedOrders = ref.watch(reportsOrdersPaginationProvider);

    // Watch for period or date range changes and reload pagination batch
    if (_lastPeriod != selectedPeriod || _lastCustomRange != customRange) {
      _lastPeriod = selectedPeriod;
      _lastCustomRange = customRange;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final filter = DateRangeFilter.forPeriod(selectedPeriod, customRange);
        ref.read(reportsOrdersPaginationProvider.notifier).fetchFirstBatch(filter);
      });
    }

    // Also auto-refresh pagination when order changes occur in realtime
    ref.listen(orderNotifierProvider, (previous, next) {
      if (previous != null && next is AsyncData) {
        final filter = DateRangeFilter.forPeriod(selectedPeriod, customRange);
        ref.read(reportsOrdersPaginationProvider.notifier).fetchFirstBatch(filter);
      }
    });

    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
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
                int crossAxisCount;
                double aspectRatio;
                if (constraints.maxWidth > 850) {
                  crossAxisCount = 3;
                  aspectRatio = 2.4;
                } else if (constraints.maxWidth > 550) {
                  crossAxisCount = 2;
                  aspectRatio = 2.3;
                } else {
                  crossAxisCount = 1;
                  aspectRatio = 2.8;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: aspectRatio,
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
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Item-wise Sold Sales Breakdown Card (Excludes cancelled orders, responsive with zero overflow)
            _buildItemSoldBreakdownCard(reportData),

            const SizedBox(height: 24),

            // Period Orders List with Lazy Loading / Pagination (10 per batch)
            _buildPeriodOrdersCard(
              context: context,
              periodLabel: selectedPeriod.label,
              totalCount: reportData.totalPeriodOrdersCount,
              paginatedState: paginatedOrders,
            ),
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
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 28),
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
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

  Widget _buildPeriodOrdersCard({
    required BuildContext context,
    required String periodLabel,
    required int totalCount,
    required PaginatedOrdersState paginatedState,
  }) {
    final orders = paginatedState.orders;

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
                Expanded(
                  child: Text(
                    'Period Orders ($periodLabel)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    totalCount > 0
                        ? 'Showing ${orders.length} of $totalCount'
                        : '0 orders',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            if (paginatedState.isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryRed),
                ),
              ),
            ] else if (orders.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    'No orders recorded in this period ($periodLabel).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (_, index) {
                  final order = orders[index];
                  final statusLower = order.status.trim().toLowerCase();
                  final isCompleted = statusLower == 'completed';
                  final isCancelled = statusLower == 'cancelled';
                  final isOnTable = statusLower == 'on table';

                  Color badgeColor = AppColors.warning;
                  Color badgeBg = AppColors.warningLight;
                  if (isCompleted) {
                    badgeColor = AppColors.success;
                    badgeBg = AppColors.successLight;
                  } else if (isCancelled) {
                    badgeColor = Colors.red.shade700;
                    badgeBg = Colors.red.shade50;
                  } else if (isOnTable) {
                    badgeColor = Colors.amber.shade900;
                    badgeBg = Colors.amber.shade50;
                  }

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
                                : (isCancelled ? Colors.red.shade50 : AppColors.lightRed),
                            child: Text(
                              order.orderNumber.replaceAll('#CP-', ''),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? AppColors.success
                                    : (isCancelled ? Colors.red.shade700 : AppColors.primaryRed),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                          horizontal: 5, vertical: 1.5),
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
                                          horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        order.status,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: badgeColor,
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
                          const SizedBox(width: 8),
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
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Lazy loading footer / Next batch button
              const SizedBox(height: 12),
              if (paginatedState.isLoadingMore) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primaryRed),
                    ),
                  ),
                ),
              ] else if (paginatedState.hasMore) ...[
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    ),
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: const Text('Load More Orders (10 next)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      ref.read(reportsOrdersPaginationProvider.notifier).fetchNextBatch();
                    },
                  ),
                ),
              ] else if (orders.length >= 10) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'All ${orders.length} orders loaded',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
