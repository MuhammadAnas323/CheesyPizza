import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/product_model.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../core/theme/app_colors.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormDialog({super.key, this.productToEdit});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _basePriceController;
  late TextEditingController _baseCostController;

  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _hasSizes = false;

  List<ProductSize> _sizes = [];
  List<ProductTopping> _toppings = [];
  List<RecipeIngredient> _recipe = [];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _basePriceController = TextEditingController(
        text: p != null ? p.basePrice.toStringAsFixed(0) : '');
    _baseCostController = TextEditingController(
        text: p != null ? p.baseCostPrice.toStringAsFixed(0) : '');
    _selectedCategoryId = p?.categoryId;
    _isAvailable = p?.isAvailable ?? true;
    _hasSizes = p?.hasSizes ?? false;
    _sizes = p != null ? List.from(p.sizes) : [];
    _toppings = p != null ? List.from(p.availableToppings) : [];
    _recipe = p != null ? List.from(p.recipe) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _basePriceController.dispose();
    _baseCostController.dispose();
    super.dispose();
  }

  void _addSize() {
    final nameCtrl = TextEditingController(text: 'Large');
    final priceCtrl = TextEditingController(text: '1500');
    final costCtrl = TextEditingController(text: '650');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Size Name (e.g. Small, Medium, Large)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Selling Price (PKR)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cost Price (PKR)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              final cost = double.tryParse(costCtrl.text) ?? 0.0;
              if (nameCtrl.text.trim().isNotEmpty && price > 0) {
                setState(() {
                  _sizes.add(ProductSize(
                    name: nameCtrl.text.trim(),
                    price: price,
                    costPrice: cost,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addTopping() {
    final nameCtrl = TextEditingController(text: 'Extra Mozzarella');
    final priceCtrl = TextEditingController(text: '150');
    final costCtrl = TextEditingController(text: '70');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Topping / Add-on'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Topping Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Selling Price (PKR)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cost Price (PKR)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              final cost = double.tryParse(costCtrl.text) ?? 0.0;
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _toppings.add(ProductTopping(
                    name: nameCtrl.text.trim(),
                    price: price,
                    costPrice: cost,
                  ));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addRecipeIngredient() {
    final inventoryAsync = ref.read(inventoryNotifierProvider);
    inventoryAsync.whenData((items) {
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No inventory items found. Add inventory items first.')),
        );
        return;
      }

      String selectedInvId = items.first.id;
      final qtyCtrl = TextEditingController(text: '0.2');

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            final selectedItem = items.firstWhere((i) => i.id == selectedInvId);
            return AlertDialog(
              title: const Text('Link Recipe Ingredient'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedInvId,
                    decoration: const InputDecoration(labelText: 'Stock Item'),
                    items: items.map((inv) {
                      return DropdownMenuItem(
                        value: inv.id,
                        child: Text('${inv.name} (${inv.unit})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedInvId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty consumed per item (${selectedItem.unit})',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                    if (qty > 0) {
                      setState(() {
                        _recipe.add(RecipeIngredient(
                          inventoryItemId: selectedItem.id,
                          ingredientName: selectedItem.name,
                          quantityRequired: qty,
                          unit: selectedItem.unit,
                        ));
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add Ingredient'),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final basePrice = double.tryParse(_basePriceController.text) ?? 0.0;
    final baseCost = double.tryParse(_baseCostController.text) ?? 0.0;

    final product = ProductModel(
      id: widget.productToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId!,
      description: _descController.text.trim(),
      basePrice: basePrice,
      baseCostPrice: baseCost,
      isAvailable: _isAvailable,
      hasSizes: _hasSizes,
      sizes: _hasSizes ? _sizes : [],
      availableToppings: _toppings,
      recipe: _recipe,
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    widget.productToEdit == null
                        ? 'Add New Product'
                        : 'Edit Product',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          hintText: 'e.g. Chicken Fajita Pizza, Zinger Burger',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter product name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Category Dropdown
                      categoriesAsync.when(
                        data: (categories) {
                          if (_selectedCategoryId == null &&
                              categories.isNotEmpty) {
                            _selectedCategoryId = categories.first.id;
                          }
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Category *',
                            ),
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedCategoryId = val);
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const Text('Error loading categories'),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description / Ingredients overview',
                          hintText: 'e.g. Spicy chicken fajita, capsicum, rich mozzarella',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),

                      // Base Price & Base Cost
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _basePriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Base Selling Price (PKR) *',
                                prefixText: 'Rs. ',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter price';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _baseCostController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Base Cost Price (PKR) *',
                                prefixText: 'Rs. ',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Enter cost';
                                }
                                if (double.tryParse(val) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Availability Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Item Available for Sale'),
                        subtitle: const Text('Toggle off if temporarily out of stock'),
                        value: _isAvailable,
                        onChanged: (val) => setState(() => _isAvailable = val),
                      ),
                      const Divider(height: 24),

                      // Multi-size Switch & List
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Supports Multiple Sizes (e.g. Small / Medium / Large)'),
                        subtitle: const Text('Set custom pricing & costs per size'),
                        value: _hasSizes,
                        onChanged: (val) => setState(() => _hasSizes = val),
                      ),
                      if (_hasSizes) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Product Sizes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Size'),
                              onPressed: _addSize,
                            ),
                          ],
                        ),
                        if (_sizes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No sizes added yet. Click "+ Add Size" to configure.',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          )
                        else
                          ..._sizes.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final size = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                dense: true,
                                title: Text(size.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    'Sell: Rs. ${size.price.toStringAsFixed(0)} | Cost: Rs. ${size.costPrice.toStringAsFixed(0)} | Profit: Rs. ${(size.price - size.costPrice).toStringAsFixed(0)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: AppColors.danger),
                                  onPressed: () {
                                    setState(() => _sizes.removeAt(idx));
                                  },
                                ),
                              ),
                            );
                          }),
                        const Divider(height: 24),
                      ],

                      // Optional Extra Toppings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Optional Extra Toppings',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Topping'),
                            onPressed: _addTopping,
                          ),
                        ],
                      ),
                      if (_toppings.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No toppings configured. (e.g. Extra Mozzarella, Jalapenos, Mushrooms)',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        )
                      else
                        ..._toppings.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final topping = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              dense: true,
                              title: Text(topping.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '+ Rs. ${topping.price.toStringAsFixed(0)} (Cost: Rs. ${topping.costPrice.toStringAsFixed(0)})'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.danger),
                                onPressed: () {
                                  setState(() => _toppings.removeAt(idx));
                                },
                              ),
                            ),
                          );
                        }),
                      const Divider(height: 24),

                      // Recipe / Inventory usage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recipe & Stock Tracking',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Deducts stock automatically upon sale',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Link Stock Item'),
                            onPressed: _addRecipeIngredient,
                          ),
                        ],
                      ),
                      if (_recipe.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No recipe ingredients linked yet. (Optional)',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        )
                      else
                        ..._recipe.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.inventory_2, size: 18),
                              title: Text(item.ingredientName,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Deducts: ${item.quantityRequired} ${item.unit} per order item'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.danger),
                                onPressed: () {
                                  setState(() => _recipe.removeAt(idx));
                                },
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderGrey)),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(widget.productToEdit == null
                        ? 'Create Product'
                        : 'Save Changes'),
                    onPressed: _saveProduct,
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
