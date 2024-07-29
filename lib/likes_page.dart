import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class LikesPage extends StatefulWidget {
  @override
  _LikesPageState createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? characteristic;
  String statusMessage = '안전운전하세요';

  @override
  void initState() {
    super.initState();
    startBluetooth();
  }

  void startBluetooth() async {
    // 스캔 시작
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    // 스캔 결과 처리
    flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (result.device.name == 'YourArduinoBluetoothName') {
          connectToDevice(result.device);
          flutterBlue.stopScan();
          break;
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    // 서비스 및 특성 검색
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic char in service.characteristics) {
        if (char.properties.notify) {
          characteristic = char;
          await characteristic!.setNotifyValue(true);
          characteristic!.value.listen((value) {
            processReceivedData(value);
          });
          break;
        }
      }
    }
  }

  void processReceivedData(List<int> data) {
    String receivedData = String.fromCharCodes(data);
    if (receivedData.contains('응급상황')) {
      setState(() {
        statusMessage = '응급상황입니다!';
      });
    } else {
      setState(() {
        statusMessage = '안전운전하세요';
      });
    }
  }

  @override
  void dispose() {
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Likes Page'),
      ),
      body: Center(
        child: Text(
          statusMessage,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
