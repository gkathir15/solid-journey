import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Universal Tag Harvester - Extracts complete OSM metadata
/// 
/// Harvests from multiple top-level keys:
/// - amenity, tourism, historic, leisure, heritage
/// - shop, craft, man_made, natural
/// 
/// Plus secondary metadata:
/// - cuisine, diet, operator, check_date, opening_hours
/// - fee, wheelchair, architecture, artist, start_date, description
class UniversalTagHarvester {
  final _log = Logger('TagHarvester');
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Comprehensive query for all relevant OSM tags
  Future<List<Map<String, dynamic>>> harvestAllTags({
    required String city,
    required List<String> primaryCategories,
  }) async {
    _log.info('🏷️ Universal Tag Harvester: Harvesting deep OSM metadata for $city');
    _log.info('Categories: $primaryCategories');

    try {
      final query = _buildComprehensiveQuery(city, primaryCategories);
      _log.fine('Building comprehensive Overpass query...');

      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        throw Exception('Overpass API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final elements = (data['elements'] as List).cast<Map<String, dynamic>>();

      _log.info('✅ Harvested ${elements.length} elements with full metadata');

      // Transform and enrich
      return _enrichWithMetadata(elements);
    } catch (e) {
      _log.severe('❌ Harvesting error: $e');
      rethrow;
    }
  }

  /// Build comprehensive Overpass query
  String _buildComprehensiveQuery(String city, List<String> categories) {
    final catFilter = categories.join('|');

    return '''[out:json][timeout:90];
{{geocodeArea:"$city"}}->.searchArea;
(
  nwr["tourism"~"$catFilter|attraction|museum|gallery|viewpoint"](area.searchArea);
  nwr["amenity"~"cafe|restaurant|bar|pub|library|cinema|theatre|museum"](area.searchArea);
  nwr["leisure"~"park|garden|playground|recreation_ground|nature_reserve|common|picnic_table|hackerspace|escape_game|bookshop"](area.searchArea);
  nwr["historic"~"archaeological_site|castle|church|ruins|memorial|monument|wayside_shrine|fortified_settlement"](area.searchArea);
  nwr["heritage"~"yes|4|3|2|1"](area.searchArea);
  nwr["shop"~"antique|art|book|craft|museum|second_hand|vintage"](area.searchArea);
  nwr["craft"~"brewery|winery|distillery|coffee|chocolate|baker|butcher"](area.searchArea);
  nwr["man_made"~"lighthouse|tower|windmill|bridge|monument|sculpture"](area.searchArea);
  nwr["natural"~"wood|water|peak|cave|beach|cliff|gorge"](area.searchArea);
  nwr["amenity"~"artisan_bakery|craft_brewery|food_court"](area.searchArea);
);
out center geom;''';
  }

  /// Enrich elements with full metadata extraction
  List<Map<String, dynamic>> _enrichWithMetadata(
    List<Map<String, dynamic>> elements,
  ) {
    return elements.map((element) {
      final tags = element['tags'] as Map<String, dynamic>? ?? {};
      
      return {
        'id': element['id'],
        'type': element['type'],
        'name': tags['name'] ?? 'Unknown',
        'lat': element['center']?['lat'] ?? element['lat'],
        'lon': element['center']?['lon'] ?? element['lon'],
        
        // Primary categories
        'primary_category': _extractPrimaryCategory(tags),
        'subcategory': _extractSubcategory(tags),
        
        // Heritage & History
        'heritage_level': tags['heritage'],
        'historic_type': tags['historic'],
        'start_date': tags['start_date'],
        'architecture': tags['architecture'],
        'artist': tags['artist'],
        'description': tags['description'] ?? tags['wikipedia'] ?? '',
        
        // Practical metadata
        'operator': tags['operator'],
        'website': tags['website'],
        'phone': tags['phone'],
        'email': tags['email'],
        'opening_hours': tags['opening_hours'],
        'fee': tags['fee'],
        
        // Dining specifics
        'cuisine': tags['cuisine'],
        'diet_vegan': tags['diet:vegan'],
        'diet_vegetarian': tags['diet:vegetarian'],
        'diet_gluten_free': tags['diet:gluten_free'],
        
        // Accessibility & Features
        'wheelchair': tags['wheelchair'],
        'smoking': tags['smoking'],
        'outdoor_seating': tags['outdoor_seating'],
        'delivery': tags['delivery'],
        'takeaway': tags['takeaway'],
        'dine_in': tags['dine_in'],
        
        // Verification
        'check_date': tags['check_date'],
        'survey_date': tags['survey:date'],
        
        // All tags for custom extraction
        'raw_tags': tags,
      };
    }).toList();
  }

  /// Extract primary category from tags
  String _extractPrimaryCategory(Map<String, dynamic> tags) {
    if (tags.containsKey('tourism')) return 'tourism:${tags['tourism']}';
    if (tags.containsKey('amenity')) return 'amenity:${tags['amenity']}';
    if (tags.containsKey('leisure')) return 'leisure:${tags['leisure']}';
    if (tags.containsKey('historic')) return 'historic:${tags['historic']}';
    if (tags.containsKey('heritage')) return 'heritage';
    if (tags.containsKey('shop')) return 'shop:${tags['shop']}';
    if (tags.containsKey('craft')) return 'craft:${tags['craft']}';
    if (tags.containsKey('natural')) return 'natural:${tags['natural']}';
    return 'unknown';
  }

  /// Extract subcategory for finer granularity
  String _extractSubcategory(Map<String, dynamic> tags) {
    if (tags['building'] != null) return tags['building'];
    if (tags['service'] != null) return tags['service'];
    if (tags['type'] != null) return tags['type'];
    return '';
  }
}
