# Phase 5 GenUI Implementation Reference Guide
**Timestamp:** 2026-01-21T18:16:14.666Z

---

## Quick Start: Copy-Paste Code Snippets

### 1. OSM Service (Data Layer)

**File: `lib/services/osm/osm_service.dart`**

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlaceData {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> tags;
  
  PlaceData({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.tags,
  });
}

class OSMService {
  static const String overpassEndpoint = 'https://overpass-api.de/api/interpreter';
  
  /// Fetch attractions with comprehensive tag harvesting
  Future<List<PlaceData>> fetchAttractions({
    required String city,
    required List<String> categories,
    bool includeSecondaryMetadata = true,
  }) async {
    try {
      final query = _buildOverpassQuery(city, categories);
      
      // Log input
      print('[OSM] Fetching attractions for $city with categories: $categories');
      print('[OSM] Query: $query');
      
      final response = await http.post(
        Uri.parse(overpassEndpoint),
        body: query,
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        throw Exception('Overpass API error: ${response.statusCode}');
      }
      
      final places = _parseOverpassResponse(response.body);
      
      // Log output
      print('[OSM] Fetched ${places.length} places');
      for (var p in places.take(3)) {
        print('[OSM]   - ${p.name}: ${p.tags}');
      }
      
      return places;
    } catch (e) {
      print('[OSM_ERROR] $e');
      rethrow;
    }
  }
  
  /// Calculate distance matrix (meters) using Haversine formula
  Future<Map<String, Map<String, double>>> calculateDistanceMatrix(
    List<PlaceData> places,
  ) async {
    final matrix = <String, Map<String, double>>{};
    
    print('[OSM] Calculating distance matrix for ${places.length} places');
    
    for (int i = 0; i < places.length; i++) {
      matrix[places[i].id] = {};
      for (int j = 0; j < places.length; j++) {
        if (i != j) {
          final distance = _haversineDistance(
            places[i].latitude,
            places[i].longitude,
            places[j].latitude,
            places[j].longitude,
          );
          matrix[places[i].id]![places[j].id] = distance;
        }
      }
    }
    
    print('[OSM] Distance matrix complete');
    return matrix;
  }
  
  String _buildOverpassQuery(String city, List<String> categories) {
    final tagFilters = _buildTagFilters(categories);
    
    return '''
[out:json][timeout:30];
area["name"="$city"]->.searchArea;
(
  $tagFilters
);
out center;
    '''.trim();
  }
  
  String _buildTagFilters(List<String> categories) {
    final filters = <String>[];
    
    for (var cat in categories) {
      filters.add('nwr["tourism"~"$cat"](area.searchArea);');
      filters.add('nwr["amenity"~"$cat"](area.searchArea);');
      filters.add('nwr["leisure"~"$cat"](area.searchArea);');
    }
    
    return filters.join('\n  ');
  }
  
  List<PlaceData> _parseOverpassResponse(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final elements = (json['elements'] as List<dynamic>?) ?? [];
    
    return elements
      .whereType<Map<String, dynamic>>()
      .where((e) => e['tags'] != null && (e['tags'] as Map).isNotEmpty)
      .map((e) => PlaceData(
        id: '${e['id']}',
        name: (e['tags']['name'] as String?) ?? 'Unknown',
        latitude: (e['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (e['lon'] as num?)?.toDouble() ?? 0.0,
        tags: Map<String, dynamic>.from(e['tags'] as Map),
      ))
      .toList();
  }
  
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadian(lat2 - lat1);
    final dLon = _toRadian(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadian(lat1)) * cos(_toRadian(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }
  
  double _toRadian(double degree) => degree * pi / 180;
}
```

---

### 2. Discovery Processor (Semantic Layer)

**File: `lib/services/discovery/discovery_processor.dart`**

```dart
class VibeSignature {
  final String placeId;
  final String name;
  final String signature;  // Minified: "v:nature,quiet;h:18thC;l:local"
  final Map<String, dynamic> fullTags;
  final double latitude;
  final double longitude;
  
  VibeSignature({
    required this.placeId,
    required this.name,
    required this.signature,
    required this.fullTags,
    required this.latitude,
    required this.longitude,
  });
  
  @override
  String toString() => '$name: $signature';
}

class DiscoveryProcessor {
  /// Transform raw OSM place into vibe signature
  VibeSignature processPlace(PlaceData place) {
    print('[DISCOVERY] Processing: ${place.name}');
    
    final tags = place.tags;
    
    // Extract vibe dimensions
    final vibes = <String>[];
    final metadata = <String, String>{};
    
    // 1. Heritage & History
    if (tags.containsKey('historic') || tags.containsKey('heritage')) {
      vibes.add('history');
      final century = _extractCentury(tags['historic'] as String?);
      if (century != null) metadata['h'] = century;
    }
    
    // 2. Natural/Serene
    if (tags.containsKey('natural') || tags.containsKey('leisure')) {
      final leisure = tags['leisure'] as String? ?? '';
      if (leisure.contains('park') || leisure.contains('garden')) {
        vibes.add('nature');
        vibes.add('serene');
      }
    }
    
    // 3. Social/Activity
    if (tags.containsKey('amenity')) {
      final amenity = tags['amenity'] as String? ?? '';
      if (amenity.contains('cafe') || amenity.contains('bar') || amenity.contains('pub')) {
        vibes.add('social');
      }
      if (amenity.contains('library') || amenity.contains('museum')) {
        vibes.add('quiet');
        vibes.add('culture');
      }
    }
    
    // 4. Localness
    final brand = tags['brand'] as String?;
    final operator = tags['operator'] as String?;
    final isLocal = (brand == null || brand.isEmpty) && 
                    (operator == null || !operator.contains('chain'));
    if (isLocal) metadata['l'] = 'local';
    
    // 5. Additional metadata
    if (tags.containsKey('cuisine')) {
      metadata['c'] = (tags['cuisine'] as String?)?? 'specialty').substring(0, 2);
    }
    if (tags.containsKey('fee')) {
      metadata['f'] = tags['fee'] == 'no' ? 'free' : 'paid';
    }
    if (tags.containsKey('wheelchair')) {
      metadata['w'] = tags['wheelchair'] == 'yes' ? 'yes' : 'limited';
    }
    
    // Remove duplicates
    vibes.removeWhere((e) => e.isEmpty);
    final uniqueVibes = vibes.toSet().toList();
    
    // Build minified signature
    final signature = _minify(uniqueVibes, metadata);
    
    print('[DISCOVERY] Signature: $signature');
    
    return VibeSignature(
      placeId: place.id,
      name: place.name,
      signature: signature,
      fullTags: tags,
      latitude: place.latitude,
      longitude: place.longitude,
    );
  }
  
  String _minify(List<String> vibes, Map<String, String> metadata) {
    final parts = <String>[];
    
    if (vibes.isNotEmpty) {
      parts.add('v:${vibes.join(',')}');
    }
    
    metadata.forEach((key, value) {
      parts.add('$key:$value');
    });
    
    return parts.join(';');
  }
  
  String? _extractCentury(String? historic) {
    if (historic == null) return null;
    
    if (historic.contains('baroque')) return '17-18thC';
    if (historic.contains('gothic')) return 'medieval';
    if (historic.contains('roman')) return 'roman';
    if (historic.contains('medieval')) return 'medieval';
    
    return 'historic';
  }
  
  /// Analyze how well a place matches user vibes
  double scoreMatch(VibeSignature place, String userVibe) {
    double score = 0.0;
    final userParts = userVibe.toLowerCase().split(',');
    
    for (var part in userParts) {
      if (place.signature.toLowerCase().contains(part)) {
        score += 1.0;
      }
    }
    
    return score / userParts.length.toDouble();
  }
}
```

---

### 3. Spatial Clusterer (Grouping Logic)

**File: `lib/services/spatial/spatial_clusterer.dart`**

```dart
class DayCluster {
  final int dayNumber;
  final List<VibeSignature> places;
  final String theme;
  final double totalDistance;
  
  DayCluster({
    required this.dayNumber,
    required this.places,
    required this.theme,
    required this.totalDistance,
  });
  
  @override
  String toString() => 'Day $dayNumber ($theme): ${places.map((p) => p.name).join(", ")}';
}

class SpatialClusterer {
  static const double clusterRadiusKm = 1.0;
  
  /// Cluster places into day-long routes
  List<DayCluster> clusterForItinerary({
    required List<VibeSignature> places,
    required Map<String, Map<String, double>> distanceMatrix,
    required int tripDuration,
  }) {
    print('[CLUSTER] Creating $tripDuration-day clusters for ${places.length} places');
    
    // 1. Identify anchor points (most central or most connected)
    final anchors = _findAnchors(places, distanceMatrix);
    print('[CLUSTER] Anchors: ${anchors.map((a) => a.name).toList()}');
    
    // 2. Group around anchors
    final clusters = <List<VibeSignature>>[];
    final assigned = <String>{};
    
    for (var anchor in anchors) {
      final cluster = <VibeSignature>[anchor];
      assigned.add(anchor.placeId);
      
      // Find all places within 1km of anchor
      final nearby = places
        .where((p) => 
          !assigned.contains(p.placeId) &&
          (distanceMatrix[anchor.placeId]?[p.placeId] ?? double.infinity) < clusterRadiusKm
        )
        .toList();
      
      cluster.addAll(nearby);
      nearby.forEach((p) => assigned.add(p.placeId));
      
      clusters.add(cluster);
    }
    
    // 3. Add remaining unassigned places to nearest cluster
    for (var place in places) {
      if (!assigned.contains(place.placeId)) {
        final nearest = _findNearestCluster(place, clusters, distanceMatrix);
        clusters[nearest].add(place);
        assigned.add(place.placeId);
      }
    }
    
    // 4. Sort clusters by distance (for optimal routing)
    for (var cluster in clusters) {
      cluster.sort((a, b) {
        final distA = distanceMatrix[cluster[0].placeId]?[a.placeId] ?? 0.0;
        final distB = distanceMatrix[cluster[0].placeId]?[b.placeId] ?? 0.0;
        return distA.compareTo(distB);
      });
    }
    
    // 5. Distribute across days
    final dayClusters = <DayCluster>[];
    for (int i = 0; i < clusters.length && i < tripDuration; i++) {
      final totalDist = _calculateClusterDistance(clusters[i], distanceMatrix);
      final theme = _generateTheme(clusters[i]);
      
      dayClusters.add(DayCluster(
        dayNumber: i + 1,
        places: clusters[i],
        theme: theme,
        totalDistance: totalDist,
      ));
    }
    
    for (var dc in dayClusters) {
      print('[CLUSTER] $dc');
    }
    
    return dayClusters;
  }
  
  List<VibeSignature> _findAnchors(
    List<VibeSignature> places,
    Map<String, Map<String, double>> distanceMatrix,
  ) {
    if (places.isEmpty) return [];
    
    // Anchor = most central place (min sum of distances)
    final scores = <String, double>{};
    
    for (var place in places) {
      final distances = distanceMatrix[place.placeId] ?? {};
      final sumDist = distances.values.fold<double>(0, (a, b) => a + b);
      scores[place.placeId] = sumDist;
    }
    
    // Pick top 3 as anchors, or fewer if not enough places
    final anchorsCount = min(3, max(1, (places.length / 3).ceil()));
    final anchorsIds = scores.entries
      .sorted((a, b) => a.value.compareTo(b.value))
      .take(anchorsCount)
      .map((e) => e.key)
      .toList();
    
    return places.where((p) => anchorsIds.contains(p.placeId)).toList();
  }
  
  int _findNearestCluster(
    VibeSignature place,
    List<List<VibeSignature>> clusters,
    Map<String, Map<String, double>> distanceMatrix,
  ) {
    int nearestIdx = 0;
    double minDist = double.infinity;
    
    for (int i = 0; i < clusters.length; i++) {
      for (var clusterPlace in clusters[i]) {
        final dist = distanceMatrix[place.placeId]?[clusterPlace.placeId] ?? double.infinity;
        if (dist < minDist) {
          minDist = dist;
          nearestIdx = i;
        }
      }
    }
    
    return nearestIdx;
  }
  
  double _calculateClusterDistance(
    List<VibeSignature> cluster,
    Map<String, Map<String, double>> distanceMatrix,
  ) {
    double total = 0;
    for (int i = 0; i < cluster.length - 1; i++) {
      final dist = distanceMatrix[cluster[i].placeId]?[cluster[i + 1].placeId] ?? 0;
      total += dist;
    }
    return total;
  }
  
  String _generateTheme(List<VibeSignature> cluster) {
    // Analyze combined vibes for theme
    final allSigs = cluster.map((p) => p.signature).join(';');
    
    if (allSigs.contains('history')) return 'Historical Heritage';
    if (allSigs.contains('nature')) return 'Nature & Serenity';
    if (allSigs.contains('social')) return 'Social & Community';
    if (allSigs.contains('culture')) return 'Culture & Arts';
    
    return 'Exploration';
  }
}
```

---

### 4. Local LLM Service (AI Reasoning Layer)

**File: `lib/services/ai/local_llm_service.dart`**

```dart
import 'package:google_generative_ai/google_generative_ai.dart';

class LocalLLMService {
  late final GenerativeModel _model;
  final _logger = print;  // Or use logger package
  
  LocalLLMService() {
    // Initialize with LOCAL Gemini Nano model
    // No API key needed for on-device inference
    _model = GenerativeModel(
      model: 'gemini-nano',
      apiKey: '',  // Empty for local inference
    );
  }
  
  /// Plan trip based on user input, discovered places, and clusters
  Future<String> planTrip({
    required String userInput,
    required List<VibeSignature> discoveredPlaces,
    required List<DayCluster> clusters,
  }) async {
    _logger('[LLM_INPUT] User: $userInput');
    _logger('[LLM_INPUT] Places: ${discoveredPlaces.length}');
    _logger('[LLM_INPUT] Clusters: ${clusters.length}');
    
    final context = _buildContext(discoveredPlaces, clusters);
    
    final systemPrompt = '''
You are a Spatial Planner AI for personalized travel experiences.

ROLE:
- Analyze user preferences and spatial data
- Recommend logical day clusters based on proximity
- Justify recommendations using rich metadata

AVAILABLE PLACES (with Vibe Signatures):
$context

INSTRUCTIONS:
1. Read user request and identify their vibe preferences
2. Match them to places using vibe signatures
3. Group geographically close places (< 1km) for same-day visits
4. Create a 3-4 day itinerary with themes
5. Output ONLY valid A2UI JSON enclosed in \`\`\`a2ui ... \`\`\` blocks

VIBE SIGNATURE FORMAT: "v:vibe1,vibe2;l:local;h:1800s;f:free"
- v = vibes (history, nature, social, culture, quiet)
- l = localness (local or chain)
- h = heritage century
- f = fee (free or paid)

WIDGET CATALOG (use only these):
1. SmartMapSurface: Show places on map
   {
     "type": "SmartMapSurface",
     "payload": {
       "places": [{"name": "...", "lat": 0.0, "lng": 0.0, "vibeFilter": "..."}],
       "centerLat": 0.0,
       "centerLng": 0.0,
       "zoom": 15
     }
   }

2. RouteItinerary: Show day-by-day plan
   {
     "type": "RouteItinerary",
     "payload": {
       "days": [
         {"dayNumber": 1, "theme": "...", "places": ["place1", "place2"], "totalDistance": 2.5}
       ]
     }
   }

3. PlaceDiscoveryCard: Show individual place
   {
     "type": "PlaceDiscoveryCard",
     "payload": {
       "name": "...",
       "vibeSignature": "v:history,quiet;l:local",
       "coordinate": {"lat": 0.0, "lng": 0.0},
       "description": "..."
     }
   }
    ''';
    
    try {
      final response = await _model.generateContent([
        Content.text(systemPrompt),
        Content.text(userInput),
      ]);
      
      final output = response.text ?? '';
      _logger('[LLM_OUTPUT] Length: ${output.length}');
      _logger('[LLM_OUTPUT] Content: ${output.substring(0, min(200, output.length))}...');
      
      return output;
    } catch (e) {
      _logger('[LLM_ERROR] $e');
      rethrow;
    }
  }
  
  String _buildContext(List<VibeSignature> places, List<DayCluster> clusters) {
    final placesSection = places
      .take(15)  // Limit to top 15 to save tokens
      .map((p) => '- ${p.name}: ${p.signature}')
      .join('\n');
    
    final clustersSection = clusters
      .map((c) => 'Day ${c.dayNumber} (${c.theme}): ${c.places.map((p) => p.name).join(", ")}')
      .join('\n');
    
    return '''
DISCOVERED PLACES:
$placesSection

SUGGESTED CLUSTERS:
$clustersSection
    ''';
  }
  
  /// Handle user interaction with widget
  Future<String> handleUserInteraction({
    required String widgetId,
    required dynamic data,
  }) async {
    _logger('[LLM_INTERACTION] Widget: $widgetId, Data: $data');
    
    // Re-plan based on interaction
    // (Implementation depends on interaction type)
    
    return 'Updated response';
  }
}
```

---

### 5. A2UI Message Processor

**File: `lib/genui/a2ui_processor.dart`**

```dart
class A2uiMessage {
  final String type;
  final Map<String, dynamic> payload;
  
  A2uiMessage({required this.type, required this.payload});
}

class A2uiMessageProcessor {
  /// Parse A2UI JSON from LLM response
  List<A2uiMessage> parseMessages(String llmResponse) {
    print('[A2UI] Parsing response of ${llmResponse.length} chars');
    
    final messages = <A2uiMessage>[];
    
    // Extract ```a2ui ... ``` blocks
    final regex = RegExp(r'```a2ui\s*([\s\S]*?)\s*```');
    final matches = regex.allMatches(llmResponse);
    
    for (var match in matches) {
      final jsonStr = match.group(1)!.trim();
      
      try {
        final json = jsonDecode(jsonStr);
        
        if (json is List) {
          for (var item in json) {
            if (item is Map<String, dynamic>) {
              messages.add(A2uiMessage(
                type: item['type'] as String,
                payload: item['payload'] as Map<String, dynamic>,
              ));
            }
          }
        }
        
        print('[A2UI] Parsed ${messages.length} messages');
      } catch (e) {
        print('[A2UI_ERROR] Failed to parse: $e');
      }
    }
    
    return messages;
  }
}
```

---

### 6. GenUI Widget Implementations

**File: `lib/genui/widgets/place_card.dart`**

```dart
class PlaceDiscoveryCard extends StatelessWidget {
  final String name;
  final String vibeSignature;
  final double latitude;
  final double longitude;
  final String? description;
  final VoidCallback? onAddToTrip;
  
  const PlaceDiscoveryCard({
    required this.name,
    required this.vibeSignature,
    required this.latitude,
    required this.longitude,
    this.description,
    this.onAddToTrip,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  vibeSignature,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                if (description != null) ...[
                  SizedBox(height: 12),
                  Text(description!),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: onAddToTrip,
              icon: Icon(Icons.add),
              label: Text('Add to Trip'),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Integration Checklist

- [ ] Add dependencies to pubspec.yaml
- [ ] Create all service files
- [ ] Implement GenUI widgets
- [ ] Set up A2UI parsing
- [ ] Add logging at each layer
- [ ] Test with iOS simulator
- [ ] Test with Android device
- [ ] Verify token efficiency
- [ ] Add offline map caching

---

## Environment Variables

```bash
# .env (or set in main.dart)
GEMINI_NANO_MODEL_PATH=assets/models/gemini-nano/
OVERPASS_ENDPOINT=https://overpass-api.de/api/interpreter
TILE_CACHE_DIR=.tile_cache
LOG_LEVEL=DEBUG
```

---

**Reference Document Version:** 1.0  
**Ready to Implement:** YES
