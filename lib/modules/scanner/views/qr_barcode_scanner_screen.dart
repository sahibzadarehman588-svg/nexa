import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';

class QRBarcodeScannerScreen extends StatefulWidget {
  const QRBarcodeScannerScreen({super.key});

  @override
  State<QRBarcodeScannerScreen> createState() => _QRBarcodeScannerScreenState();
}

class _QRBarcodeScannerScreenState extends State<QRBarcodeScannerScreen> {
  bool _isScanning = true;
  String? _scannedCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan QR/Barcode'),
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                if (!_isScanning) return;

                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  _onCodeDetected(barcode.rawValue!);
                }
              },
            ),
          ),
          if (_scannedCode != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: AppColors.surface,
              child: Column(
                children: [
                  Text(
                    'Scanned Code:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _scannedCode!,
                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirmScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rescan,
                          child: const Text('Rescan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _onCodeDetected(String code) {
    if (_isScanning) {
      setState(() {
        _scannedCode = code;
        _isScanning = false;
      });
    }
  }

  void _confirmScan() {
    if (_scannedCode != null) {
      Get.back(result: _scannedCode);
    }
  }

  void _rescan() {
    setState(() {
      _scannedCode = null;
      _isScanning = true;
    });
  }
}
