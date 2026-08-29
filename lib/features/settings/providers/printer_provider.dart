import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:khao_piyo_pos/core/printing/printer_config.dart';
import 'package:khao_piyo_pos/core/printing/printer_service.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class PrinterConfigNotifier extends Notifier<PrinterConfig> {
  @override
  PrinterConfig build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return PrinterConfig.fromPrefs(prefs);
  }

  Future<void> update(PrinterConfig config) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await config.saveTo(prefs);
    state = config;
  }
}

final printerConfigProvider = NotifierProvider<PrinterConfigNotifier, PrinterConfig>(() {
  return PrinterConfigNotifier();
});

final printerServiceProvider = Provider<PrinterService>((ref) {
  final settings = ref.watch(settingsProvider);
  final config = ref.watch(printerConfigProvider);
  return PrinterService(settings, config);
});

/// Paired Bluetooth devices available to connect a printer to. Requires the
/// Bluetooth permission to already be granted (see `requestBluetoothPermission`).
final pairedBluetoothDevicesProvider = FutureProvider.autoDispose<List<BluetoothInfo>>((ref) async {
  final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
  if (!granted) return [];
  return PrintBluetoothThermal.pairedBluetooths;
});

final bluetoothConnectionStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  return PrintBluetoothThermal.connectionStatus;
});
