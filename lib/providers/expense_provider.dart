import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../repositories/cafe_repository.dart';
import 'repository_providers.dart';

class ExpenseNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  final CafeRepository _repository;
  StreamSubscription<List<ExpenseModel>>? _subscription;

  ExpenseNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initStream();
  }

  void _initStream() {
    _subscription?.cancel();
    _subscription = _repository.expensesStream().listen(
      (expenses) {
        state = AsyncValue.data(expenses);
      },
      onError: (err, st) {
        loadExpenses();
      },
    );
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      if (state is! AsyncData) {
        state = const AsyncValue.loading();
      }
      final list = await _repository.getExpenses();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> saveExpense(ExpenseModel expense) async {
    await _repository.saveExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _repository.deleteExpense(id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<ExpenseModel>>>((ref) {
  final repo = ref.watch(cafeRepositoryProvider);
  return ExpenseNotifier(repo);
});

final expenseDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return DateTimeRange(start: start, end: end);
});
