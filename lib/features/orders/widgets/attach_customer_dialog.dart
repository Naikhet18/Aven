import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/features/orders/providers/cart_provider.dart';
import 'package:khao_piyo_pos/shared/models/customer.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class AttachCustomerDialog extends ConsumerStatefulWidget {
  const AttachCustomerDialog({super.key});

  @override
  ConsumerState<AttachCustomerDialog> createState() => _AttachCustomerDialogState();
}

class _AttachCustomerDialogState extends ConsumerState<AttachCustomerDialog> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  Customer? _found;
  bool _searched = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() => _isLoading = true);

    final businessId = ref.read(currentBusinessIdProvider);
    final repo = ref.read(customerRepositoryProvider);
    final result = businessId == null ? null : await repo.getCustomerByPhone(businessId, phone);

    setState(() {
      _found = result;
      _searched = true;
      _isLoading = false;
      if (result?.name != null) _nameController.text = result!.name!;
    });
  }

  Future<void> _attachExisting() async {
    if (_found == null) return;
    ref.read(cartProvider.notifier).attachCustomer(_found!);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _createAndAttach() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    setState(() => _isLoading = true);

    final customer = Customer(
      id: const Uuid().v4(),
      businessId: businessId,
      phone: _phoneController.text.trim(),
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ref.read(customerRepositoryProvider).addCustomer(customer);
    ref.read(cartProvider.notifier).attachCustomer(customer);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attach Customer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder()),
                  onChanged: (_) => setState(() => _searched = false),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isLoading ? null : _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _searched && _found != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                title: Text(_found!.name ?? 'Unnamed customer'),
                subtitle: Text('${_found!.totalOrders} orders • ${_found!.loyaltyPoints} pts'),
                trailing: FilledButton(onPressed: _attachExisting, child: const Text('Use')),
              ),
            ),
          if (!_isLoading && _searched && _found == null) ...[
            const Text('No customer found. Create a new one:'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name (optional)', border: OutlineInputBorder()),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        if (_searched && _found == null)
          FilledButton(onPressed: _isLoading ? null : _createAndAttach, child: const Text('Create & Attach')),
      ],
    );
  }
}
