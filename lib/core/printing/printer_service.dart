import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:khao_piyo_pos/core/printing/printer_config.dart';
import 'package:khao_piyo_pos/core/utils/app_logger.dart';
import 'package:khao_piyo_pos/features/settings/providers/settings_provider.dart';
import 'package:khao_piyo_pos/shared/models/order.dart';
import 'package:khao_piyo_pos/shared/models/order_item.dart';

class PrintResult {
  final bool success;
  final String message;
  const PrintResult(this.success, this.message);
}

class PrinterService {
  final BusinessSettings _settings;
  final PrinterConfig _config;
  static const _log = AppLogger('printer');

  PrinterService(this._settings, this._config);

  Future<PrintResult> printCustomerReceipt(Order order, List<OrderItem> items) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    bytes.addAll(generator.text(_settings.name,
        styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true)));
    bytes.addAll(generator.text(_settings.address, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.text('Phone: ${_settings.phone}', styles: const PosStyles(align: PosAlign.center)));
    if (_settings.gstNumber.isNotEmpty) {
      bytes.addAll(generator.text('GST: ${_settings.gstNumber}', styles: const PosStyles(align: PosAlign.center)));
    }

    bytes.addAll(generator.emptyLines(1));
    bytes.addAll(generator.text('Order #${order.orderNumber}', styles: const PosStyles(bold: true)));
    bytes.addAll(generator.text('Type: ${order.orderType}${order.tableNumber != null ? ' - Table ${order.tableNumber}' : ''}'));
    bytes.addAll(generator.text('Date: ${(order.createdAt ?? DateTime.now()).toString().substring(0, 16)}'));
    bytes.addAll(generator.hr());

    for (final item in items) {
      bytes.addAll(generator.row([
        PosColumn(text: '${item.quantity.toInt()}x ${item.itemNameSnapshot}', width: 8),
        PosColumn(text: item.total.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.row([
      PosColumn(text: 'Subtotal', width: 8),
      PosColumn(text: order.subtotal.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]));
    if (order.discount > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: 'Discount', width: 8),
        PosColumn(text: '-${order.discount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }
    if (order.tax > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: 'Tax', width: 8),
        PosColumn(text: order.tax.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]));
    }
    bytes.addAll(generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(
          text: order.total.toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(bold: true, align: PosAlign.right, height: PosTextSize.size2)),
    ]));

    bytes.addAll(generator.emptyLines(1));
    bytes.addAll(generator.text(_settings.receiptFooter, styles: const PosStyles(align: PosAlign.center)));
    bytes.addAll(generator.emptyLines(2));
    bytes.addAll(generator.cut());

    return _send(bytes, type: _config.receiptType, mac: _config.receiptBluetoothMac, host: _config.receiptNetworkHost, port: _config.receiptNetworkPort);
  }

  Future<PrintResult> printKitchenTicket(Order order, List<OrderItem> items) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];

    bytes.addAll(generator.text('KITCHEN ORDER',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2)));
    bytes.addAll(generator.text('#${order.orderNumber}',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2)));
    bytes.addAll(generator.text(
      order.tableNumber != null && order.tableNumber!.isNotEmpty ? '${order.orderType} - Table ${order.tableNumber}' : order.orderType,
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.hr());

    for (final item in items) {
      bytes.addAll(generator.text('${item.quantity.toInt()}x ${item.itemNameSnapshot}',
          styles: const PosStyles(height: PosTextSize.size2, bold: true)));
      if (item.notes != null && item.notes!.isNotEmpty) {
        bytes.addAll(generator.text('   Note: ${item.notes}', styles: const PosStyles(bold: false)));
      }
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.text((order.createdAt ?? DateTime.now()).toString().substring(0, 16)));
    bytes.addAll(generator.emptyLines(2));
    bytes.addAll(generator.cut());

    final type = _config.hasSeparateKotPrinter ? _config.kotType : _config.receiptType;
    final mac = _config.hasSeparateKotPrinter ? _config.kotBluetoothMac : _config.receiptBluetoothMac;
    final host = _config.hasSeparateKotPrinter ? _config.kotNetworkHost : _config.receiptNetworkHost;
    final port = _config.hasSeparateKotPrinter ? _config.kotNetworkPort : _config.receiptNetworkPort;
    return _send(bytes, type: type, mac: mac, host: host, port: port);
  }

  Future<PrintResult> _send(
    List<int> bytes, {
    required PrinterConnectionType type,
    String? mac,
    String? host,
    int port = 9100,
  }) async {
    switch (type) {
      case PrinterConnectionType.none:
        _log.info('No printer configured; skipping ${bytes.length} bytes');
        return const PrintResult(false, 'No printer configured. Set one up in Settings > Printer.');

      case PrinterConnectionType.bluetooth:
        if (mac == null) return const PrintResult(false, 'No Bluetooth printer selected.');
        try {
          if (!await PrintBluetoothThermal.connectionStatus) {
            final connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
            if (!connected) return const PrintResult(false, 'Could not connect to the Bluetooth printer.');
          }
          final sent = await PrintBluetoothThermal.writeBytes(bytes);
          return sent ? const PrintResult(true, 'Printed') : const PrintResult(false, 'Printer did not accept the print job.');
        } catch (e, st) {
          _log.error('Bluetooth print failed', e, st);
          return PrintResult(false, 'Bluetooth print failed: $e');
        }

      case PrinterConnectionType.network:
        if (host == null || host.isEmpty) return const PrintResult(false, 'No network printer configured.');
        try {
          final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
          socket.add(bytes);
          await socket.flush();
          await socket.close();
          return const PrintResult(true, 'Printed');
        } catch (e, st) {
          _log.error('Network print failed', e, st);
          return PrintResult(false, 'Network print failed: $e');
        }
    }
  }
}
