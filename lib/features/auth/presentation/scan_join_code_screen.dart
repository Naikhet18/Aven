import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans a restaurant join QR (encoded as `khaopiyo://join/<code>`, or just
/// the bare code) and pops with the extracted code string.
class ScanJoinCodeScreen extends StatefulWidget {
  const ScanJoinCodeScreen({super.key});

  @override
  State<ScanJoinCodeScreen> createState() => _ScanJoinCodeScreenState();
}

class _ScanJoinCodeScreenState extends State<ScanJoinCodeScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    _handled = true;
    final uri = Uri.tryParse(raw);
    final code = (uri != null && uri.scheme == 'khaopiyo' && uri.pathSegments.isNotEmpty) ? uri.pathSegments.last : raw;
    Navigator.of(context).pop(code.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Restaurant QR')),
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
        ],
      ),
    );
  }
}
