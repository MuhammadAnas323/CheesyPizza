import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showExpenseDialog({ExpenseModel? expense}) {
    final noteController = TextEditingController(text: expense?.note ?? '');
    final amountController = TextEditingController(
        text: expense != null ? expense.amount.toString() : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          expense == null ? 'Add New Expense' : 'Edit Expense',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Description / Note',
                    hintText: 'e.g. Electricity bill, Tomatoes, Gas cylinder',
                    prefixIcon: Icon(Icons.note),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (Rs.)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.payments),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(val) == null || double.parse(val) <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final note = noteController.text.trim();
                final amount = double.parse(amountController.text.trim());

                if (expense == null) {
                  final newExp = ExpenseModel(
                    note: note,
                    amount: amount,
                    createdAt: DateTime.now(),
                  );
                  await ref.read(expenseNotifierProvider.notifier).saveExpense(newExp);
                } else {
                  final updated = expense.copyWith(
                    note: note,
                    amount: amount,
                  );
                  await ref.read(expenseNotifierProvider.notifier).saveExpense(updated);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(expense == null ? 'Save Expense' : 'Update Expense'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.note}" (${CurrencyFormatter.format(expense.amount)})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseNotifierProvider);
    final dateRange = ref.watch(expenseDateRangeProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          return Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
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
                        children: [
                          Text(
                            'Cafe Expenses Management',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Record and track daily cafe operating expenses',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 10 : 12),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('Add', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                      onPressed: () => _showExpenseDialog(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metrics / Summary Cards (Responsive layout)
                expensesAsync.maybeWhen(
                  data: (expenses) {
                    final now = DateTime.now();
                    final todayExpenses = expenses.where((e) =>
                        e.createdAt.year == now.year &&
                        e.createdAt.month == now.month &&
                        e.createdAt.day == now.day);
                    final double todayTotal =
                        todayExpenses.fold(0.0, (sum, e) => sum + e.amount);

                    final rangeExpenses = expenses.where((e) {
                      final start = DateTime(
                          dateRange.start.year, dateRange.start.month, dateRange.start.day, 0, 0, 0);
                      final end = DateTime(
                          dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
                      return e.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                          e.createdAt.isBefore(end.add(const Duration(seconds: 1)));
                    });
                    final double rangeTotal =
                        rangeExpenses.fold(0.0, (sum, e) => sum + e.amount);

                    final todayCard = Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Today's Expenses",
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted)),
                            const SizedBox(height: 6),
                            Text(
                              CurrencyFormatter.format(todayTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('${todayExpenses.length} entries today',
                                style: const TextStyle(
                                    fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    );

                    final rangeCard = Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Range Total",
                                    style: TextStyle(
                                        fontSize: 12, color: AppColors.textMuted)),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDateRangePicker(
                                      context: context,
                                      firstDate: DateTime(2023),
                                      lastDate: DateTime.now().add(const Duration(days: 1)),
                                      initialDateRange: dateRange,
                                    );
                                    if (picked != null) {
                                      ref.read(expenseDateRangeProvider.notifier).state = picked;
                                    }
                                  },
                                  child: const Text('Change',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryRed)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              CurrencyFormatter.format(rangeTotal),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormatter.formatShort(dateRange.start)} - ${DateFormatter.formatShort(dateRange.end)}',
                              style: const TextStyle(
                                  fontSize: 10.5, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          todayCard,
                          const SizedBox(height: 8),
                          rangeCard,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: todayCard),
                        const SizedBox(width: 14),
                        Expanded(child: rangeCard),
                      ],
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Search bar
                SizedBox(
                  width: isMobile ? double.infinity : 300,
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search expense notes...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),

                // Expenses List
                Expanded(
                  child: expensesAsync.when(
                    data: (expenses) {
                      final query = _searchController.text.trim().toLowerCase();
                      final filtered = expenses.where((e) {
                        return query.isEmpty || e.note.toLowerCase().contains(query);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No expenses recorded yet. Click "Add" to start.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final expense = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.lightRed,
                                child: const Icon(Icons.receipt, color: AppColors.primaryRed, size: 18),
                              ),
                              title: Text(
                                expense.note,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.textDark,
                                ),
                              ),
                              subtitle: Text(
                                DateFormatter.formatDateTime(expense.createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(expense.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () => _showExpenseDialog(expense: expense),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16, color: AppColors.danger),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () => _confirmDelete(expense),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
