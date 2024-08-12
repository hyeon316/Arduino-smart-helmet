import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class MyBluetoothService {
  static final MyBluetoothService instance = MyBluetoothService._internal();

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  final StreamController<List<int>> _alertStreamController = StreamController.broadcast();
  final StreamController<void> _disconnectionStreamController = StreamController.broadcast();

  bool get isConnected => _connection != null && _connection!.isConnected;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  Stream<List<int>>? get alertStream => _alertStreamController.stream;

  // 새로운 스트림을 추가하여 연결이 끊어질 때 이벤트를 발생시킴
  Stream<void> get disconnectionStream => _disconnectionStreamController.stream;

  MyBluetoothService._internal();

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      print('Connected to the device');

      _connection?.input?.listen((data) {
        if (!_alertStreamController.isClosed) {
          _alertStreamController.add(data);
        }
      }).onDone(() {
        print('Disconnected from device');
        _connection = null;
        _connectedDevice = null;

        // 연결이 끊어졌을 때 이벤트 발생
        _disconnectionStreamController.add(null);
      });

    } catch (error) {
      print('Failed to connect: $error');
      _connection = null;
      _connectedDevice = null;
    }
  }

  void disconnect() {
    _connection?.dispose();
    _connection = null;
    _connectedDevice = null;
    if (!_alertStreamController.isClosed) {
      _alertStreamController.close();
    }
  }
}
