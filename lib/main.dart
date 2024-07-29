import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'naver_directions.dart';
import 'naver_geocode.dart';
import 'naver_static_map.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Helmet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    DirectionsPage(),
    LikesPage(),
    Center(child: Text("Search Page")), // Placeholder for Search page
    Center(child: Text("Profile Page")), // Placeholder for Profile page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Helmet')),
      body: _pages[_selectedIndex],
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xff6200ee),
        unselectedItemColor: const Color(0xff757575),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text("Home"),
            selectedColor: Colors.purple,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.favorite_border),
            title: const Text("Likes"),
            selectedColor: Colors.pink,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.search),
            title: const Text("Search"),
            selectedColor: Colors.orange,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person),
            title: const Text("Profile"),
            selectedColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}

class LikesPage extends StatefulWidget {
  @override
  _LikesPageState createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? alertCharacteristic;
  String alertMessage = '안전운전하세요';

  @override
  void initState() {
    super.initState();
    startBluetooth();
  }

  void startBluetooth() async {
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name == 'YourDeviceName') { // Replace with your device name
          flutterBlue.stopScan();
          connectToDevice(r.device);
          break;
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      service.characteristics.forEach((characteristic) {
        if (characteristic.uuid.toString() == 'your_characteristic_uuid') { // Replace with your characteristic UUID
          alertCharacteristic = characteristic;
          listenForAlerts();
        }
      });
    });
  }

  void listenForAlerts() {
    alertCharacteristic?.value.listen((value) {
      String receivedMessage = String.fromCharCodes(value);
      if (receivedMessage == '응급상황') {
        setState(() {
          alertMessage = '응급상황입니다!';
        });
      }
    });

    alertCharacteristic?.setNotifyValue(true);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        alertMessage,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
      ),
    );
  }
}

class DirectionsPage extends StatefulWidget {
  @override
  _DirectionsPageState createState() => _DirectionsPageState();
}

class _DirectionsPageState extends State<DirectionsPage> {
  final NaverDirections _naverDirections = NaverDirections();
  final NaverGeocode _naverGeocode = NaverGeocode();
  final NaverStaticMap _naverStaticMap = NaverStaticMap();
  Map<String, dynamic>? _directions;
  String? _staticMapUrl;

  final TextEditingController _startAddressController = TextEditingController();
  final TextEditingController _goalAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _goalAddressController.addListener(_updateMap);
  }

  @override
  void dispose() {
    _goalAddressController.removeListener(_updateMap);
    _goalAddressController.dispose();
    _startAddressController.dispose();
    super.dispose();
  }

  Future<void> _findDirections() async {
    try {
      final startCoords = await _naverGeocode.getCoordinates(_startAddressController.text);
      final goalCoords = await _naverGeocode.getCoordinates(_goalAddressController.text);

      final directions = await _naverDirections.getDirections(
        startCoords['lat']!,
        startCoords['lng']!,
        goalCoords['lat']!,
        goalCoords['lng']!,
      );

      setState(() {
        _directions = directions;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _directions = null;
      });
    }
  }

  Future<void> _updateMap() async {
    try {
      if (_goalAddressController.text.isEmpty) {
        setState(() {
          _staticMapUrl = null;
        });
        return;
      }

      final goalCoords = await _naverGeocode.getCoordinates(_goalAddressController.text);

      final staticMapUrl = await _naverStaticMap.fetchStaticMap(
        goalCoords['lat']!,
        goalCoords['lng']!,
        300,
        300,
        16,
      );

      setState(() {
        _staticMapUrl = staticMapUrl;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _staticMapUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _startAddressController,
            decoration: InputDecoration(labelText: 'Start Address'),
          ),
          TextField(
            controller: _goalAddressController,
            decoration: InputDecoration(labelText: 'Goal Address'),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _findDirections,
            child: Text('Find Directions'),
          ),
          SizedBox(height: 16.0),
          _directions != null
              ? Expanded(
            child: ListView.builder(
              itemCount: (_directions!['route']['trafast'] as List).length,
              itemBuilder: (context, index) {
                final step = _directions!['route']['trafast'][index];
                final guides = step['guide'] as List<dynamic>;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: guides.length,
                  itemBuilder: (context, guideIndex) {
                    final guide = guides[guideIndex];
                    return ListTile(
                      title: Text(guide['instructions']),
                    );
                  },
                );
              },
            ),
          )
              : Text('No directions available'),
          _staticMapUrl != null
              ? Image.network(_staticMapUrl!)
              : Container(),
        ],
      ),
    );
  }
}
