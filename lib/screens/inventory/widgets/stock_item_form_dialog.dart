import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/inventory_model.dart';
import '../../../core/theme/app_colors.dart';

class StockItemFormDialog extends StatefulWidget {
  final InventoryItem? itemToEdit;

  const StockItemFormDialog({super.key, this.itemToEdit});

  @override
  State<StockItemFormDialog> createState() => _StockItemFormDialogState();
}

class _StockItemFormDialogState extends State<StockItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _stockController;
  late TextEditingController _minAlertController;
  late TextEditingController _costController;

  String _category = 'Dairy';
  String _unit = 'kg';

  final List<String> _categories = [
    'Dairy',
    'Meat',
    'Bakery',
    'Vegetables',
    'Beverages',
    'Condiments',
    'Pantry',
    'Packaging',
    'General',
  ];

  final List<String> _units = ['kg', 'g', 'pcs', 'liters', 'cans', 'bottles'];

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.name ?? '');
    _stockController = TextEditingController(
        text: item != null ? item.currentStock.toString() : '');
    _minAlertController = TextEditingController(
        text: item != null ? item.minStockAlert.toString() : '5.0');
    _costController = TextEditingController(
        text: item != null ? item.costPerUnit.toString() : '');
    if (item != null) {
      _category = item.category;
      _unit = item.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _minAlertController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final currentStock = double.tryParse(_stockController.text) ?? 0.0;
    final minAlert = double.tryParse(_minAlertController.text) ?? 5.0;
    final costPerUnit = double.tryParse(_costController.text) ?? 0.0;

    final item = InventoryItem(
      id: widget.itemToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      category: _category,
      currentStock: currentStock,
      minStockAlert: minAlert,
      unit: _unit,
      costPerUnit: costPerUnit,
      lastUpdated: DateTime.now(),
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.inventory_2, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Text(widget.itemToEdit == null
              ? 'Add Stock Item'
              : 'Edit Stock Item'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g. Mozzarella Cheese, Flour, Burger Buns',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Please enter item name'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: _units.map((u) {
                          return DropdownMenuItem(value: u, child: Text(u));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _unit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Current Stock ($_unit) *',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter quantity';
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
                        controller: _minAlertController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Low Stock Alert ($_unit)',
                        ),
                        validator: (val) =>
                            double.tryParse(val ?? '') == null
                                ? 'Invalid number'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cost Price per $_unit (PKR) *',
                    prefixText: 'Rs. ',
                    hintText: 'e.g. 1400',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter cost';
                    if (double.tryParse(val) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save Stock Item'),
        ),
      ],
    );
  }
}
