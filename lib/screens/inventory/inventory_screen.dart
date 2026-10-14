import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import 'widgets/stock_item_form_dialog.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  void _openAddItem(BuildContext context, WidgetRef ref) async {
    final newItem = await showDialog<InventoryItem>(
      context: context,
      builder: (ctx) => const StockItemFormDialog(),
    );
    if (newItem != null) {
      await ref.read(inventoryNotifierProvider.notifier).saveItem(newItem);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newItem.name} added to stock!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _openEditItem(
      BuildContext context, WidgetRef ref, InventoryItem item) async {
    final updatedItem = await showDialog<InventoryItem>(
      context: context,
      builder: (ctx) => StockItemFormDialog(itemToEdit: item),
    );
    if (updatedItem != null) {
      await ref.read(inventoryNotifierProvider.notifier).saveItem(updatedItem);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedItem.name} updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _openRestockDialog(
      BuildContext context, WidgetRef ref, InventoryItem item) {
    final qtyCtrl = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_shopping_cart, color: AppColors.success),
            const SizedBox(width: 8),
            Text('Restock: ${item.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${item.currentStock} ${item.unit}'),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantity to Add (${item.unit})',
                hintText: 'e.g. 5, 10, 20',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              final added = double.tryParse(qtyCtrl.text) ?? 0.0;
              if (added > 0) {
                await ref
                    .read(inventoryNotifierProvider.notifier)
                    .restock(item.id, added);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Added $added ${item.unit} to ${item.name}!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Stock Item?'),
        content: Text('Remove "${item.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(inventoryNotifierProvider.notifier)
                  .deleteItem(item.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredItems = ref.watch(filteredInventoryProvider);
    final onlyLowStock = ref.watch(inventoryFilterLowStockProvider);
    final totalLowStock = ref.watch(lowStockCountProvider);
    final inventoryAsync = ref.watch(inventoryNotifierProvider);

    // Compute total inventory valuation
    final totalValuation = inventoryAsync.maybeWhen(
      data: (items) => items.fold(
          0.0, (sum, i) => sum + (i.currentStock * i.costPerUnit)),
      orElse: () => 0.0,
    );
    final totalItemsCount = inventoryAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventory & Ingredients',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Track cheese, flour, chicken, buns & stock alerts',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 16,
                            vertical: isMobile ? 8 : 12),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'Add Item',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      onPressed: () => _openAddItem(context, ref),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Metrics Summary Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;

                final card1 = SizedBox(
                  width: isMobile ? 170 : null,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory,
                                color: AppColors.primaryRed, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Items',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted)),
                                Text(
                                  '$totalItemsCount Items',
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                final card2 = SizedBox(
                  width: isMobile ? 170 : null,
                  child: Card(
                    color: totalLowStock > 0 ? AppColors.warningLight : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: totalLowStock > 0
                                  ? AppColors.warning.withAlpha(40)
                                  : AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.warning_amber_rounded,
                                color: totalLowStock > 0
                                    ? AppColors.warning
                                    : AppColors.mediumGrey,
                                size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Low Stock',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted)),
                                Text(
                                  '$totalLowStock Items',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: totalLowStock > 0
                                        ? AppColors.warning
                                        : AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                final card3 = SizedBox(
                  width: isMobile ? 180 : null,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightYellow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_balance_wallet,
                                color: AppColors.cheeseYellow, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Valuation',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted)),
                                Text(
                                  CurrencyFormatter.format(totalValuation),
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                if (isMobile) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        card1,
                        const SizedBox(width: 8),
                        card2,
                        const SizedBox(width: 8),
                        card3,
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 12),
                    Expanded(child: card2),
                    const SizedBox(width: 12),
                    Expanded(child: card3),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Filter & Search Controls
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;
                final chips = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilterChip(
                      label: const Text('All Stock'),
                      selected: !onlyLowStock,
                      selectedColor: AppColors.primaryRed,
                      labelStyle: TextStyle(
                        color: !onlyLowStock ? Colors.white : AppColors.textDark,
                        fontWeight:
                            !onlyLowStock ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        ref
                            .read(inventoryFilterLowStockProvider.notifier)
                            .state = false;
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: const Icon(Icons.warning, size: 14, color: Colors.white),
                      label: Text('Low Stock ($totalLowStock)'),
                      selected: onlyLowStock,
                      selectedColor: AppColors.warning,
                      labelStyle: TextStyle(
                        color: onlyLowStock ? Colors.white : AppColors.textDark,
                        fontWeight:
                            onlyLowStock ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        ref
                            .read(inventoryFilterLowStockProvider.notifier)
                            .state = true;
                      },
                    ),
                  ],
                );

                final searchField = SizedBox(
                  width: isMobile ? double.infinity : 250,
                  height: 38,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search stock...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onChanged: (val) {
                      ref
                          .read(inventorySearchQueryProvider.notifier)
                          .state = val;
                    },
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: chips,
                      ),
                      const SizedBox(height: 10),
                      searchField,
                    ],
                  );
                }

                return Row(
                  children: [
                    chips,
                    const Spacer(),
                    searchField,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Inventory List
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: AppColors.mediumGrey),
                          SizedBox(height: 12),
                          Text(
                            'No inventory items found.',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 650;

                        return ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isLow = item.isLowStock;

                            if (isMobile) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: isLow
                                                  ? AppColors.warningLight
                                                  : AppColors.lightGrey,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              isLow
                                                  ? Icons.warning_amber_rounded
                                                  : Icons.inventory_2,
                                              color: isLow
                                                  ? AppColors.warning
                                                  : AppColors.mediumGrey,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors.textDark,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                              horizontal: 5,
                                                              vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.lightGrey,
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        item.category,
                                                        style: const TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors.mediumGrey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${CurrencyFormatter.format(item.costPerUnit)} / ${item.unit}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isLow
                                                      ? AppColors.warning
                                                      : AppColors.textDark,
                                                ),
                                              ),
                                              if (isLow)
                                                const Text(
                                                  'LOW STOCK',
                                                  style: TextStyle(
                                                    color: AppColors.warning,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 14),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Alert <= ${item.minStockAlert.toStringAsFixed(1)} ${item.unit}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted),
                                          ),
                                          Row(
                                            children: [
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.success,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                ),
                                                icon: const Icon(Icons.add,
                                                    size: 14),
                                                label: const Text('Restock',
                                                    style:
                                                        TextStyle(fontSize: 11)),
                                                onPressed: () =>
                                                    _openRestockDialog(
                                                        context, ref, item),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(Icons.edit,
                                                    size: 16,
                                                    color: AppColors.mediumGrey),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: () => _openEditItem(
                                                    context, ref, item),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 16,
                                                    color: AppColors.danger),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: () => _confirmDelete(
                                                    context, ref, item),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Status Indicator Icon
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isLow
                                            ? AppColors.warningLight
                                            : AppColors.lightGrey,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isLow
                                              ? AppColors.warning
                                              : AppColors.borderGrey,
                                        ),
                                      ),
                                      child: Icon(
                                        isLow
                                            ? Icons.warning_amber_rounded
                                            : Icons.inventory_2,
                                        color: isLow
                                            ? AppColors.warning
                                            : AppColors.mediumGrey,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Details
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.lightGrey,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item.category,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.mediumGrey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Cost: ${CurrencyFormatter.format(item.costPerUnit)} / ${item.unit}  •  Updated ${DateFormatter.formatRelative(item.lastUpdated)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Stock Level
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isLow
                                                      ? AppColors.warning
                                                      : AppColors.textDark,
                                                ),
                                              ),
                                              if (isLow) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .warningLight,
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                    border: Border.all(
                                                        color:
                                                            AppColors.warning),
                                                  ),
                                                  child: const Text(
                                                    'LOW STOCK',
                                                    style: TextStyle(
                                                      color: AppColors.warning,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(
                                            'Alert at <= ${item.minStockAlert.toStringAsFixed(1)} ${item.unit}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Restock & Edit Actions
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Restock'),
                                      onPressed: () =>
                                          _openRestockDialog(context, ref, item),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 18,
                                          color: AppColors.mediumGrey),
                                      onPressed: () =>
                                          _openEditItem(context, ref, item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: AppColors.danger),
                                      onPressed: () =>
                                          _confirmDelete(context, ref, item),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
