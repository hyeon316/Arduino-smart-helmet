import 'dart:convert';
import 'package:http/http.dart' as http;

class NaverDirections {
  final String _apiKeyId = 'tzoepfxqm2';
  final String _apiKey = 'KlH2BScuJJmSThleZ3l1sy1q80dmHaohe7ay9LHb';

  Future<Map<String, dynamic>> getDirections(double startLat, double startLng, double goalLat, double goalLng) async {
    final String url = 'https://naveropenapi.apigw.ntruss.com/map-direction/v1/driving?start=$startLng,$startLat&goal=$goalLng,$goalLat&option=trafast';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'X-NCP-APIGW-API-KEY-ID': _apiKeyId,
        'X-NCP-APIGW-API-KEY': _apiKey,
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      return json.decode(decodedBody) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load directions');
    }
  }
}
