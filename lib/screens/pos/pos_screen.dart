import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../models/order_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import 'widgets/product_customization_dialog.dart';
import 'widgets/cart_sidebar.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onProductTapped(ProductModel product, String categoryName) {
    if (!product.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} is currently marked unavailable'),
          backgroundColor: AppColors.mediumGrey,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    if (product.hasSizes || product.availableToppings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => ProductCustomizationDialog(
          product: product,
          categoryName: categoryName,
          onAddToCart: (orderItem) {
            ref.read(cartNotifierProvider.notifier).addItem(orderItem);
          },
        ),
      );
    } else {
      // Direct add to cart
      final orderItem = OrderItem(
        productId: product.id,
        productName: product.name,
        categoryId: product.categoryId,
        categoryName: categoryName,
        unitPrice: product.basePrice,
        unitCostPrice: product.baseCostPrice,
        quantity: 1,
      );
      ref.read(cartNotifierProvider.notifier).addItem(orderItem);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${product.name} to order'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'local_pizza':
        return Icons.local_pizza;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'local_offer':
        return Icons.local_offer;
      case 'fastfood':
        return Icons.fastfood;
      case 'local_drink':
        return Icons.local_drink;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);
    final selectedCatId = ref.watch(selectedCategoryIdProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final cart = ref.watch(cartNotifierProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopOrTablet = screenWidth >= 800;

    return Scaffold(
      body: Row(
        children: [
          // Left: Menu & Categories & Search
          Expanded(
            flex: isDesktopOrTablet ? 7 : 12,
            child: Column(
              children: [
                // Search & Filter Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search pizza, burgers, deals, drinks...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(productSearchQueryProvider.notifier)
                                          .state = '';
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            ref
                                .read(productSearchQueryProvider.notifier)
                                .state = val;
                          },
                        ),
                      ),
                      if (!isDesktopOrTablet) ...[
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart,
                                  color: AppColors.primaryRed),
                              onPressed: () {
                                _openCartDrawer(context);
                              },
                            ),
                            if (cart.items.isNotEmpty)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.cheeseYellow,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${cart.totalItemCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Category Tabs / Chips
                Container(
                  color: Colors.white,
                  height: 52,
                  child: categoriesAsync.when(
                    data: (categories) {
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8, bottom: 8),
                            child: FilterChip(
                              label: const Text('All Items'),
                              selected: selectedCatId == null || selectedCatId.isEmpty,
                              selectedColor: AppColors.primaryRed,
                              labelStyle: TextStyle(
                                color: (selectedCatId == null || selectedCatId.isEmpty)
                                    ? Colors.white
                                    : AppColors.textDark,
                                fontWeight: (selectedCatId == null || selectedCatId.isEmpty)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                              onSelected: (_) {
                                ref.read(selectedCategoryIdProvider.notifier).state = null;
                              },
                            ),
                          ),
                          ...categories.map((cat) {
                            final isSelected = selectedCatId == cat.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8, bottom: 8),
                              child: FilterChip(
                                avatar: Icon(
                                  _getCategoryIcon(cat.iconName),
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primaryRed,
                                ),
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
                                  fontSize: 13,
                                ),
                                onSelected: (_) {
                                  ref
                                      .read(selectedCategoryIdProvider.notifier)
                                      .state = cat.id;
                                },
                              ),
                            );
                          }),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const SizedBox(),
                  ),
                ),

                const Divider(height: 1),

                // Product Grid
                Expanded(
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.search_off,
                                  size: 48, color: AppColors.mediumGrey),
                              SizedBox(height: 12),
                              Text(
                                'No products found',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Responsive columns
                            int crossAxisCount = constraints.maxWidth > 900
                                ? 3
                                : (constraints.maxWidth > 550 ? 2 : 1);
                            double childAspectRatio = constraints.maxWidth > 550 ? 1.6 : 2.4;

                            return GridView.builder(
                              padding: const EdgeInsets.all(14),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final categoryName = categoriesAsync.maybeWhen(
                                  data: (cats) => cats
                                      .firstWhere((c) => c.id == product.categoryId,
                                          orElse: () => const CategoryModel(
                                              id: '', name: 'General', iconName: ''))
                                      .name,
                                  orElse: () => '',
                                );

                                return _buildProductCard(
                                    product, categoryName, isDesktopOrTablet);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Right: Sticky Order Cart (on Desktop & Tablet)
          if (isDesktopOrTablet)
            const Expanded(
              flex: 4,
              child: CartSidebar(),
            ),
        ],
      ),
      bottomNavigationBar: !isDesktopOrTablet && cart.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openCartDrawer(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag),
                        const SizedBox(width: 8),
                        Text('${cart.totalItemCount} Items'),
                      ],
                    ),
                    Text(
                      'View Order • ${CurrencyFormatter.format(cart.totalBill)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProductCard(
      ProductModel product, String categoryName, bool isDesktop) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: product.isAvailable
              ? AppColors.borderGrey
              : Colors.red.withAlpha(80),
          width: 0.8,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onProductTapped(product, categoryName),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Title & Category Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!product.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (product.hasSizes)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightYellow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Multi-size',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              // Description
              if (product.description.isNotEmpty)
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              // Price & Add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.hasSizes)
                        const Text(
                          'Starting from',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      Text(
                        CurrencyFormatter.format(product.displayStartingPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: product.isAvailable
                          ? AppColors.primaryRed
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      product.hasSizes || product.availableToppings.isNotEmpty
                          ? Icons.tune
                          : Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCartDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: const CartSidebar(isMobileDrawer: true),
        ),
      ),
    );
  }
}
