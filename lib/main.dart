import 'package:flutter/material.dart';
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
      home: DirectionsPage(),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Helmet Directions'),
      ),
      body: Padding(
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
      ),
    );
  }
}
