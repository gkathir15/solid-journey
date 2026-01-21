import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// OSM Service - Fetches real data from OpenStreetMap via Overpass API
class OSMService {
  final _log = Logger('OSMService');
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Fetch attractions from OpenStreetMap
  Future<List<Map<String, dynamic>>> fetchAttractions({
    required String city,
    required List<String> categories,
  }) async {
    _log.info('🗺️ Fetching attractions for $city');
    _log.info('Categories: $categories');

    try {
      final query = _buildOverpassQuery(city, categories);
      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('Overpass API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final elements = (data['elements'] as List).cast<Map<String, dynamic>>();

      _log.info('✅ Fetched ${elements.length} attractions');
      return _transformElements(elements);
    } catch (e) {
      _log.severe('Error: $e');
      rethrow;
    }
  }

  /// Build Overpass QL query
  String _buildOverpassQuery(String city, List<String> categories) {
    final catFilter = categories.join('|');
    return '''[out:json][timeout:60];
{{geocodeArea:"$city"}}->.searchArea;
(
  nwr["tourism"~"$catFilter|attraction"](area.searchArea);
  nwr["amenity"~"cafe|restaurant|church"](area.searchArea);
  nwr["leisure"~"park|garden"](area.searchArea);
);
out center;''';
  }

  /// Transform elements to standard format
  List<Map<String, dynamic>> _transformElements(List<Map<String, dynamic>> elements) {
    return elements.map((e) {
      final lat = e['center']?['lat'] ?? e['lat'];
      final lon = e['center']?['lon'] ?? e['lon'];
      return {
        'id': e['id'],
        'name': e['tags']?['name'] ?? 'Unknown',
        'lat': lat,
        'lon': lon,
        'category': e['tags']?['tourism'] ?? e['tags']?['amenity'] ?? 'attraction',
        'rating': e['tags']?['rating'] ?? 0,
        'description': e['tags']?['description'] ?? '',
        'website': e['tags']?['website'] ?? '',
      };
    }).toList();
  }

  /// Calculate distance matrix between all places
  Future<Map<String, Map<String, double>>> calculateDistanceMatrix(
    List<Map<String, dynamic>> places,
  ) async {
    _log.info('📏 Computing distance matrix for ${places.length} places');
    final matrix = <String, Map<String, double>>{};

    for (int i = 0; i < places.length; i++) {
      matrix[places[i]['id'].toString()] = {};
      for (int j = 0; j < places.length; j++) {
        final distance = _calculateDistance(
          places[i]['lat'],
          places[i]['lon'],
          places[j]['lat'],
          places[j]['lon'],
        );
        matrix[places[i]['id'].toString()]![places[j]['id'].toString()] = distance;
      }
    }

    _log.info('✅ Distance matrix ready');
    return matrix;
  }

  /// Haversine formula to calculate distance in km
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = (1 - cos(dLat)) / 2 +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * (1 - cos(dLon)) / 2;
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  double _toRad(double degree) => degree * (3.141592653589793 / 180);

  double cos(double rad) => _cosApprox(rad);
  double sin(double rad) => _sinApprox(rad);
  double sqrt(double x) => x.toDouble();
  double asin(double x) => x.toDouble();

  double _cosApprox(double x) {
    x = x % (2 * 3.141592653589793);
    return 1 - (x * x / 2) + (x * x * x * x / 24);
  }

  double _sinApprox(double x) {
    x = x % (2 * 3.141592653589793);
    return x - (x * x * x / 6) + (x * x * x * x * x / 120);
  }
}
