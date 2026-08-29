import 'package:flutter/foundation.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/order_item.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class PrinterService {
  final BusinessSettings _settings;

  PrinterService(this._settings);

  Future<void> printCustomerReceipt(Order order, List<OrderItem> items) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Header
      bytes += generator.text(_settings.name,
          styles: const PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              bold: true));
      bytes += generator.text(_settings.address,
          styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Phone: ${_settings.phone}',
          styles: const PosStyles(align: PosAlign.center));
      
      if (_settings.gstNumber.isNotEmpty) {
        bytes += generator.text('GST: ${_settings.gstNumber}',
            styles: const PosStyles(align: PosAlign.center));
      }

      bytes += generator.emptyLines(1);
      bytes += generator.text('Order #${order.orderNumber}',
          styles: const PosStyles(bold: true));
      bytes += generator.text('Type: ${order.orderType}');
      bytes += generator.text('Date: ${DateTime.now().toString().substring(0, 16)}');
      bytes += generator.hr();

      // Items
      for (final item in items) {
        bytes += generator.row([
          PosColumn(text: '${item.quantity.toInt()}x ${item.itemNameSnapshot}', width: 8),
          PosColumn(
              text: item.total.toStringAsFixed(2),
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }

      bytes += generator.hr();
      
      // Totals
      bytes += generator.row([
        PosColumn(text: 'Subtotal', width: 8),
        PosColumn(
            text: order.subtotal.toStringAsFixed(2),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      bytes += generator.row([
        PosColumn(
            text: 'TOTAL',
            width: 8,
            styles: const PosStyles(bold: true, height: PosTextSize.size2)),
        PosColumn(
            text: order.total.toStringAsFixed(2),
            width: 4,
            styles: const PosStyles(
                bold: true,
                align: PosAlign.right,
                height: PosTextSize.size2)),
      ]);
      
      bytes += generator.emptyLines(1);
      bytes += generator.text(_settings.receiptFooter,
          styles: const PosStyles(align: PosAlign.center));
      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      // MOCK PRINT: Send raw bytes length to console instead of actual Bluetooth
      debugPrint('====================================');
      debugPrint('MOCK PRINT RECEIPT: ${bytes.length} bytes generated');
      debugPrint('Order: ${order.orderNumber}');
      debugPrint('====================================');

    } catch (e) {
      debugPrint('Error printing receipt: $e');
    }
  }
}
