import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/category.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';
import 'package:khao_piyo_pos/features/menu/providers/menu_provider.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  final Category? categoryToEdit;

  const AddCategoryDialog({super.key, this.categoryToEdit});

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sortOrderController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _sortOrderController = TextEditingController(text: widget.categoryToEdit?.sortOrder.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final sortOrder = int.tryParse(_sortOrderController.text) ?? 0;
      final businessId = ref.read(currentBusinessIdProvider);
      
      if (businessId == null) return;

      if (widget.categoryToEdit != null) {
        // Edit existing
        final updated = widget.categoryToEdit!.copyWith(
          name: name,
          sortOrder: sortOrder,
          updatedAt: DateTime.now(),
        );
        ref.read(menuProvider.notifier).updateCategory(updated);
      } else {
        // Add new
        final newCategory = Category(
          id: const Uuid().v4(),
          businessId: businessId,
          name: name,
          sortOrder: sortOrder,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ref.read(menuProvider.notifier).addCategory(newCategory);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.categoryToEdit != null ? 'Edit Category' : 'Add Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              autofocus: true,
              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sortOrderController,
              decoration: const InputDecoration(labelText: 'Sort Order (0 = First)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
