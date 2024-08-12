import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class MyBluetoothService {
  static final MyBluetoothService instance = MyBluetoothService._internal();

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;  // 연결된 기기를 저장하는 변수 추가
  final StreamController<List<int>> _alertStreamController = StreamController.broadcast();

  bool get isConnected => _connection != null && _connection!.isConnected;

  // 연결된 기기 정보를 반환하는 getter
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Stream<List<int>>? get alertStream => _alertStreamController.stream;

  MyBluetoothService._internal();

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;  // 연결된 기기 저장
      print('Connected to the device');

      _connection?.input?.listen((data) {
        if (!_alertStreamController.isClosed) {
          _alertStreamController.add(data);
        }
      }).onDone(() {
        print('Disconnected from device');
        _connection = null;
        _connectedDevice = null;  // 연결 해제 시 기기 정보 초기화
      });

    } catch (error) {
      print('Failed to connect: $error');
      _connection = null;
      _connectedDevice = null;  // 연결 실패 시 기기 정보 초기화
    }
  }

  void disconnect() {
    _connection?.dispose();
    _connection = null;
    _connectedDevice = null;  // 연결 해제 시 기기 정보 초기화
    if (!_alertStreamController.isClosed) {
      _alertStreamController.close();
    }
  }
}
