import 'package:http/http.dart' as http;

class NaverStaticMap {
  final String _apiKeyId = 'tzoepfxqm2';
  final String _apiKey = 'KlH2BScuJJmSThleZ3l1sy1q80dmHaohe7ay9LHb';

  String getStaticMapUrl(double lat, double lng, int width, int height, int level) {
    return 'https://naveropenapi.apigw.ntruss.com/map-static/v2/raster?w=$width&h=$height&center=$lng,$lat&level=$level';
  }

  Future<String> fetchStaticMap(double lat, double lng, int width, int height, int level) async {
    final String url = getStaticMapUrl(lat, lng, width, height, level);
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'X-NCP-APIGW-API-KEY-ID': _apiKeyId,
        'X-NCP-APIGW-API-KEY': _apiKey,
      },
    );

    if (response.statusCode == 200) {
      return url;
    } else {
      throw Exception('Failed to load static map');
    }
  }
}
