import 'package:flutter/material.dart';
import 'naver_directions.dart';
import 'naver_geocode.dart';
import 'naver_static_map.dart';

class DirectionsPage extends StatefulWidget {
  const DirectionsPage({super.key});

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
            decoration: const InputDecoration(labelText: 'Start Address'),
          ),
          TextField(
            controller: _goalAddressController,
            decoration: const InputDecoration(labelText: 'Goal Address'),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _findDirections,
            child: const Text('Find Directions'),
          ),
          const SizedBox(height: 16.0),
          _directions != null
              ? Expanded(
            child: ListView.builder(
              itemCount: (_directions!['route']['trafast'] as List).length,
              itemBuilder: (context, index) {
                final step = _directions!['route']['trafast'][index];
                final guides = step['guide'] as List<dynamic>;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: guides.length,
                  itemBuilder: (context, guideIndex) {
                    final guide = guides[guideIndex];
                    return ListTile(
                      title: Text(guide['instructions']),
                      subtitle: Text('${guide['distance']} meters'),
                    );
                  },
                );
              },
            ),
          )
              : const Text('No directions found.'),
          _staticMapUrl != null
              ? Image.network(_staticMapUrl!)
              : const Text('No map available.'),
        ],
      ),
    );
  }
}
