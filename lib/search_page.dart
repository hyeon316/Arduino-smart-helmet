import 'dart:async'; // 추가된 import
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'bluetooth_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<BluetoothDiscoveryResult> _devicesList = [];
  bool _isDiscovering = false;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetoothState();
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkBluetoothState() async {
    final BluetoothState state = await FlutterBluetoothSerial.instance.state;
    if (state == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
    if (MyBluetoothService.instance.isConnected) {
      setState(() {
        _connectedDevice = MyBluetoothService.instance.connectedDevice;
      });
    } else {
      _startDiscovery();
    }
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
      _devicesList = [];
    });

    _discoveryStreamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final existingIndex = _devicesList.indexWhere(
              (element) => element.device.address == r.device.address,
        );
        if (existingIndex >= 0) {
          _devicesList[existingIndex] = r;
        } else {
          _devicesList.add(r);
        }
      });
    });

    _discoveryStreamSubscription?.onDone(() {
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    await MyBluetoothService.instance.connectToDevice(device);
    setState(() {
      _connectedDevice = MyBluetoothService.instance.isConnected ? device : null;
    });

    if (_connectedDevice == null) {
      _startDiscovery();
    }
  }

  void _disconnectDevice() {
    MyBluetoothService.instance.disconnect();
    setState(() {
      _connectedDevice = null;
    });
    _startDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Bluetooth Devices'),
        actions: [
          if (_isDiscovering)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (_connectedDevice == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startDiscovery,
            ),
        ],
      ),
      body: _connectedDevice != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Connected to:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _connectedDevice!.name ?? "Unknown device",
              style: const TextStyle(fontSize: 16),
            ),
            Text(_connectedDevice!.address),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _disconnectDevice,
              child: const Text('Disconnect'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _devicesList.length,
        itemBuilder: (context, index) {
          BluetoothDiscoveryResult result = _devicesList[index];
          return ListTile(
            title: Text(result.device.name ?? "Unknown device"),
            subtitle: Text(result.device.address),
            trailing: ElevatedButton(
              onPressed: () => _connectToDevice(result.device),
              child: const Text('Connect'),
            ),
          );
        },
      ),
    );
  }
}
