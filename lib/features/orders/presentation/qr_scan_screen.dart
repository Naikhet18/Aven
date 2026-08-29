import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:khao_piyo_pos/features/orders/providers/cart_provider.dart';

/// Scans a table QR code (expected format: a bare table number/name, or a
/// `khaopiyo://table/<number>` deep link) and jumps straight into a new
/// dine-in order for that table.
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    _handled = true;
    final tableNumber = _extractTableNumber(raw);

    ref.read(cartProvider.notifier)
      ..setOrderType('DINE_IN')
      ..setTableNumber(tableNumber);

    Navigator.of(context).pop();
    context.go('/new-order');
  }

  String _extractTableNumber(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.scheme == 'khaopiyo' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Table QR')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'Point the camera at a table QR code',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
