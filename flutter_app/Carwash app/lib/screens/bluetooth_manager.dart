import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  BluetoothConnection? _connection;

  bool get isConnected => _connection != null && _connection!.isConnected;
  BluetoothConnection? get connection => _connection;

  Future<bool> connect(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      return true;
    } catch (e) {
      _connection = null;
      return false;
    }
  }

  void disconnect() {
    _connection?.dispose();
    _connection = null;
  }
}