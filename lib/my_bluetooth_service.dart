import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class MyBluetoothService {
  // Singleton 인스턴스
  static final MyBluetoothService instance = MyBluetoothService._internal();

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;

  // Bluetooth 연결 상태 확인
  bool get isConnected => _connection != null && _connection!.isConnected;

  // 연결된 장치 정보 반환
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // 스트림 컨트롤러로 외부에서 이벤트 구독 가능
  final StreamController<List<int>> _alertStreamController = StreamController.broadcast();
  final StreamController<void> _disconnectionStreamController = StreamController.broadcast();  // 추가

  Stream<List<int>> get alertStream => _alertStreamController.stream;
  Stream<void> get disconnectionStream => _disconnectionStreamController.stream;  // 추가

  MyBluetoothService._internal();

  // Bluetooth 기기 연결
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_connection != null && _connection!.isConnected) {
      return; // 이미 연결되어 있는 경우
    }
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      print('Connected to the device');

      // 데이터 수신 리스너
      _connection?.input?.listen((data) {
        _alertStreamController.add(data); // 데이터를 스트림으로 보냄
      }).onDone(() {
        print('Disconnected from device');
        _connection = null;
        _connectedDevice = null;
        _disconnectionStreamController.add(null);  // 연결이 끊어졌을 때 이벤트 발생
      });
    } catch (error) {
      print('Failed to connect: $error');
      _connection = null;
      _connectedDevice = null;
      rethrow; // 예외를 재발생시켜 호출자가 처리하도록 함
    }
  }

  // Bluetooth 연결 해제
  void disconnect() {
    _connection?.dispose();
    _connection = null;
    _connectedDevice = null;
  }

  // 리소스 정리
  void dispose() {
    _alertStreamController.close();
    _disconnectionStreamController.close();  // 추가
  }
}
