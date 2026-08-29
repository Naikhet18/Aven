import 'package:shared_preferences/shared_preferences.dart';

enum PrinterConnectionType { none, bluetooth, network }

/// Where to send receipts, and optionally a separate printer for kitchen
/// tickets (KDS stations commonly use a different printer than the counter).
class PrinterConfig {
  final PrinterConnectionType receiptType;
  final String? receiptBluetoothMac;
  final String? receiptBluetoothName;
  final String? receiptNetworkHost;
  final int receiptNetworkPort;

  final bool kotAutoPrint;
  final PrinterConnectionType kotType;
  final String? kotBluetoothMac;
  final String? kotBluetoothName;
  final String? kotNetworkHost;
  final int kotNetworkPort;

  const PrinterConfig({
    this.receiptType = PrinterConnectionType.none,
    this.receiptBluetoothMac,
    this.receiptBluetoothName,
    this.receiptNetworkHost,
    this.receiptNetworkPort = 9100,
    this.kotAutoPrint = false,
    this.kotType = PrinterConnectionType.none,
    this.kotBluetoothMac,
    this.kotBluetoothName,
    this.kotNetworkHost,
    this.kotNetworkPort = 9100,
  });

  /// Whether a distinct kitchen printer is configured; if not, KOT tickets
  /// fall back to the receipt printer.
  bool get hasSeparateKotPrinter => kotType != PrinterConnectionType.none;

  PrinterConfig copyWith({
    PrinterConnectionType? receiptType,
    String? receiptBluetoothMac,
    String? receiptBluetoothName,
    String? receiptNetworkHost,
    int? receiptNetworkPort,
    bool? kotAutoPrint,
    PrinterConnectionType? kotType,
    String? kotBluetoothMac,
    String? kotBluetoothName,
    String? kotNetworkHost,
    int? kotNetworkPort,
  }) {
    return PrinterConfig(
      receiptType: receiptType ?? this.receiptType,
      receiptBluetoothMac: receiptBluetoothMac ?? this.receiptBluetoothMac,
      receiptBluetoothName: receiptBluetoothName ?? this.receiptBluetoothName,
      receiptNetworkHost: receiptNetworkHost ?? this.receiptNetworkHost,
      receiptNetworkPort: receiptNetworkPort ?? this.receiptNetworkPort,
      kotAutoPrint: kotAutoPrint ?? this.kotAutoPrint,
      kotType: kotType ?? this.kotType,
      kotBluetoothMac: kotBluetoothMac ?? this.kotBluetoothMac,
      kotBluetoothName: kotBluetoothName ?? this.kotBluetoothName,
      kotNetworkHost: kotNetworkHost ?? this.kotNetworkHost,
      kotNetworkPort: kotNetworkPort ?? this.kotNetworkPort,
    );
  }

  static const _kReceiptType = 'printer_receipt_type';
  static const _kReceiptBtMac = 'printer_receipt_bt_mac';
  static const _kReceiptBtName = 'printer_receipt_bt_name';
  static const _kReceiptHost = 'printer_receipt_host';
  static const _kReceiptPort = 'printer_receipt_port';
  static const _kKotAutoPrint = 'printer_kot_auto';
  static const _kKotType = 'printer_kot_type';
  static const _kKotBtMac = 'printer_kot_bt_mac';
  static const _kKotBtName = 'printer_kot_bt_name';
  static const _kKotHost = 'printer_kot_host';
  static const _kKotPort = 'printer_kot_port';

  factory PrinterConfig.fromPrefs(SharedPreferences prefs) {
    return PrinterConfig(
      receiptType: _parseType(prefs.getString(_kReceiptType)),
      receiptBluetoothMac: prefs.getString(_kReceiptBtMac),
      receiptBluetoothName: prefs.getString(_kReceiptBtName),
      receiptNetworkHost: prefs.getString(_kReceiptHost),
      receiptNetworkPort: prefs.getInt(_kReceiptPort) ?? 9100,
      kotAutoPrint: prefs.getBool(_kKotAutoPrint) ?? false,
      kotType: _parseType(prefs.getString(_kKotType)),
      kotBluetoothMac: prefs.getString(_kKotBtMac),
      kotBluetoothName: prefs.getString(_kKotBtName),
      kotNetworkHost: prefs.getString(_kKotHost),
      kotNetworkPort: prefs.getInt(_kKotPort) ?? 9100,
    );
  }

  Future<void> saveTo(SharedPreferences prefs) async {
    await prefs.setString(_kReceiptType, receiptType.name);
    await _setOrRemove(prefs, _kReceiptBtMac, receiptBluetoothMac);
    await _setOrRemove(prefs, _kReceiptBtName, receiptBluetoothName);
    await _setOrRemove(prefs, _kReceiptHost, receiptNetworkHost);
    await prefs.setInt(_kReceiptPort, receiptNetworkPort);
    await prefs.setBool(_kKotAutoPrint, kotAutoPrint);
    await prefs.setString(_kKotType, kotType.name);
    await _setOrRemove(prefs, _kKotBtMac, kotBluetoothMac);
    await _setOrRemove(prefs, _kKotBtName, kotBluetoothName);
    await _setOrRemove(prefs, _kKotHost, kotNetworkHost);
    await prefs.setInt(_kKotPort, kotNetworkPort);
  }

  static Future<void> _setOrRemove(SharedPreferences prefs, String key, String? value) {
    return value == null ? prefs.remove(key) : prefs.setString(key, value);
  }

  static PrinterConnectionType _parseType(String? raw) {
    return PrinterConnectionType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => PrinterConnectionType.none,
    );
  }
}
