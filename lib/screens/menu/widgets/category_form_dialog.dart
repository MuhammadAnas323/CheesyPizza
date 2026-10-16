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

  @override
  void initState() {
    super.initState();
    final c = widget.categoryToEdit;
    _nameController = TextEditingController(text: c?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final category = CategoryModel(
      id: widget.categoryToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      iconName: widget.categoryToEdit?.iconName ?? 'local_pizza',
      displayOrder: widget.categoryToEdit?.displayOrder ?? 1,
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
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
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
          child: const Text('Save Category'),
        ),
      ],
    );
  }
}
