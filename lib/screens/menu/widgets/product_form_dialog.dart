import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/category_provider.dart';

class ProductFormDialog extends ConsumerStatefulWidget {
  final String? categoryId;
  final ProductModel? productToEdit;

  const ProductFormDialog({
    super.key,
    this.categoryId,
    this.productToEdit,
  });

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  String? _selectedCatId;

  List<ProductSize> _sizes = [];

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _selectedCatId = p?.categoryId ?? widget.categoryId;

    if (p != null) {
      if (p.hasSizes && p.sizes.isNotEmpty) {
        _sizes = List.from(p.sizes);
      } else if (p.basePrice > 0) {
        _sizes = [ProductSize(name: '', price: p.basePrice, costPrice: 0)];
      }
    }
    if (_sizes.isEmpty) {
      _sizes = [ProductSize(name: '', price: 0, costPrice: 0)];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addSizeRow() {
    setState(() {
      _sizes.add(ProductSize(name: '', price: 0, costPrice: 0));
    });
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;
    
    // Ensure selected category ID is valid
    final categories = ref.read(categoryNotifierProvider).asData?.value ?? [];
    if (_selectedCatId == null || _selectedCatId!.isEmpty) {
      if (categories.isNotEmpty) {
        _selectedCatId = categories.first.id;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create a category first')),
        );
        return;
      }
    }

    if (_sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one size and price')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final basePrice = _sizes.first.price;

    final product = ProductModel(
      id: widget.productToEdit?.id ?? const Uuid().v4(),
      name: name,
      categoryId: _selectedCatId!,
      description: description,
      basePrice: basePrice,
      baseCostPrice: 0.0,
      isAvailable: true,
      hasSizes: true,
      sizes: _sizes,
      availableToppings: [],
      recipe: [],
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
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
                    widget.productToEdit == null ? 'Add New Item' : 'Edit Item',
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

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Dropdown
                      categoriesAsync.when(
                        data: (categories) {
                          if (categories.isEmpty) {
                            return const Text('No categories available. Please add a category first.',
                                style: TextStyle(color: AppColors.danger));
                          }
                          if (_selectedCatId == null ||
                              _selectedCatId!.isEmpty ||
                              !categories.any((c) => c.id == _selectedCatId)) {
                            _selectedCatId = widget.categoryId ?? categories.first.id;
                          }
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedCatId,
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
                              if (val != null) setState(() => _selectedCatId = val);
                            },
                            validator: (val) => val == null || val.isEmpty ? 'Select category' : null,
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox(),
                      ),
                      const SizedBox(height: 14),

                      // Item Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'e.g. Chicken Tikka Pizza, Zinger Burger',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter item name'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Description
                      TextFormField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'e.g. Spicy chicken tikka, onions, capsicum, cheese',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Sizes & Prices Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sizes & Prices (PKR) *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Size'),
                            onPressed: _addSizeRow,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ..._sizes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final size = entry.value;

                        return Card(
                          key: ValueKey('size_row_$index'),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    initialValue: size.name,
                                    decoration: const InputDecoration(
                                      labelText: 'Size Name',
                                      hintText: 'e.g. Small / Medium / Large',
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      _sizes[index] = ProductSize(
                                        name: val,
                                        price: _sizes[index].price,
                                        costPrice: 0,
                                      );
                                    },
                                    validator: (val) => val == null || val.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    initialValue: size.price > 0 ? size.price.toStringAsFixed(0) : '',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Price (PKR)',
                                      hintText: '0',
                                      prefixText: 'Rs. ',
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      final price = double.tryParse(val) ?? 0.0;
                                      _sizes[index] = ProductSize(
                                        name: _sizes[index].name,
                                        price: price,
                                        costPrice: 0,
                                      );
                                    },
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(val) == null || double.parse(val) <= 0) {
                                        return 'Invalid price';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (_sizes.length > 1) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                    onPressed: () {
                                      setState(() {
                                        _sizes.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderGrey)),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
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
                    label: Text(widget.productToEdit == null ? 'Save Item' : 'Update Item'),
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
