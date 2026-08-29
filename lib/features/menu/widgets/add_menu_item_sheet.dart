import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/models/category.dart';
import 'package:khao_piyo_pos/shared/models/menu_item.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';
import 'package:khao_piyo_pos/features/menu/providers/menu_provider.dart';

class AddMenuItemSheet extends ConsumerStatefulWidget {
  final List<Category> categories;
  final MenuItem? itemToEdit;
  final String? defaultCategoryId;

  const AddMenuItemSheet({
    super.key,
    required this.categories,
    this.itemToEdit,
    this.defaultCategoryId,
  });

  @override
  ConsumerState<AddMenuItemSheet> createState() => _AddMenuItemSheetState();
}

class _AddMenuItemSheetState extends ConsumerState<AddMenuItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  String? _selectedCategoryId;
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemToEdit?.name ?? '');
    _priceController = TextEditingController(text: widget.itemToEdit?.price.toString() ?? '');
    _selectedCategoryId = widget.itemToEdit?.categoryId ?? widget.defaultCategoryId;
    _isAvailable = widget.itemToEdit?.isAvailable ?? true;

    if (_selectedCategoryId == null && widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final businessId = ref.read(currentBusinessIdProvider);
      
      if (businessId == null) return;

      if (widget.itemToEdit != null) {
        // Edit existing
        final updated = widget.itemToEdit!.copyWith(
          name: name,
          price: price,
          categoryId: _selectedCategoryId,
          isAvailable: _isAvailable,
          updatedAt: DateTime.now(),
        );
        ref.read(menuProvider.notifier).updateMenuItem(updated);
      } else {
        // Add new
        final newItem = MenuItem(
          id: const Uuid().v4(),
          businessId: businessId,
          categoryId: _selectedCategoryId!,
          name: name,
          price: price,
          isAvailable: _isAvailable,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ref.read(menuProvider.notifier).addMenuItem(newItem);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('Please create a category first.'),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.itemToEdit != null ? 'Edit Menu Item' : 'Add Menu Item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                autofocus: true,
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (₹)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter a price';
                  if (double.tryParse(value) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (val) {
                  setState(() {
                    _isAvailable = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save Item'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
