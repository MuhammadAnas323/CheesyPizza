import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../../models/order_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class ProductCustomizationDialog extends StatefulWidget {
  final ProductModel product;
  final String categoryName;
  final Function(OrderItem) onAddToCart;

  const ProductCustomizationDialog({
    super.key,
    required this.product,
    required this.categoryName,
    required this.onAddToCart,
  });

  @override
  State<ProductCustomizationDialog> createState() =>
      _ProductCustomizationDialogState();
}

class _ProductCustomizationDialogState
    extends State<ProductCustomizationDialog> {
  ProductSize? _selectedSize;
  final Set<ProductTopping> _selectedToppings = {};
  int _quantity = 1;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product.hasSizes && widget.product.sizes.isNotEmpty) {
      // Default to medium or first size
      _selectedSize = widget.product.sizes.length > 1
          ? widget.product.sizes[1]
          : widget.product.sizes.first;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  double get _currentUnitPrice {
    if (widget.product.hasSizes && _selectedSize != null) {
      return _selectedSize!.price;
    }
    return widget.product.basePrice;
  }

  double get _currentUnitCost {
    if (widget.product.hasSizes && _selectedSize != null) {
      return _selectedSize!.costPrice;
    }
    return widget.product.baseCostPrice;
  }

  double get _toppingsPrice {
    return _selectedToppings.fold(0.0, (sum, t) => sum + t.price);
  }

  double get _totalItemPrice {
    return (_currentUnitPrice + _toppingsPrice) * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.categoryName,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.description.isNotEmpty) ...[
                      Text(
                        widget.product.description,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sizes section
                    if (widget.product.hasSizes && widget.product.sizes.isNotEmpty) ...[
                      const Text(
                        'Select Size',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.product.sizes.map((size) {
                          final isSelected = _selectedSize == size;
                          return ChoiceChip(
                            label: Text(
                              '${size.name} • ${CurrencyFormatter.format(size.price)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textDark,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primaryRed,
                            backgroundColor: Colors.white,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedSize = size);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Extra Toppings section
                    if (widget.product.availableToppings.isNotEmpty) ...[
                      const Text(
                        'Optional Extra Toppings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: widget.product.availableToppings.map((topping) {
                          final isChecked = _selectedToppings.contains(topping);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              topping.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              '+ ${CurrencyFormatter.format(topping.price)}',
                              style: const TextStyle(
                                color: AppColors.primaryRed,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            value: isChecked,
                            activeColor: AppColors.primaryRed,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedToppings.add(topping);
                                } else {
                                  _selectedToppings.remove(topping);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Special instructions / notes
                    const Text(
                      'Special Preparation Note (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Less spicy, crispy crust, no mayo',
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Quantity selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderGrey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: () => setState(() => _quantity++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer / Add to Cart Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: AppColors.borderGrey),
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(_totalItemPrice),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Add to Order'),
                    onPressed: () {
                      final orderItem = OrderItem(
                        productId: widget.product.id,
                        productName: widget.product.name,
                        categoryId: widget.product.categoryId,
                        categoryName: widget.categoryName,
                        selectedSize: _selectedSize?.name,
                        selectedToppings: _selectedToppings
                            .map((t) => OrderItemTopping(
                                  name: t.name,
                                  price: t.price,
                                  costPrice: t.costPrice,
                                ))
                            .toList(),
                        unitPrice: _currentUnitPrice,
                        unitCostPrice: _currentUnitCost,
                        quantity: _quantity,
                        notes: _notesController.text.trim().isNotEmpty
                            ? _notesController.text.trim()
                            : null,
                      );
                      widget.onAddToCart(orderItem);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
