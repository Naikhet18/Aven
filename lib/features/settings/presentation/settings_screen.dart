import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/printer_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();
  final _footerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _nameController.text = settings.name;
      _addressController.text = settings.address;
      _phoneController.text = settings.phone;
      _gstController.text = settings.gstNumber;
      _footerController.text = settings.receiptFooter;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final settings = BusinessSettings(
      name: _nameController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      gstNumber: _gstController.text,
      receiptFooter: _footerController.text,
    );
    ref.read(settingsProvider.notifier).updateSettings(settings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Business Details', icon: Icon(Icons.store)),
              Tab(text: 'Printer Setup', icon: Icon(Icons.print)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBusinessTab(),
            _buildPrinterTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _gstController,
            decoration: const InputDecoration(labelText: 'GST / Tax Number', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _footerController,
            decoration: const InputDecoration(labelText: 'Receipt Footer Message', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('SAVE SETTINGS'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterTab() {
    final isConnected = ref.watch(isPrinterConnectedProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bluetooth Thermal Printer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect to a 58mm or 80mm Bluetooth thermal printer. (MOCKED FOR PHASE 8)',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('Mock Printer MPT-II'),
              subtitle: Text(isConnected ? 'Connected' : 'Not Connected'),
              trailing: ElevatedButton(
                onPressed: () {
                  ref.read(isPrinterConnectedProvider.notifier).state = !isConnected;
                },
                child: Text(isConnected ? 'DISCONNECT' : 'CONNECT'),
              ),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: isConnected
                ? () {
                    // Just print a placeholder text to test connection
                    debugPrint('Test Print Requested');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mock Test Receipt Sent! Check console.')),
                    );
                  }
                : null,
            icon: const Icon(Icons.print),
            label: const Text('TEST PRINT'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }
}
