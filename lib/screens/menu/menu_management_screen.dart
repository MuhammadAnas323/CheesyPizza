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
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddProduct() async {
    final newProduct = await showDialog<ProductModel>(
      context: context,
      builder: (ctx) => const ProductFormDialog(),
    );
    if (newProduct != null) {
      await ref.read(productNotifierProvider.notifier).saveProduct(newProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newProduct.name} created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _openEditProduct(ProductModel product) async {
    final updatedProduct = await showDialog<ProductModel>(
      context: context,
      builder: (ctx) => ProductFormDialog(productToEdit: product),
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
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(productNotifierProvider.notifier).deleteProduct(product.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${product.name}'),
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

  void _openCategoriesManager() {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final categoriesAsync = ref.watch(categoryNotifierProvider);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.category, color: AppColors.primaryRed),
                    SizedBox(width: 8),
                    Text('Manage Categories'),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Category'),
                  onPressed: () async {
                    final newCat = await showDialog<CategoryModel>(
                      context: context,
                      builder: (_) => const CategoryFormDialog(),
                    );
                    if (newCat != null) {
                      await ref
                          .read(categoryNotifierProvider.notifier)
                          .saveCategory(newCat);
                    }
                  },
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 380,
              child: categoriesAsync.when(
                data: (categories) {
                  return ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.lightRed,
                          child: const Icon(Icons.fastfood,
                              color: AppColors.primaryRed, size: 20),
                        ),
                        title: Text(cat.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Display Order: ${cat.displayOrder}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () async {
                                final edited = await showDialog<CategoryModel>(
                                  context: context,
                                  builder: (_) => CategoryFormDialog(categoryToEdit: cat),
                                );
                                if (edited != null) {
                                  await ref
                                      .read(categoryNotifierProvider.notifier)
                                      .saveCategory(edited);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.danger),
                              onPressed: () async {
                                await ref
                                    .read(categoryNotifierProvider.notifier)
                                    .deleteCategory(cat.id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text('Error loading categories')),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final productsAsync = ref.watch(productNotifierProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Menu & Products Management',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Add, edit, set prices, pizza sizes, extra toppings, and recipes',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.category, size: 18),
                  label: const Text('Categories'),
                  onPressed: _openCategoriesManager,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                  onPressed: _openAddProduct,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter & Search Row
            Row(
              children: [
                // Category Filter Chips
                Expanded(
                  child: categoriesAsync.when(
                    data: (categories) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('All Categories'),
                                selected: _selectedCategory == null,
                                selectedColor: AppColors.primaryRed,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == null
                                      ? Colors.white
                                      : AppColors.textDark,
                                  fontWeight: _selectedCategory == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setState(() => _selectedCategory = null);
                                },
                              ),
                            ),
                            ...categories.map((cat) {
                              final isSelected = _selectedCategory == cat.id;
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
                                  ),
                                  onSelected: (_) {
                                    setState(() => _selectedCategory = cat.id);
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, _) => const SizedBox(),
                  ),
                ),
                const SizedBox(width: 14),

                // Search Box
                SizedBox(
                  width: 260,
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Products List
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = products.where((p) {
                    final matchCat =
                        _selectedCategory == null || p.categoryId == _selectedCategory;
                    final matchQuery = query.isEmpty ||
                        p.name.toLowerCase().contains(query) ||
                        p.description.toLowerCase().contains(query);
                    return matchCat && matchQuery;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: AppColors.mediumGrey),
                          SizedBox(height: 12),
                          Text(
                            'No products match your criteria.',
                            style: TextStyle(
                                fontSize: 15, color: AppColors.textMuted),
                          ),
                        ],
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
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar / Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: product.isAvailable
                                      ? AppColors.lightRed
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.fastfood,
                                  color: product.isAvailable
                                      ? AppColors.primaryRed
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Product Info
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.lightGrey,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: AppColors.borderGrey),
                                          ),
                                          child: Text(
                                            catName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mediumGrey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (product.description.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        product.description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 6),

                                    // Sizes or Toppings Chips
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (product.hasSizes &&
                                            product.sizes.isNotEmpty)
                                          ...product.sizes.map((s) => Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.lightYellow,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${s.name}: ${CurrencyFormatter.format(s.price)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textDark,
                                                  ),
                                                ),
                                              ))
                                        else
                                          Text(
                                            'Price: ${CurrencyFormatter.format(product.basePrice)} (Cost: ${CurrencyFormatter.format(product.baseCostPrice)})',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryRed,
                                            ),
                                          ),
                                        if (product.availableToppings.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${product.availableToppings.length} Toppings',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade900,
                                              ),
                                            ),
                                          ),
                                        if (product.recipe.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Recipe: ${product.recipe.length} ingredients',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade900,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Availability Toggle
                              Column(
                                children: [
                                  Switch(
                                    value: product.isAvailable,
                                    activeThumbColor: AppColors.success,
                                    onChanged: (val) {
                                      ref
                                          .read(productNotifierProvider.notifier)
                                          .toggleAvailability(product.id);
                                    },
                                  ),
                                  Text(
                                    product.isAvailable
                                        ? 'Available'
                                        : 'Unavailable',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: product.isAvailable
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),

                              // Actions
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 20, color: AppColors.mediumGrey),
                                    tooltip: 'Edit Product',
                                    onPressed: () => _openEditProduct(product),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: AppColors.danger),
                                    tooltip: 'Delete Product',
                                    onPressed: () =>
                                        _confirmDeleteProduct(product),
                                  ),
                                ],
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
      ),
    );
  }
}
