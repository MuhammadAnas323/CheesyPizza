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

  void _openAddCategory() async {
    final newCat = await showDialog<CategoryModel>(
      context: context,
      builder: (ctx) => const CategoryFormDialog(),
    );
    if (newCat != null) {
      await ref.read(categoryNotifierProvider.notifier).saveCategory(newCat);
      if (mounted) {
        setState(() {
          _selectedCategoryId = newCat.id; // Automatically select newly added category
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
                // Header Row (Add Categories & Add Items buttons)
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
                            'Manage categories as filters and add items to your menu (Long-press any item to delete)',
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

                // Products List filtered by selected category chip
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
                          final catName = categoriesAsync.maybeWhen(
                            data: (cats) => cats
                                .firstWhere((c) => c.id == product.categoryId,
                                    orElse: () => const CategoryModel(
                                        id: '', name: 'General', iconName: ''))
                                .name,
                            orElse: () => '',
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onLongPress: () => _confirmDeleteProduct(product),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 10 : 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: isMobile ? 36 : 42,
                                      height: isMobile ? 36 : 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.lightRed,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.fastfood,
                                          color: AppColors.primaryRed, size: isMobile ? 18 : 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product.name,
                                                  style: TextStyle(
                                                    fontSize: isMobile ? 13.5 : 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                              ),
                                              if (catName.isNotEmpty) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.lightGrey,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    catName,
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.mediumGrey),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (product.description.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              product.description,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: product.sizes.map((s) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.lightYellow,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${s.name}: ${CurrencyFormatter.format(s.price)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                          tooltip: 'Edit Item',
                                          onPressed: () => _openEditProduct(product),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
