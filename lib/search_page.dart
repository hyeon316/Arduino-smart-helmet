import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<BluetoothDiscoveryResult> _devicesList = [];
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
      _devicesList = [];
    });

    FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
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
    }).onDone(() {
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);
      print('Connected to the device');
    } catch (error) {
      print('Failed to connect: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Bluetooth Devices'),
        actions: [
          _isDiscovering
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _startDiscovery,
                ),
        ],
      ),
      body: ListView.builder(
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
