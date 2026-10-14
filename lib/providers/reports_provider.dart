import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import 'order_provider.dart';

enum ReportTimePeriod {
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  custom('Custom Range');

  final String label;
  const ReportTimePeriod(this.label);
}

class CategoryMetric {
  final String categoryName;
  int quantity;
  double revenue;
  double cost;

  CategoryMetric({
    required this.categoryName,
    this.quantity = 0,
    this.revenue = 0.0,
    this.cost = 0.0,
  });

  double get profit => revenue - cost;
}

class ProductMetric {
  final String productId;
  final String productName;
  final String categoryName;
  int quantity;
  double revenue;
  double cost;

  ProductMetric({
    required this.productId,
    required this.productName,
    required this.categoryName,
    this.quantity = 0,
    this.revenue = 0.0,
    this.cost = 0.0,
  });

  double get profit => revenue - cost;
}

class SalesReportData {
  final double totalRevenue;
  final double totalCost;
  final double estimatedProfit;
  final int totalOrdersCount;
  final int totalItemsSold;

  // Specific fast food categories
  final int pizzaSoldCount;
  final int burgersSoldCount;
  final int dealsSoldCount;
  final int friesSoldCount;
  final int drinksSoldCount;
  final int othersSoldCount;

  final Map<String, CategoryMetric> categoryMetrics;
  final List<ProductMetric> productMetrics;
  final List<OrderModel> orders;

  const SalesReportData({
    this.totalRevenue = 0.0,
    this.totalCost = 0.0,
    this.estimatedProfit = 0.0,
    this.totalOrdersCount = 0,
    this.totalItemsSold = 0,
    this.pizzaSoldCount = 0,
    this.burgersSoldCount = 0,
    this.dealsSoldCount = 0,
    this.friesSoldCount = 0,
    this.drinksSoldCount = 0,
    this.othersSoldCount = 0,
    this.categoryMetrics = const {},
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

SalesReportData _calculateReportForOrders(List<OrderModel> orders) {
  double totalRevenue = 0.0;
  double totalCost = 0.0;
  double totalProfit = 0.0;
  int totalItemsSold = 0;

  int pizzaSold = 0;
  int burgersSold = 0;
  int dealsSold = 0;
  int friesSold = 0;
  int drinksSold = 0;
  int othersSold = 0;

  final Map<String, CategoryMetric> catMap = {};
  final Map<String, ProductMetric> prodMap = {};

  for (final order in orders) {
    if (order.status.toLowerCase() == 'cancelled') continue;

    totalRevenue += order.totalAmount;
    totalCost += order.totalCost;
    totalProfit += order.estimatedProfit;

    for (final item in order.items) {
      totalItemsSold += item.quantity;
      final catName = item.categoryName.isNotEmpty ? item.categoryName : 'Others';
      final lowerCat = catName.toLowerCase();

      if (lowerCat.contains('pizza')) {
        pizzaSold += item.quantity;
      } else if (lowerCat.contains('burger')) {
        burgersSold += item.quantity;
      } else if (lowerCat.contains('deal')) {
        dealsSold += item.quantity;
      } else if (lowerCat.contains('frie')) {
        friesSold += item.quantity;
      } else if (lowerCat.contains('drink') || lowerCat.contains('beverage')) {
        drinksSold += item.quantity;
      } else {
        othersSold += item.quantity;
      }

      // Category map
      if (!catMap.containsKey(catName)) {
        catMap[catName] = CategoryMetric(categoryName: catName);
      }
      catMap[catName]!.quantity += item.quantity;
      catMap[catName]!.revenue += item.totalPrice;
      catMap[catName]!.cost += item.totalCost;

      // Product map
      final pKey = item.productId.isNotEmpty ? item.productId : item.productName;
      if (!prodMap.containsKey(pKey)) {
        prodMap[pKey] = ProductMetric(
          productId: item.productId,
          productName: item.productName,
          categoryName: catName,
        );
      }
      prodMap[pKey]!.quantity += item.quantity;
      prodMap[pKey]!.revenue += item.totalPrice;
      prodMap[pKey]!.cost += item.totalCost;
    }
  }

  final prodList = prodMap.values.toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

  return SalesReportData(
    totalRevenue: totalRevenue,
    totalCost: totalCost,
    estimatedProfit: totalProfit,
    totalOrdersCount: orders.where((o) => o.status.toLowerCase() != 'cancelled').length,
    totalItemsSold: totalItemsSold,
    pizzaSoldCount: pizzaSold,
    burgersSoldCount: burgersSold,
    dealsSoldCount: dealsSold,
    friesSoldCount: friesSold,
    drinksSoldCount: drinksSold,
    othersSoldCount: othersSold,
    categoryMetrics: catMap,
    productMetrics: prodList,
    orders: orders,
  );
}

/// Provider for Today's Dashboard Metrics
final todayDashboardMetricsProvider = Provider<SalesReportData>((ref) {
  final ordersAsync = ref.watch(orderNotifierProvider);
  return ordersAsync.maybeWhen(
    data: (allOrders) {
      final now = DateTime.now();
      final todayOrders = allOrders.where((order) {
        return order.createdAt.year == now.year &&
            order.createdAt.month == now.month &&
            order.createdAt.day == now.day;
      }).toList();
      return _calculateReportForOrders(todayOrders);
    },
    orElse: () => const SalesReportData(),
  );
});

/// Provider for Sales Reports Screen (Driven by period and custom date range)
final filteredSalesReportProvider = Provider<SalesReportData>((ref) {
  final ordersAsync = ref.watch(orderNotifierProvider);
  final period = ref.watch(reportTimePeriodProvider);
  final customRange = ref.watch(customDateRangeProvider);

  return ordersAsync.maybeWhen(
    data: (allOrders) {
      final now = DateTime.now();
      List<OrderModel> filtered = [];

      switch (period) {
        case ReportTimePeriod.today:
          filtered = allOrders.where((o) {
            return o.createdAt.year == now.year &&
                o.createdAt.month == now.month &&
                o.createdAt.day == now.day;
          }).toList();
          break;
        case ReportTimePeriod.thisWeek:
          // Last 7 days or start of week
          final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          filtered = allOrders.where((o) => o.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1)))).toList();
          break;
        case ReportTimePeriod.thisMonth:
          final monthStart = DateTime(now.year, now.month, 1);
          filtered = allOrders.where((o) => o.createdAt.isAfter(monthStart.subtract(const Duration(seconds: 1)))).toList();
          break;
        case ReportTimePeriod.custom:
          final start = DateTime(
              customRange.start.year, customRange.start.month, customRange.start.day, 0, 0, 0);
          final end = DateTime(
              customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
          filtered = allOrders.where((o) {
            return o.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                o.createdAt.isBefore(end.add(const Duration(seconds: 1)));
          }).toList();
          break;
      }

      return _calculateReportForOrders(filtered);
    },
    orElse: () => const SalesReportData(),
  );
});
