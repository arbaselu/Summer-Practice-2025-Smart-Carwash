import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'qr_scanner.dart';
import 'bluetooth_manager.dart';

class BluetoothTab extends StatefulWidget {
  const BluetoothTab({super.key});

  @override
  State<BluetoothTab> createState() => _BluetoothTabState();
}

class _BluetoothTabState extends State<BluetoothTab> {
  final bluetooth = BluetoothManager();

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.camera,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  void scanQRCodeAndConnect() async {
    final granted = await requestPermissions();

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisiuni refuzate')),
      );
      return;
    }

    final deviceId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );

    if (deviceId != null && deviceId is String) {
      final success = await bluetooth.connect(deviceId);

      if (success) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Conectat la $deviceId')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Conectarea a eșuat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = bluetooth.isConnected ? Colors.green : Colors.red;
    final statusText = bluetooth.isConnected ? 'ON' : 'OFF';

    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, size: 64, color: color),
            const SizedBox(height: 8),
            Text(
              'Stare conexiune: $statusText',
              style: TextStyle(fontSize: 20, color: color),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code),
              label: const Text('Scanează cod QR și conectează-te'),
              onPressed: scanQRCodeAndConnect,
            ),
            const SizedBox(height: 16),
            if (bluetooth.isConnected)
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_disabled),
                label: const Text('Deconectează-te'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () {
                  bluetooth.disconnect();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(' Deconectat de la boxă')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

}


