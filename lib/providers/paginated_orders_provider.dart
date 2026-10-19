import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../repositories/cafe_repository.dart';
import 'repository_providers.dart';
import 'reports_provider.dart';

class PaginatedOrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final int offset;
  final String? errorMessage;
  final DateRangeFilter? filter;

  const PaginatedOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastDoc,
    this.offset = 0,
    this.errorMessage,
    this.filter,
  });

  PaginatedOrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    int? offset,
    String? errorMessage,
    DateRangeFilter? filter,
  }) {
    return PaginatedOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      offset: offset ?? this.offset,
      errorMessage: errorMessage,
      filter: filter ?? this.filter,
    );
  }
}

class PaginatedOrdersNotifier extends StateNotifier<PaginatedOrdersState> {
  final CafeRepository _repository;

  PaginatedOrdersNotifier(this._repository) : super(const PaginatedOrdersState());

  Future<void> fetchFirstBatch(DateRangeFilter filter) async {
    state = state.copyWith(
      isLoading: true,
      orders: [],
      hasMore: true,
      lastDoc: null,
      offset: 0,
      filter: filter,
      errorMessage: null,
    );

    try {
      final result = await _repository.getOrdersPaginated(
        limit: 10,
        startDate: filter.start,
        endDate: filter.end,
        offset: 0,
      );

      state = state.copyWith(
        orders: result.orders,
        isLoading: false,
        hasMore: result.hasMore,
        lastDoc: result.lastDocument,
        offset: result.orders.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> fetchNextBatch() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final filter = state.filter;
      final result = await _repository.getOrdersPaginated(
        limit: 10,
        startAfterDoc: state.lastDoc,
        startDate: filter?.start,
        endDate: filter?.end,
        offset: state.offset,
      );

      // Prevent duplicate orders
      final existingIds = state.orders.map((o) => o.id).toSet();
      final uniqueNew = result.orders.where((o) => !existingIds.contains(o.id)).toList();

      state = state.copyWith(
        orders: [...state.orders, ...uniqueNew],
        isLoadingMore: false,
        hasMore: result.hasMore && result.orders.isNotEmpty,
        lastDoc: result.lastDocument ?? state.lastDoc,
        offset: state.offset + result.orders.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  void refresh() {
    if (state.filter != null) {
      fetchFirstBatch(state.filter!);
    }
  }
}

final dashboardOrdersPaginationProvider =
    StateNotifierProvider<PaginatedOrdersNotifier, PaginatedOrdersState>((ref) {
  final repo = ref.watch(cafeRepositoryProvider);
  return PaginatedOrdersNotifier(repo);
});

final reportsOrdersPaginationProvider =
    StateNotifierProvider<PaginatedOrdersNotifier, PaginatedOrdersState>((ref) {
  final repo = ref.watch(cafeRepositoryProvider);
  return PaginatedOrdersNotifier(repo);
});
