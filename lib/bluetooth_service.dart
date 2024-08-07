import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class MyBluetoothService {
  static final MyBluetoothService instance = MyBluetoothService._internal();

  BluetoothConnection? _connection;
  StreamController<List<int>> _alertStreamController = StreamController.broadcast();

  Stream<List<int>>? get alertStream => _alertStreamController.stream;

  MyBluetoothService._internal();

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to the device');
      _connection?.input?.listen((data) {
        _alertStreamController.add(data);
      }).onDone(() {
        print('Disconnected from device');
      });
    } catch (error) {
      print('Failed to connect: $error');
    }
  }

  void dispose() {
    _connection?.dispose();
    _alertStreamController.close();
  }
}
