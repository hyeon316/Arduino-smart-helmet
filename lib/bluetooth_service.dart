import 'package:flutter_blue/flutter_blue.dart';

class MyBluetoothService {
  MyBluetoothService._privateConstructor();
  static final MyBluetoothService instance = MyBluetoothService._privateConstructor();

  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  Stream<List<int>>? alertStream;

  void startScan() {
    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name == 'HC-06') {
          flutterBlue.stopScan();
          connectToDevice(result.device);
          break;
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          this.characteristic = characteristic;
          alertStream = this.characteristic?.value;
          this.characteristic?.setNotifyValue(true);
        }
      }
    }
  }

  void disconnect() {
    connectedDevice?.disconnect();
  }
}
