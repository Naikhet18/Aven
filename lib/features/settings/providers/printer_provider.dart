import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/core/printing/printer_service.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';

final printerServiceProvider = Provider<PrinterService>((ref) {
  final settings = ref.watch(settingsProvider);
  return PrinterService(settings);
});

// Since we are mocking Bluetooth scanning for now, we'll create a simple state provider
final isPrinterConnectedProvider = StateProvider<bool>((ref) => false);
