import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import 'order_provider.dart';
import 'expense_provider.dart';

enum ReportTimePeriod {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  custom('Custom Range');

  final String label;
  const ReportTimePeriod(this.label);
}

class DateRangeFilter {
  final DateTime start;
  final DateTime end;

  const DateRangeFilter({required this.start, required this.end});

  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static DateRangeFilter forPeriod(ReportTimePeriod period, [DateTimeRange? customRange]) {
    final now = DateTime.now();
    switch (period) {
      case ReportTimePeriod.today:
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateRangeFilter(start: start, end: end);

      case ReportTimePeriod.thisWeek:
        // Weekly: orders placed within the current week (Monday 00:00:00 to Sunday 23:59:59.999)
        final monday = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0, 0);
        final sunday = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
        return DateRangeFilter(start: start, end: sunday);

      case ReportTimePeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return DateRangeFilter(start: start, end: end);

      case ReportTimePeriod.custom:
        if (customRange != null) {
          final start = DateTime(
            customRange.start.year,
            customRange.start.month,
            customRange.start.day,
            0,
            0,
            0,
            0,
          );
          final end = DateTime(
            customRange.end.year,
            customRange.end.month,
            customRange.end.day,
            23,
            59,
            59,
            999,
          );
          return DateRangeFilter(start: start, end: end);
        }
        final start = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return DateRangeFilter(start: start, end: end);
    }
  }
}

class ProductMetric {
  final String productName;
  int quantity;
  double revenue;

  ProductMetric({
    required this.productName,
    this.quantity = 0,
    this.revenue = 0.0,
  });
}

class SalesReportData {
  final double todaySales;
  final double totalRevenue;
  final double cashRevenue;
  final double accountRevenue;
  final double otherRevenue;
  final double totalExpenses;
  final double netProfit;
  final int totalOrdersCount;
  final int cancelledOrdersCount;
  final int onTableOrdersCount;
  final int pendingOrdersCount;
  final int totalPeriodOrdersCount;
  final int cashOrdersCount;
  final int accountOrdersCount;
  final List<ProductMetric> productMetrics;
  final List<OrderModel> orders;
  final DateRangeFilter dateRange;

  SalesReportData({
    this.todaySales = 0.0,
    this.totalRevenue = 0.0,
    this.cashRevenue = 0.0,
    this.accountRevenue = 0.0,
    this.otherRevenue = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.totalOrdersCount = 0,
    this.cancelledOrdersCount = 0,
    this.onTableOrdersCount = 0,
    this.pendingOrdersCount = 0,
    this.totalPeriodOrdersCount = 0,
    this.cashOrdersCount = 0,
    this.accountOrdersCount = 0,
    this.productMetrics = const [],
    this.orders = const [],
    DateRangeFilter? dateRange,
  }) : dateRange = dateRange ?? DateRangeFilter.forPeriod(ReportTimePeriod.today);
}

final reportTimePeriodProvider = StateProvider<ReportTimePeriod>((ref) => ReportTimePeriod.today);

final customDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return DateTimeRange(start: start, end: end);
});

SalesReportData _calculateReportForOrders({
  required List<OrderModel> allOrders,
  required DateRangeFilter filter,
  double totalExpenses = 0.0,
}) {
  // 1. Calculate Today's Sales (Orders placed TODAY that are completed)
  final todayFilter = DateRangeFilter.forPeriod(ReportTimePeriod.today);
  final todayCompletedOrders = allOrders.where((o) {
    return todayFilter.contains(o.createdAt) &&
        o.status.trim().toLowerCase() == 'completed';
  }).toList();
  final double todaySales = todayCompletedOrders.fold(
      0.0, (sum, o) => sum + o.totalAmount);

  // 2. Filter orders for the selected period
  final periodOrders = allOrders.where((o) => filter.contains(o.createdAt)).toList();
  periodOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // 3. Count order statuses in the selected period
  int completedCount = 0;
  int cancelledCount = 0;
  int pendingCount = 0;

  final List<OrderModel> completedOrders = [];

  for (final order in periodOrders) {
    final status = order.status.trim().toLowerCase();
    if (status == 'completed') {
      completedCount++;
      completedOrders.add(order);
    } else if (status == 'cancelled') {
      cancelledCount++;
    } else if (status == 'pending') {
      pendingCount++;
    }
  }

  // 4. On Table Orders: number of orders currently marked as On Table
  final int onTableCount = allOrders
      .where((o) => o.status.trim().toLowerCase() == 'on table')
      .length;

  // 5. Calculate Revenue & Item-wise Breakdown STRICTLY from completed orders
  // Cancelled, pending, and on-table orders are strictly excluded from item breakdown and completed sales
  double totalRevenue = 0.0;
  double cashRevenue = 0.0;
  double accountRevenue = 0.0;
  double otherRevenue = 0.0;
  int cashOrdersCount = 0;
  int accountOrdersCount = 0;

  final Map<String, ProductMetric> prodMap = {};

  for (final order in completedOrders) {
    if (order.status.trim().toLowerCase() != 'completed') continue; // Extra safety guard

    totalRevenue += order.totalAmount;

    final method = order.paymentMethod.trim().toLowerCase();
    if (method == 'cash') {
      cashRevenue += order.totalAmount;
      cashOrdersCount++;
    } else if (method == 'account' || method == 'online' || method == 'card') {
      accountRevenue += order.totalAmount;
      accountOrdersCount++;
    } else {
      otherRevenue += order.totalAmount;
    }

    for (final item in order.items) {
      final pKey = item.displayName;
      if (!prodMap.containsKey(pKey)) {
        prodMap[pKey] = ProductMetric(productName: pKey);
      }
      prodMap[pKey]!.quantity += item.quantity;
      prodMap[pKey]!.revenue += item.totalPrice;
    }
  }

  final prodList = prodMap.values.toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

  return SalesReportData(
    todaySales: todaySales,
    totalRevenue: totalRevenue,
    cashRevenue: cashRevenue,
    accountRevenue: accountRevenue,
    otherRevenue: otherRevenue,
    totalExpenses: totalExpenses,
    netProfit: totalRevenue - totalExpenses,
    totalOrdersCount: completedCount,
    cancelledOrdersCount: cancelledCount,
    onTableOrdersCount: onTableCount,
    pendingOrdersCount: pendingCount,
    totalPeriodOrdersCount: periodOrders.length,
    cashOrdersCount: cashOrdersCount,
    accountOrdersCount: accountOrdersCount,
    productMetrics: prodList,
    orders: periodOrders,
    dateRange: filter,
  );
}

final todayDashboardMetricsProvider = Provider<SalesReportData>((ref) {
  final ordersAsync = ref.watch(orderNotifierProvider);
  final expensesAsync = ref.watch(expenseNotifierProvider);

  return ordersAsync.maybeWhen(
    data: (allOrders) {
      final todayFilter = DateRangeFilter.forPeriod(ReportTimePeriod.today);
      final allExpenses = expensesAsync.asData?.value ?? [];
      final todayExpenses = allExpenses
          .where((e) => todayFilter.contains(e.createdAt))
          .fold(0.0, (sum, e) => sum + e.amount);

      return _calculateReportForOrders(
        allOrders: allOrders,
        filter: todayFilter,
        totalExpenses: todayExpenses,
      );
    },
    orElse: () => SalesReportData(),
  );
});

/// Dashboard / Reports filtered by period provider
final filteredSalesReportProvider = Provider<SalesReportData>((ref) {
  final ordersAsync = ref.watch(orderNotifierProvider);
  final expensesAsync = ref.watch(expenseNotifierProvider);
  final period = ref.watch(reportTimePeriodProvider);
  final customRange = ref.watch(customDateRangeProvider);

  return ordersAsync.maybeWhen(
    data: (allOrders) {
      final filter = DateRangeFilter.forPeriod(period, customRange);
      final allExpenses = expensesAsync.asData?.value ?? [];
      final filteredExpenses = allExpenses
          .where((e) => filter.contains(e.createdAt))
          .fold(0.0, (sum, e) => sum + e.amount);

      return _calculateReportForOrders(
        allOrders: allOrders,
        filter: filter,
        totalExpenses: filteredExpenses,
      );
    },
    orElse: () => SalesReportData(),
  );
});
