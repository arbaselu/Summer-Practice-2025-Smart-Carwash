import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  late final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanează QR')),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) {
            controller.stop(); // oprește camera
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
