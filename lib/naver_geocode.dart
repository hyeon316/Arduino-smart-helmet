import 'dart:convert';
import 'package:http/http.dart' as http;

class NaverGeocode {
  final String _apiKeyId = 'tzoepfxqm2';
  final String _apiKey = 'KlH2BScuJJmSThleZ3l1sy1q80dmHaohe7ay9LHb';

  Future<Map<String, double>> getCoordinates(String address) async {
    final String url = 'https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=${Uri.encodeQueryComponent(address)}';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'X-NCP-APIGW-API-KEY-ID': _apiKeyId,
        'X-NCP-APIGW-API-KEY': _apiKey,
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = json.decode(decodedBody) as Map<String, dynamic>;
      final firstResult = data['addresses'][0];

      return {
        'lat': double.parse(firstResult['y']),
        'lng': double.parse(firstResult['x']),
      };
    } else {
      throw Exception('Failed to load coordinates');
    }
  }
}
