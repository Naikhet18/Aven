import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khao_piyo_pos/core/printing/printer_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PrinterConfig round-trips through SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    const config = PrinterConfig(
      receiptType: PrinterConnectionType.bluetooth,
      receiptBluetoothMac: '00:11:22:33:44:55',
      receiptBluetoothName: 'Counter Printer',
      kotAutoPrint: true,
      kotType: PrinterConnectionType.network,
      kotNetworkHost: '192.168.1.50',
      kotNetworkPort: 9100,
    );

    await config.saveTo(prefs);
    final restored = PrinterConfig.fromPrefs(prefs);

    expect(restored.receiptType, PrinterConnectionType.bluetooth);
    expect(restored.receiptBluetoothMac, '00:11:22:33:44:55');
    expect(restored.kotAutoPrint, isTrue);
    expect(restored.kotType, PrinterConnectionType.network);
    expect(restored.kotNetworkHost, '192.168.1.50');
    expect(restored.hasSeparateKotPrinter, isTrue);
  });

  test('a fresh install defaults to no printer configured', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final config = PrinterConfig.fromPrefs(prefs);

    expect(config.receiptType, PrinterConnectionType.none);
    expect(config.hasSeparateKotPrinter, isFalse);
    expect(config.kotAutoPrint, isFalse);
  });
}
