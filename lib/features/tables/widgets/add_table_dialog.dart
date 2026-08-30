import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/features/tables/providers/tables_provider.dart';
import 'package:khao_piyo_pos/shared/models/restaurant_table.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class AddTableDialog extends ConsumerStatefulWidget {
  final RestaurantTable? tableToEdit;
  const AddTableDialog({super.key, this.tableToEdit});

  @override
  ConsumerState<AddTableDialog> createState() => _AddTableDialogState();
}

class _AddTableDialogState extends ConsumerState<AddTableDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tableToEdit?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final repo = ref.read(tableRepositoryProvider);

    if (widget.tableToEdit != null) {
      await repo.updateTable(widget.tableToEdit!.copyWith(name: name, updatedAt: DateTime.now()));
    } else {
      final businessId = ref.read(currentBusinessIdProvider);
      if (businessId == null) return;
      await repo.addTable(RestaurantTable(
        id: const Uuid().v4(),
        businessId: businessId,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    ref.invalidate(tablesProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tableToEdit != null ? 'Rename Table' : 'Add Table'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Table name or number', border: OutlineInputBorder()),
          autofocus: true,
          validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
