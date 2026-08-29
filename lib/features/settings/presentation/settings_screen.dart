import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khao_piyo_pos/core/printing/printer_config.dart';
import 'package:khao_piyo_pos/features/settings/providers/printer_provider.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/features/settings/widgets/activity_log_tab.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

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
  final _taxController = TextEditingController();
  final _currencyController = TextEditingController();
  final _tableCountController = TextEditingController();

  final _networkHostController = TextEditingController();
  final _networkPortController = TextEditingController(text: '9100');

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
      _taxController.text = settings.taxRatePercent.toString();
      _currencyController.text = settings.currencySymbol;
      _tableCountController.text = settings.tableCount.toString();

      final config = ref.read(printerConfigProvider);
      _networkHostController.text = config.receiptNetworkHost ?? '';
      _networkPortController.text = config.receiptNetworkPort.toString();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _footerController.dispose();
    _taxController.dispose();
    _currencyController.dispose();
    _tableCountController.dispose();
    _networkHostController.dispose();
    _networkPortController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final settings = BusinessSettings(
      name: _nameController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      gstNumber: _gstController.text,
      receiptFooter: _footerController.text,
      taxRatePercent: double.tryParse(_taxController.text) ?? 0,
      currencySymbol: _currencyController.text.trim().isEmpty ? '₹' : _currencyController.text.trim(),
      tableCount: int.tryParse(_tableCountController.text) ?? 12,
    );
    ref.read(settingsProvider.notifier).updateSettings(settings);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to use this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true) return;

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('business_id');
    ref.read(currentBusinessIdProvider.notifier).state = null;
    await Supabase.instance.client.auth.signOut();

    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
              onPressed: _logout,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Business', icon: Icon(Icons.store)),
              Tab(text: 'Printer', icon: Icon(Icons.print)),
              Tab(text: 'Activity', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBusinessTab(),
            _buildPrinterTab(),
            const ActivityLogTab(),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Tax rate (%)', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _currencyController,
                  decoration: const InputDecoration(labelText: 'Currency symbol', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tableCountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Number of dine-in tables', border: OutlineInputBorder()),
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
    final config = ref.watch(printerConfigProvider);
    final pairedDevicesAsync = ref.watch(pairedBluetoothDevicesProvider);
    final connectionStatusAsync = ref.watch(bluetoothConnectionStatusProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Receipt printer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<PrinterConnectionType>(
          segments: const [
            ButtonSegment(value: PrinterConnectionType.none, label: Text('None')),
            ButtonSegment(value: PrinterConnectionType.bluetooth, label: Text('Bluetooth')),
            ButtonSegment(value: PrinterConnectionType.network, label: Text('Network')),
          ],
          selected: {config.receiptType},
          onSelectionChanged: (set) {
            ref.read(printerConfigProvider.notifier).update(config.copyWith(receiptType: set.first));
          },
        ),
        const SizedBox(height: 16),
        if (config.receiptType == PrinterConnectionType.bluetooth) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  config.receiptBluetoothName ?? 'No printer selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              connectionStatusAsync.when(
                data: (connected) => Chip(
                  label: Text(connected ? 'Connected' : 'Not connected'),
                  backgroundColor: connected ? Colors.green.shade100 : Colors.grey.shade200,
                ),
                loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.location].request();
              ref.invalidate(pairedBluetoothDevicesProvider);
            },
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Scan for paired printers'),
          ),
          const SizedBox(height: 12),
          pairedDevicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err'),
            data: (devices) {
              if (devices.isEmpty) {
                return const Text('No paired Bluetooth devices found. Pair your printer in system Bluetooth settings first.');
              }
              return Column(
                children: devices.map((d) {
                  final selected = d.macAdress == config.receiptBluetoothMac;
                  return Card(
                    child: ListTile(
                      leading: Icon(selected ? Icons.print : Icons.print_outlined),
                      title: Text(d.name),
                      subtitle: Text(d.macAdress),
                      trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      onTap: () {
                        ref.read(printerConfigProvider.notifier).update(
                              config.copyWith(receiptBluetoothMac: d.macAdress, receiptBluetoothName: d.name),
                            );
                        ref.invalidate(bluetoothConnectionStatusProvider);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
        if (config.receiptType == PrinterConnectionType.network) ...[
          TextField(
            controller: _networkHostController,
            decoration: const InputDecoration(labelText: 'Printer IP address', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _networkPortController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Port (default 9100)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              ref.read(printerConfigProvider.notifier).update(config.copyWith(
                    receiptNetworkHost: _networkHostController.text.trim(),
                    receiptNetworkPort: int.tryParse(_networkPortController.text) ?? 9100,
                  ));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network printer saved.')));
            },
            child: const Text('Save network printer'),
          ),
        ],
        const Divider(height: 48),
        Text('Kitchen ticket printing', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-print kitchen ticket for new orders'),
          subtitle: const Text('Uses the receipt printer unless a separate kitchen printer is set up.'),
          value: config.kotAutoPrint,
          onChanged: (val) {
            ref.read(printerConfigProvider.notifier).update(config.copyWith(kotAutoPrint: val));
          },
        ),
      ],
    );
  }
}
