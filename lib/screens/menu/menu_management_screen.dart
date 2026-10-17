import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import 'widgets/product_form_dialog.dart';
import 'widgets/category_form_dialog.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  String? _selectedCategoryId; // null means 'All'
  String? _expandedProductId;  // tracks which card is expanded

  void _openAddCategory() async {
    final newCat = await showDialog<CategoryModel>(
      context: context,
      builder: (ctx) => const CategoryFormDialog(),
    );
    if (newCat != null) {
      await ref.read(categoryNotifierProvider.notifier).saveCategory(newCat);
      if (mounted) {
        setState(() {
          _selectedCategoryId = newCat.id;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${newCat.name}" added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _openAddProduct() async {
    final categories = ref.read(categoryNotifierProvider).asData?.value ?? [];
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a category first before adding items.')),
      );
      return;
    }

    final targetCatId = _selectedCategoryId ?? categories.first.id;

    final newProduct = await showDialog<ProductModel>(
      context: context,
      builder: (ctx) => ProductFormDialog(categoryId: targetCatId),
    );
    if (newProduct != null) {
      await ref.read(productNotifierProvider.notifier).saveProduct(newProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newProduct.name} added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _openEditProduct(ProductModel product) async {
    final updatedProduct = await showDialog<ProductModel>(
      context: context,
      builder: (ctx) => ProductFormDialog(
        categoryId: product.categoryId,
        productToEdit: product,
      ),
    );
    if (updatedProduct != null) {
      await ref.read(productNotifierProvider.notifier).saveProduct(updatedProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${updatedProduct.name} updated!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final prodName = product.name;
              Navigator.pop(ctx);
              await ref.read(productNotifierProvider.notifier).deleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item "$prodName" deleted!'),
                    backgroundColor: AppColors.mediumGrey,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showProductActionSheet(ProductModel product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.lightRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fastfood, color: AppColors.primaryRed, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.sizes.isNotEmpty
                                ? '${product.sizes.length} size option(s)'
                                : CurrencyFormatter.format(product.basePrice),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                ),
                title: const Text(
                  'Edit Menu Item',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                subtitle: const Text(
                  'Update item name, description, sizes and prices',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openEditProduct(product);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                ),
                title: const Text(
                  'Delete Menu Item',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.danger),
                ),
                subtitle: const Text(
                  'Remove this item from the cafe menu',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteProduct(product);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final productsAsync = ref.watch(productNotifierProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          return Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Menu Management',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap card to expand details • Long-press to edit or delete',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 10 : 14,
                                vertical: isMobile ? 8 : 10),
                          ),
                          icon: const Icon(Icons.category, size: 16),
                          label: Text('Add Categories',
                              style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.bold)),
                          onPressed: _openAddCategory,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 10 : 16,
                                vertical: isMobile ? 8 : 10),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text('Add Items',
                              style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.bold)),
                          onPressed: _openAddProduct,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Categories as Filter Chips
                categoriesAsync.when(
                  data: (categories) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All Categories'),
                              selected: _selectedCategoryId == null,
                              selectedColor: AppColors.primaryRed,
                              labelStyle: TextStyle(
                                color: _selectedCategoryId == null
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontWeight: _selectedCategoryId == null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12.5,
                              ),
                              onSelected: (_) => setState(() => _selectedCategoryId = null),
                            ),
                          ),
                          ...categories.map((cat) {
                            final isSelected = _selectedCategoryId == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(cat.name),
                                selected: isSelected,
                                selectedColor: AppColors.primaryRed,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textDark,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12.5,
                                ),
                                onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const SizedBox(),
                ),
                const SizedBox(height: 16),

                // Products List
                Expanded(
                  child: productsAsync.when(
                    data: (products) {
                      final filtered = products.where((p) {
                        final matchCat = _selectedCategoryId == null ||
                            p.categoryId == _selectedCategoryId;
                        return matchCat;
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: AppColors.lightYellow,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.fastfood_outlined, size: 48, color: AppColors.cheeseYellow),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Items Found',
                                  style: TextStyle(fontSize: 17, color: AppColors.textDark, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Use the "Add Items" button in the top header to create items for this filter.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          final isExpanded = _expandedProductId == product.id;

                          final catName = categoriesAsync.maybeWhen(
                            data: (cats) => cats
                                .firstWhere((c) => c.id == product.categoryId,
                                    orElse: () => const CategoryModel(
                                        id: '', name: 'General', iconName: ''))
                                .name,
                            orElse: () => '',
                          );

                          return _MenuItemCard(
                            product: product,
                            catName: catName,
                            isMobile: isMobile,
                            isExpanded: isExpanded,
                            onTap: () => setState(() {
                              _expandedProductId =
                                  isExpanded ? null : product.id;
                            }),
                            onLongPress: () => _showProductActionSheet(product),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(child: Text('Error loading orders')),
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

// ─────────────────────────────────────────────────────────────────────────────
// Extracted card widget with animated expand/collapse
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.product,
    required this.catName,
    required this.isMobile,
    required this.isExpanded,
    required this.onTap,
    required this.onLongPress,
  });

  final ProductModel product;
  final String catName;
  final bool isMobile;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isExpanded ? 3 : 1.5,
      shadowColor: Colors.black.withAlpha(isExpanded ? 35 : 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isExpanded
              ? AppColors.primaryRed.withAlpha(120)
              : AppColors.borderGrey.withAlpha(150),
          width: isExpanded ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Collapsed header row ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: isMobile ? 42 : 48,
                    height: isMobile ? 42 : 48,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppColors.primaryRed.withAlpha(20)
                          : AppColors.lightRed.withAlpha(60),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primaryRed.withAlpha(isExpanded ? 80 : 30)),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: AppColors.primaryRed,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name + category badge
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (catName.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.lightRed.withAlpha(35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                catName,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryRed,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Expand/collapse chevron
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? AppColors.primaryRed : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // ── Animated expanded detail panel ────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _ExpandedDetail(
                product: product,
                catName: catName,
                isMobile: isMobile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanded detail panel content
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandedDetail extends StatelessWidget {
  const _ExpandedDetail({
    required this.product,
    required this.catName,
    required this.isMobile,
  });

  final ProductModel product;
  final String catName;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightRed.withAlpha(10),
        border: Border(
          top: BorderSide(color: AppColors.primaryRed.withAlpha(40)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 18,
        12,
        isMobile ? 14 : 18,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info rows ──────────────────────────────────────────────────
          _DetailRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: catName.isEmpty ? 'General' : catName,
          ),

          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Description',
              value: product.description,
              multiLine: true,
            ),
          ],

          const SizedBox(height: 14),

          // ── Size & price table ─────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.local_offer_outlined,
                  size: 14, color: AppColors.primaryRed),
              const SizedBox(width: 6),
              Text(
                product.sizes.length == 1 ? 'Price' : 'Sizes & Prices',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Size chips — full overflow-safe version
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: product.sizes.map((s) {
              final hasName = s.name.trim().isNotEmpty;
              final priceStr = CurrencyFormatter.format(s.price);
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.lightYellow.withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.cheeseYellow.withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasName) ...[
                        Flexible(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 1,
                          height: 12,
                          color: AppColors.borderGrey,
                        ),
                      ],
                      Text(
                        priceStr,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // ── Actions row ────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.touch_app_outlined,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              const Text(
                'Long-press the card to edit or delete',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool multiLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            maxLines: multiLine ? 4 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
