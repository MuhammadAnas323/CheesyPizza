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
  final double totalRevenue;
  final double cashRevenue;
  final double accountRevenue;
  final double otherRevenue;
  final double totalExpenses;
  final double netProfit;
  final int totalOrdersCount;
  final int cashOrdersCount;
  final int accountOrdersCount;
  final List<ProductMetric> productMetrics;
  final List<OrderModel> orders;

  const SalesReportData({
    this.totalRevenue = 0.0,
    this.cashRevenue = 0.0,
    this.accountRevenue = 0.0,
    this.otherRevenue = 0.0,
    this.totalExpenses = 0.0,
    this.netProfit = 0.0,
    this.totalOrdersCount = 0,
    this.cashOrdersCount = 0,
    this.accountOrdersCount = 0,
    this.productMetrics = const [],
    this.orders = const [],
  });
}

final reportTimePeriodProvider = StateProvider<ReportTimePeriod>((ref) => ReportTimePeriod.today);

final customDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return DateTimeRange(start: start, end: end);
});

SalesReportData _calculateReportForOrders({
  required List<OrderModel> orders,
  double totalExpenses = 0.0,
}) {
  // STRICT RULE: Only completed orders count towards completed sales totals and reports
  final completedOrders = orders.where((o) => o.status.toLowerCase() == 'completed').toList();

  double totalRevenue = 0.0;
  double cashRevenue = 0.0;
  double accountRevenue = 0.0;
  double otherRevenue = 0.0;
  int cashOrdersCount = 0;
  int accountOrdersCount = 0;

  final Map<String, ProductMetric> prodMap = {};

  for (final order in completedOrders) {
    totalRevenue += order.totalAmount;

    final method = order.paymentMethod.trim().toLowerCase();
    if (method == 'cash') {
      cashRevenue += order.totalAmount;
      cashOrdersCount++;
    } else if (method == 'account' || method == 'online' || method == 'card') {
      // Account / bank / digital transfer
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
    totalRevenue: totalRevenue,
    cashRevenue: cashRevenue,
    accountRevenue: accountRevenue,
    otherRevenue: otherRevenue,
    totalExpenses: totalExpenses,
    netProfit: totalRevenue - totalExpenses,
    totalOrdersCount: completedOrders.length,
    cashOrdersCount: cashOrdersCount,
    accountOrdersCount: accountOrdersCount,
    productMetrics: prodList,
    orders: orders, // Keep all orders in list for history viewing
  );
}

final todayDashboardMetricsProvider = Provider<SalesReportData>((ref) {
  final ordersAsync = ref.watch(orderNotifierProvider);
  final expensesAsync = ref.watch(expenseNotifierProvider);

  return ordersAsync.maybeWhen(
    data: (allOrders) {
      final now = DateTime.now();
      final todayOrders = allOrders.where((order) {
        return order.createdAt.year == now.year &&
            order.createdAt.month == now.month &&
            order.createdAt.day == now.day;
      }).toList();

      final todayExpenses = expensesAsync.maybeWhen(
        data: (allExpenses) => allExpenses.where((e) {
          return e.createdAt.year == now.year &&
              e.createdAt.month == now.month &&
              e.createdAt.day == now.day;
        }).fold(0.0, (sum, e) => sum + e.amount),
        orElse: () => 0.0,
      );

      return _calculateReportForOrders(
        orders: todayOrders,
        totalExpenses: todayExpenses,
      );
    },
    orElse: () => const SalesReportData(),
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
      final now = DateTime.now();
      List<OrderModel> filteredOrders = [];
      double filteredExpenses = 0.0;
      final allExpenses = expensesAsync.asData?.value ?? [];

      switch (period) {
        case ReportTimePeriod.today:
          filteredOrders = allOrders.where((o) {
            return o.createdAt.year == now.year &&
                o.createdAt.month == now.month &&
                o.createdAt.day == now.day;
          }).toList();
          filteredExpenses = allExpenses.where((e) {
            return e.createdAt.year == now.year &&
                e.createdAt.month == now.month &&
                e.createdAt.day == now.day;
          }).fold(0.0, (sum, e) => sum + e.amount);
          break;
        case ReportTimePeriod.thisWeek:
          final weekStart = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          filteredOrders = allOrders
              .where((o) => o.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))))
              .toList();
          filteredExpenses = allExpenses
              .where((e) => e.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))))
              .fold(0.0, (sum, e) => sum + e.amount);
          break;
        case ReportTimePeriod.thisMonth:
          final monthStart = DateTime(now.year, now.month, 1);
          filteredOrders = allOrders
              .where((o) => o.createdAt.isAfter(monthStart.subtract(const Duration(seconds: 1))))
              .toList();
          filteredExpenses = allExpenses
              .where((e) => e.createdAt.isAfter(monthStart.subtract(const Duration(seconds: 1))))
              .fold(0.0, (sum, e) => sum + e.amount);
          break;
        case ReportTimePeriod.custom:
          final start = DateTime(
              customRange.start.year, customRange.start.month, customRange.start.day, 0, 0, 0);
          final end = DateTime(
              customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
          filteredOrders = allOrders.where((o) {
            return o.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                o.createdAt.isBefore(end.add(const Duration(seconds: 1)));
          }).toList();
          filteredExpenses = allExpenses.where((e) {
            return e.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                e.createdAt.isBefore(end.add(const Duration(seconds: 1)));
          }).fold(0.0, (sum, e) => sum + e.amount);
          break;
      }

      return _calculateReportForOrders(
        orders: filteredOrders,
        totalExpenses: filteredExpenses,
      );
    },
    orElse: () => const SalesReportData(),
  );
});
