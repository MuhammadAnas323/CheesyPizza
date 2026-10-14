import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/category_model.dart';
import '../../../core/theme/app_colors.dart';

class CategoryFormDialog extends StatefulWidget {
  final CategoryModel? categoryToEdit;

  const CategoryFormDialog({super.key, this.categoryToEdit});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _orderController;
  String _selectedIcon = 'local_pizza';

  final List<Map<String, dynamic>> _iconOptions = [
    {'name': 'local_pizza', 'icon': Icons.local_pizza, 'label': 'Pizza'},
    {'name': 'lunch_dining', 'icon': Icons.lunch_dining, 'label': 'Burger'},
    {'name': 'local_offer', 'icon': Icons.local_offer, 'label': 'Deal'},
    {'name': 'fastfood', 'icon': Icons.fastfood, 'label': 'Fries'},
    {'name': 'local_drink', 'icon': Icons.local_drink, 'label': 'Drink'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Meal'},
    {'name': 'icecream', 'icon': Icons.icecream, 'label': 'Dessert'},
    {'name': 'bakery_dining', 'icon': Icons.bakery_dining, 'label': 'Bakery'},
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.categoryToEdit;
    _nameController = TextEditingController(text: c?.name ?? '');
    _orderController = TextEditingController(
        text: c != null ? c.displayOrder.toString() : '1');
    _selectedIcon = c?.iconName ?? 'local_pizza';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final order = int.tryParse(_orderController.text) ?? 1;
    final category = CategoryModel(
      id: widget.categoryToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      iconName: _selectedIcon,
      displayOrder: order,
    );

    Navigator.pop(context, category);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.category, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Text(widget.categoryToEdit == null ? 'Add Category' : 'Edit Category'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  hintText: 'e.g. Pizza, Burgers, Deals, Fries, Drinks',
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter category name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Display Order Position',
                  hintText: '1, 2, 3...',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Category Icon',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconOptions.map((opt) {
                  final isSelected = _selectedIcon == opt['name'];
                  return ChoiceChip(
                    avatar: Icon(opt['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.primaryRed),
                    label: Text(opt['label'] as String,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : AppColors.textDark)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryRed,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedIcon = opt['name'] as String);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
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
          child: const Text('Save Category'),
        ),
      ],
    );
  }
}
