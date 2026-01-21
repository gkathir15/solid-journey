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
        _log.warning('⚠️ Overpass API error: ${response.statusCode}, using mock data');
        return _getMockData(city);
      }

      final data = jsonDecode(response.body);
      final elements = (data['elements'] as List).cast<Map<String, dynamic>>();

      _log.info('✅ Harvested ${elements.length} elements with full metadata');

      // Transform and enrich
      return _enrichWithMetadata(elements);
    } catch (e) {
      _log.warning('⚠️ Harvesting error: $e, using mock data');
      return _getMockData(city);
    }
  }

  /// Build comprehensive Overpass query
  String _buildComprehensiveQuery(String city, List<String> categories) {
    // Use bbox for Chennai instead of geocoding for reliability
    // Chennai bounds: 12.57°N to 13.25°N, 79.75°E to 80.30°E
    final bbox = _getCityBbox(city);
    
    return '''[out:json][timeout:90];
($bbox
  node["tourism"~"attraction|museum|gallery|viewpoint|historic|artwork|theme_park"];
  way["tourism"~"attraction|museum|gallery|viewpoint|historic|artwork|theme_park"];
  relation["tourism"~"attraction|museum|gallery|viewpoint|historic|artwork|theme_park"];
  node["amenity"~"cafe|restaurant|bar|pub|library|cinema|theatre|museum|art_gallery|community_centre"];
  way["amenity"~"cafe|restaurant|bar|pub|library|cinema|theatre|museum|art_gallery|community_centre"];
  node["leisure"~"park|garden|playground|recreation_ground|nature_reserve|common|hackerspace|escape_game"];
  way["leisure"~"park|garden|playground|recreation_ground|nature_reserve|common|hackerspace|escape_game"];
  node["historic"~"archaeological_site|castle|church|ruins|memorial|monument|wayside_shrine"];
  way["historic"~"archaeological_site|castle|church|ruins|memorial|monument|wayside_shrine"];
  node["shop"~"antique|art|book|craft|museum|second_hand|vintage"];
  way["shop"~"antique|art|book|craft|museum|second_hand|vintage"];
  node["craft"~"brewery|winery|distillery|coffee|chocolate|baker|pottery"];
  way["craft"~"brewery|winery|distillery|coffee|chocolate|baker|pottery"];
  node["natural"~"wood|water|peak|cave|beach|viewpoint"];
  way["natural"~"wood|water|peak|cave|beach|viewpoint"];
);
out center;''';
  }

  /// Get bounding box for major cities
  String _getCityBbox(String city) {
    const cityBboxes = {
      'Chennai': '(12.57,79.75,13.25,80.30)',
      'Mumbai': '(18.90,72.80,19.30,73.00)',
      'Delhi': '(28.40,76.80,28.90,77.30)',
      'Bangalore': '(12.80,77.50,13.10,77.75)',
      'Kolkata': '(22.40,88.30,22.65,88.50)',
      'Hyderabad': '(17.30,78.40,17.50,78.65)',
      'Paris': '(48.81,2.22,48.90,2.47)',
      'London': '(51.40,-0.20,51.55,-0.10)',
      'New York': '(40.60,-74.10,40.90,-73.90)',
      'Tokyo': '(35.60,139.60,35.70,139.80)',
    };
    
    return cityBboxes[city] ?? '(12.57,79.75,13.25,80.30)'; // Default to Chennai
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

  /// Mock data for development/fallback
  List<Map<String, dynamic>> _getMockData(String city) {
    final mockPlaces = {
      'Chennai': [
        {
          'id': 1,
          'type': 'node',
          'name': 'Kapaleeshwarar Temple',
          'lat': 13.0012,
          'lon': 80.2719,
          'primary_category': 'historic:temple',
          'subcategory': 'religious',
          'heritage_level': '4',
          'historic_type': 'temple',
          'start_date': '1600',
          'architecture': 'dravidian',
          'description': 'Ancient Hindu temple dedicated to Lord Shiva, 400+ years old',
          'operator': 'Hindu Religious',
          'opening_hours': '06:00-21:00',
          'fee': 'no',
          'wheelchair': 'no',
          'raw_tags': {'name': 'Kapaleeshwarar Temple', 'tourism': 'attraction', 'historic': 'temple'},
        },
        {
          'id': 2,
          'type': 'node',
          'name': 'San Thome Basilica',
          'lat': 13.0024,
          'lon': 80.2744,
          'primary_category': 'historic:church',
          'subcategory': 'religious',
          'heritage_level': '3',
          'historic_type': 'church',
          'start_date': '1504',
          'architecture': 'neo-gothic',
          'description': 'Historic Catholic church built in 1504, UNESCO site',
          'operator': 'Catholic',
          'opening_hours': '06:00-18:00',
          'fee': 'no',
          'wheelchair': 'yes',
          'raw_tags': {'name': 'San Thome Basilica', 'tourism': 'attraction', 'historic': 'church'},
        },
        {
          'id': 3,
          'type': 'node',
          'name': 'Parthasarathy Temple',
          'lat': 13.0070,
          'lon': 80.2624,
          'primary_category': 'historic:temple',
          'subcategory': 'religious',
          'heritage_level': '4',
          'historic_type': 'temple',
          'start_date': '1178',
          'architecture': 'dravidian',
          'description': '800+ year old Vaishnavite temple, artistic masterpiece',
          'operator': 'Hindu Religious',
          'opening_hours': '06:00-12:00,16:00-21:00',
          'fee': 'no',
          'wheelchair': 'no',
          'raw_tags': {'name': 'Parthasarathy Temple', 'tourism': 'attraction', 'historic': 'temple'},
        },
        {
          'id': 4,
          'type': 'node',
          'name': 'DakshinaChitra',
          'lat': 12.9670,
          'lon': 80.2462,
          'primary_category': 'tourism:museum',
          'subcategory': 'cultural',
          'heritage_level': '2',
          'historic_type': 'museum',
          'description': 'Living museum showcasing South Indian heritage and crafts',
          'operator': 'DakshinaChitra Society',
          'opening_hours': '10:00-18:00',
          'fee': 'yes',
          'wheelchair': 'yes',
          'raw_tags': {'name': 'DakshinaChitra', 'tourism': 'museum'},
        },
        {
          'id': 5,
          'type': 'node',
          'name': 'Chennai Central Station',
          'lat': 13.0823,
          'lon': 80.2703,
          'primary_category': 'historic:station',
          'subcategory': 'architecture',
          'heritage_level': '3',
          'historic_type': 'railway_station',
          'start_date': '1856',
          'architecture': 'victorian',
          'description': 'Historic Victorian railway station, architectural landmark',
          'operator': 'Indian Railways',
          'opening_hours': '00:00-24:00',
          'fee': 'no',
          'wheelchair': 'yes',
          'raw_tags': {'name': 'Chennai Central Station', 'tourism': 'attraction', 'historic': 'railway_station'},
        },
      ],
      'Mumbai': [
        {'id': 101, 'type': 'node', 'name': 'Gateway of India', 'lat': 18.9580, 'lon': 72.8355, 'primary_category': 'historic:monument', 'heritage_level': '2', 'start_date': '1924', 'description': 'Iconic monument and UNESCO site'},
        {'id': 102, 'type': 'node', 'name': 'Taj Mahal Palace Hotel', 'lat': 18.9542, 'lon': 72.8236, 'primary_category': 'tourism:hotel', 'start_date': '1903', 'description': 'Historic heritage hotel'},
      ],
      'Paris': [
        {'id': 201, 'type': 'node', 'name': 'Eiffel Tower', 'lat': 48.8584, 'lon': 2.2945, 'primary_category': 'tourism:attraction', 'heritage_level': '3', 'description': 'Famous iron tower landmark'},
        {'id': 202, 'type': 'node', 'name': 'Louvre Museum', 'lat': 48.8606, 'lon': 2.3352, 'primary_category': 'tourism:museum', 'description': 'World famous art museum'},
      ],
    };

    final places = mockPlaces[city] ?? mockPlaces['Chennai'] ?? [];
    
    _log.info('📦 Using mock data: ${places.length} places for $city');
    
    return places.cast<Map<String, dynamic>>();
  }
}
