# PHASE 5: AI-First GenUI Travel Agent - Complete Implementation Guide

**Date**: 2026-01-21  
**Status**: Comprehensive Implementation Roadmap  
**Objective**: Build a Flutter app where local LLM manages planning, recommendation, and spatial grouping with real OSM data.

---

## PART 1: THE FOUNDATION (Environment Setup)

### Step 1.1: Dependency Setup
```yaml
# pubspec.yaml additions
dependencies:
  google_generative_ai: ^0.4.0
  flutter_genui: ^1.0.0
  flutter_map: ^6.0.0
  flutter_map_tile_caching: ^9.0.0
  google_mlkit_gen_ai: latest
  json_schema_builder: ^2.0.0
  dio: ^5.4.0
  uuid: ^4.0.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.8.0
```

### Step 1.2: Configure Google AI Edge SDK
- Install Google AI Edge SDK locally (no API keys required)
- Point `google_mlkit_gen_ai` to use **Gemini Nano** (E2B or E4B variant)
- Verify model runs on-device with `flutter run -v`

### Step 1.3: Verify Local Inference
```dart
// lib/services/llm_service.dart
import 'package:google_mlkit_gen_ai/google_mlkit_gen_ai.dart';

class LocalLLMService {
  late final GenerativeModel _model;

  Future<void> initialize() async {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // or gemini-nano locally
      apiKey: '', // Empty - local inference
    );
  }

  Future<String> generateResponse(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }
}
```

---

## PART 2: THE DATA ENGINE (OSM + Spatial Tools)

### Step 2.1: Universal Tag Harvester - OSM Service
```dart
// lib/services/osm_service.dart
class OverpassService {
  static const String OVERPASS_API = 'https://overpass-api.de/api/interpreter';

  /// Fetch attractions with rich metadata
  Future<List<PlaceData>> fetchAttractions({
    required String city,
    required List<String> categories,
  }) async {
    final query = _buildOverpassQuery(city, categories);
    // Query includes: amenity, tourism, historic, leisure, shop, craft, natural
    // Secondary metadata: cuisine, diet:*, operator, opening_hours, fee, wheelchair, architecture
    final response = await Dio().post(OVERPASS_API, data: query);
    return _parseResponse(response.data);
  }

  String _buildOverpassQuery(String city, List<String> categories) {
    // Overpass QL query structure:
    // [out:json][timeout:30];
    // {{geocodeArea:{{city}}}}->.searchArea;
    // ( nwr["tourism"~"museum|attraction"](area.searchArea);
    //   nwr["amenity"~"cafe|church"](area.searchArea);
    //   nwr["historic"~"..."] ... );
    // out center;
    
    return '''
      [out:json][timeout:30];
      {{geocodeArea:"$city"}}->.searchArea;
      (
        ${_buildCategoryFilters(categories)}
      );
      out center;
    ''';
  }

  String _buildCategoryFilters(List<String> categories) {
    // Dynamic filter building based on user categories
    // Maps user input to OSM tag queries
    return categories.map((cat) => 'nwr["${_mapCategoryToTag(cat)}"](area.searchArea);').join('\n');
  }

  List<PlaceData> _parseResponse(Map<String, dynamic> data) {
    // Extract all elements with rich metadata
    // Build PlaceData objects with coordinates, tags, and secondary metadata
  }
}

// Data model
class PlaceData {
  final String id;
  final String name;
  final double lat, lng;
  final Map<String, String> tags; // All OSM tags
  final String imageUrl;
  final double rating;
  final String vibeSignature; // Compact representation
}
```

### Step 2.2: Distance Matrix Calculator
```dart
// lib/services/spatial_service.dart
class SpatialService {
  /// Calculate distance matrix for all places
  Map<String, Map<String, double>> calculateDistanceMatrix(List<PlaceData> places) {
    final matrix = <String, Map<String, double>>{};
    
    for (int i = 0; i < places.length; i++) {
      matrix[places[i].id] = {};
      for (int j = 0; j < places.length; j++) {
        if (i != j) {
          matrix[places[i].id]![places[j].id] = 
            _haversineDistance(places[i], places[j]);
        }
      }
    }
    
    return matrix;
  }

  double _haversineDistance(PlaceData p1, PlaceData p2) {
    // Calculate distance in kilometers
    // Returns distance <= 1km for spatial clustering
  }

  /// Group places into day clusters (1km proximity)
  List<DayCluster> groupIntoClusters(
    List<PlaceData> places,
    Map<String, Map<String, double>> distanceMatrix,
  ) {
    // Algorithm: Greedy clustering or K-means
    // Places within 1km are grouped together
    // Anchor points (high-rated, famous) are cluster centers
    
    return [];
  }
}

class DayCluster {
  final int dayNumber;
  final List<PlaceData> places; // Sorted by rating/fame
  final PlaceData anchorPoint; // Primary attraction
  final double totalDistance; // Route distance
}
```

---

## PART 3: THE AGENTIC REASONING (LLM Decision Layer)

### Step 3.1: Setup Discovery Processor (Tag → Vibe Signature)
```dart
// lib/services/discovery_processor.dart
class DiscoveryProcessor {
  /// Transform raw OSM tags into compact "Vibe Signature"
  String generateVibeSignature(PlaceData place) {
    final signatures = <String>[];

    // Heritage Link
    if (place.tags.containsKey('historic') || place.tags.containsKey('heritage')) {
      signatures.add('historic:${place.tags['start_date'] ?? 'era'}');
    }

    // Localness Test
    if (!_isGlobalBrand(place.tags['operator'])) {
      signatures.add('local');
    }

    // Activity Profile
    if (place.tags.containsKey('leisure')) {
      signatures.add('social:${place.tags['leisure']}');
    }

    // Natural Anchor
    if (place.tags.containsKey('natural') || place.tags['tourism'] == 'viewpoint') {
      signatures.add('nature:serene');
    }

    // Cuisine (if food-related)
    if (place.tags.containsKey('cuisine')) {
      signatures.add('cuisine:${place.tags['cuisine']}');
    }

    // Architecture
    if (place.tags.containsKey('architecture')) {
      signatures.add('arch:${place.tags['architecture']}');
    }

    // Accessibility
    if (place.tags['wheelchair'] == 'yes') {
      signatures.add('accessible');
    }

    // Fee status
    if (place.tags['fee'] == 'no') {
      signatures.add('free');
    }

    // Return minified semicolon-delimited string
    return signatures.join(';');
  }

  bool _isGlobalBrand(String? operator) {
    final globalBrands = ['mcdonalds', 'starbucks', 'ikea', 'zara', 'h&m'];
    return operator != null && globalBrands.any((b) => operator.toLowerCase().contains(b));
  }
}

// Example output: "historic:1800s;local;social:biergarten;nature:serene;free"
```

### Step 3.2: Configure LLM as Decision Agent
```dart
// lib/services/agent_llm_service.dart
class AgentLLMService {
  final LocalLLMService _llm;
  final OverpassService _osmService;
  final DiscoveryProcessor _processor;

  /// System instruction for spatial planning
  String get systemInstruction => '''
You are a Spatial Travel Planner. Your role is to:
1. When a user selects a city and categories, call the OSMSlimmer tool to fetch attractions.
2. Analyze the returned 'Vibe Signatures' to understand place personalities.
3. Group places into logical "Day Clusters" (places within 1km are visited together).
4. Prioritize high-rated or famous spots as "Anchor Points" for each day.
5. Emit A2UI messages to render the SmartMapSurface and RouteItinerary.
6. Use ONLY the widgets in the provided catalog.

Your decisions must be justified: explain WHY you chose a place based on its metadata.

Example reasoning:
- If user likes "Quiet History", look for places with signatures: "historic:*;local;nature:serene"
- If user wants "Urban Edge", prioritize: "social:craft_beer;arch:modern;local"

Always consider:
- Distance matrix to optimize routes
- Vibe signatures to match user preferences
- Open hours and accessibility
- Weather and seasonal factors if provided
  ''';

  Future<String> planTrip({
    required String city,
    required List<String> categories,
    required String userVibe,
  }) async {
    // Step 1: Fetch attractions
    final places = await _osmService.fetchAttractions(
      city: city,
      categories: categories,
    );

    // Step 2: Generate vibe signatures
    final enrichedPlaces = places.map((p) {
      p.vibeSignature = _processor.generateVibeSignature(p);
      return p;
    }).toList();

    // Step 3: Create distance matrix
    final distanceMatrix = SpatialService().calculateDistanceMatrix(enrichedPlaces);

    // Step 4: Build prompt with structured data
    final prompt = _buildAgentPrompt(enrichedPlaces, distanceMatrix, userVibe);

    // Step 5: Call local LLM
    final response = await _llm.generateResponse(prompt);

    // Log input/output for transparency
    _logAgentExchange(prompt, response);

    return response;
  }

  String _buildAgentPrompt(
    List<PlaceData> places,
    Map<String, Map<String, double>> distanceMatrix,
    String userVibe,
  ) {
    final placesJson = places
        .map((p) => '''{
      "id": "${p.id}",
      "name": "${p.name}",
      "lat": ${p.lat},
      "lng": ${p.lng},
      "vibe": "${p.vibeSignature}",
      "rating": ${p.rating}
    }''')
        .join(',\n');

    return '''
$systemInstruction

USER PREFERENCE: $userVibe

AVAILABLE PLACES:
[$placesJson]

DISTANCE MATRIX (km):
${_formatDistanceMatrix(distanceMatrix)}

Task: Create a 3-day itinerary by grouping nearby places and arranging them logically.
Output: A2UI JSON message with SmartMapSurface and RouteItinerary components.
    ''';
  }

  String _formatDistanceMatrix(Map<String, Map<String, double>> matrix) {
    // Format for readability and token efficiency
    return '';
  }

  void _logAgentExchange(String input, String output) {
    // Transparency logging
    print('=== AGENT INPUT ===');
    print(input);
    print('\n=== AGENT OUTPUT ===');
    print(output);
  }
}
```

---

## PART 4: GenUI FLOW & WIDGET CATALOG

### Step 4.1: Define Component Catalog with JSON Schemas
```dart
// lib/genui/component_catalog.dart
class ComponentCatalog {
  static final catalog = {
    'PlaceDiscoveryCard': {
      'widget': PlaceDiscoveryCard,
      'schema': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'name': {'type': 'string'},
          'vibe': {'type': 'string'},
          'imageUrl': {'type': 'string'},
          'rating': {'type': 'number'},
        },
        'required': ['id', 'name', 'vibe'],
      },
    },
    'SmartMapSurface': {
      'widget': SmartMapSurface,
      'schema': {
        'type': 'object',
        'properties': {
          'places': {
            'type': 'array',
            'items': {'type': 'object'},
          },
          'center': {
            'type': 'object',
            'properties': {'lat': {'type': 'number'}, 'lng': {'type': 'number'}},
          },
          'vibeFilter': {'type': 'string'},
        },
        'required': ['places', 'center'],
      },
    },
    'RouteItinerary': {
      'widget': RouteItinerary,
      'schema': {
        'type': 'object',
        'properties': {
          'dayClusters': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'dayNumber': {'type': 'integer'},
                'places': {'type': 'array'},
                'totalDistance': {'type': 'number'},
              },
            },
          },
        },
        'required': ['dayClusters'],
      },
    },
  };
}
```

### Step 4.2: Implement GenUI Widgets
```dart
// lib/genui/widgets/place_discovery_card.dart
class PlaceDiscoveryCard extends StatefulWidget {
  final String id;
  final String name;
  final String vibe;
  final String imageUrl;
  final double rating;
  final Function(String)? onAddToTrip;

  const PlaceDiscoveryCard({
    required this.id,
    required this.name,
    required this.vibe,
    required this.imageUrl,
    required this.rating,
    this.onAddToTrip,
  });

  @override
  State<PlaceDiscoveryCard> createState() => _PlaceDiscoveryCardState();
}

class _PlaceDiscoveryCardState extends State<PlaceDiscoveryCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Image.network(widget.imageUrl),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 8),
                Text('Vibe: ${widget.vibe}', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('⭐ ${widget.rating}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => widget.onAddToTrip?.call(widget.id),
                  child: Text('Add to Trip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// lib/genui/widgets/smart_map_surface.dart
class SmartMapSurface extends StatefulWidget {
  final List<PlaceData> places;
  final LatLng center;
  final String? vibeFilter;

  const SmartMapSurface({
    required this.places,
    required this.center,
    this.vibeFilter,
  });

  @override
  State<SmartMapSurface> createState() => _SmartMapSurfaceState();
}

class _SmartMapSurfaceState extends State<SmartMapSurface> {
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.travel_filter_app',
        ),
        MarkerLayer(
          markers: widget.places
              .map((p) => Marker(
                    point: LatLng(p.lat, p.lng),
                    child: GestureDetector(
                      onTap: () => _showPlaceDetails(p),
                      child: Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  void _showPlaceDetails(PlaceData place) {
    // Show place details in bottom sheet
  }
}

// lib/genui/widgets/route_itinerary.dart
class RouteItinerary extends StatelessWidget {
  final List<DayCluster> dayClusters;

  const RouteItinerary({required this.dayClusters});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: dayClusters.length,
      itemBuilder: (context, index) {
        final day = dayClusters[index];
        return Card(
          child: ExpansionTile(
            title: Text('Day ${day.dayNumber}'),
            subtitle: Text('${day.places.length} places • ${day.totalDistance.toStringAsFixed(2)} km'),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: day.places.length,
                itemBuilder: (context, idx) {
                  final place = day.places[idx];
                  return ListTile(
                    title: Text(place.name),
                    subtitle: Text(place.vibeSignature),
                    trailing: Text('⭐${place.rating}'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Step 4.3: GenUI Orchestration Layer
```dart
// lib/genui/genui_orchestrator.dart
class GenUiOrchestrator {
  final A2uiMessageProcessor _messageProcessor;
  final ComponentCatalog _catalog = ComponentCatalog();

  Future<List<Widget>> processLLMOutput(String llmOutput) async {
    // Parse A2UI JSON from LLM
    final jsonData = jsonDecode(llmOutput);
    final widgets = <Widget>[];

    // Example structure:
    // {
    //   "components": [
    //     {"type": "SmartMapSurface", "data": {...}},
    //     {"type": "RouteItinerary", "data": {...}}
    //   ]
    // }

    for (final component in jsonData['components'] ?? []) {
      final widget = _buildWidget(component);
      if (widget != null) widgets.add(widget);
    }

    return widgets;
  }

  Widget? _buildWidget(Map<String, dynamic> component) {
    final type = component['type'] as String?;
    final data = component['data'] as Map<String, dynamic>?;

    if (type == null || data == null) return null;

    switch (type) {
      case 'PlaceDiscoveryCard':
        return PlaceDiscoveryCard(
          id: data['id'],
          name: data['name'],
          vibe: data['vibe'],
          imageUrl: data['imageUrl'] ?? '',
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
        );
      case 'SmartMapSurface':
        // Build from data
        return SmartMapSurface(
          places: [], // Parse from data
          center: LatLng(0, 0), // Parse from data
        );
      case 'RouteItinerary':
        // Build from data
        return RouteItinerary(dayClusters: []);
      default:
        return null;
    }
  }
}
```

---

## PART 5: STEP-BY-STEP IMPLEMENTATION FLOW

### Step 5.1: Initialize AI & Verify Local Inference
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local LLM
  final llmService = LocalLLMService();
  await llmService.initialize();
  
  // Verify it's running locally
  final testResponse = await llmService.generateResponse('Say hello');
  debugPrint('LLM Ready: $testResponse');
  
  runApp(MyApp());
}
```

### Step 5.2: On-Boarding Flow
```dart
// lib/screens/onboarding_screen.dart
class OnboardingScreen extends StatefulWidget {
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _agentLlm = AgentLLMService(...);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenUiSurface(
        child: FutureBuilder<String>(
          future: _agentLlm.generateTripDurationPicker(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final widgets = GenUiOrchestrator().processLLMOutput(snapshot.data!);
              return Column(children: widgets);
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
```

### Step 5.3: Location Selection
```dart
// lib/screens/location_selection_screen.dart
class LocationSelectionScreen extends StatefulWidget {
  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenUiSurface(
        child: Column(
          children: [
            Text('Select Country', style: Theme.of(context).textTheme.headlineSmall),
            // CountryGrid generated by AI
            SizedBox(height: 24),
            Text('Select City', style: Theme.of(context).textTheme.headlineSmall),
            // CityHeroCard generated by AI
          ],
        ),
      ),
    );
  }
}
```

### Step 5.4: Trip Planning (Main Logic)
```dart
// lib/screens/trip_planning_screen.dart
class TripPlanningScreen extends StatefulWidget {
  final String city;
  final List<String> categories;

  const TripPlanningScreen({required this.city, required this.categories});

  @override
  State<TripPlanningScreen> createState() => _TripPlanningScreenState();
}

class _TripPlanningScreenState extends State<TripPlanningScreen> {
  final _agentLlm = AgentLLMService(...);
  final _orchestrator = GenUiOrchestrator();

  @override
  void initState() {
    super.initState();
    _planTrip();
  }

  Future<void> _planTrip() async {
    try {
      // Call agent LLM
      final agentOutput = await _agentLlm.planTrip(
        city: widget.city,
        categories: widget.categories,
        userVibe: 'Quiet History', // From user selection
      );

      // Process A2UI output
      final widgets = await _orchestrator.processLLMOutput(agentOutput);

      setState(() {
        _generatedWidgets = widgets;
      });
    } catch (e) {
      debugPrint('Planning error: $e');
    }
  }

  List<Widget> _generatedWidgets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.city)),
      body: _generatedWidgets.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GenUiSurface(
              child: Column(
                children: _generatedWidgets,
              ),
            ),
    );
  }
}
```

### Step 5.5: Event Handling Loop
```dart
// lib/genui/genui_surface.dart
class GenUiSurface extends StatefulWidget {
  final Widget child;
  final Function(Map<String, dynamic>)? onUserEvent;

  const GenUiSurface({required this.child, this.onUserEvent});

  @override
  State<GenUiSurface> createState() => _GenUiSurfaceState();
}

class _GenUiSurfaceState extends State<GenUiSurface> {
  final _agentLlm = AgentLLMService(...);

  void _handleUserInteraction(String action, Map<String, dynamic> data) async {
    debugPrint('User action: $action, data: $data');

    // Send back to LLM for re-thinking
    final response = await _agentLlm.replanWithUserFeedback(action, data);

    // Update UI
    final newWidgets = await GenUiOrchestrator().processLLMOutput(response);
    
    // Refresh state
    setState(() {
      // Update widgets
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onUserEvent?.call({}),
      child: widget.child,
    );
  }
}
```

---

## PART 6: TRANSPARENCY LOGGING

### Step 6.1: Comprehensive Logging
```dart
// lib/services/logging_service.dart
class TransparencyLogger {
  static final _instance = TransparencyLogger._();

  factory TransparencyLogger() => _instance;

  TransparencyLogger._();

  void logLLMInput(String input) {
    final timestamp = DateTime.now().toIso8601String();
    print('''
╔══════════════════════════════════════════════════════════════
║ [LLM INPUT] @ $timestamp
╠══════════════════════════════════════════════════════════════
║ $input
╚══════════════════════════════════════════════════════════════
    ''');
  }

  void logLLMOutput(String output) {
    final timestamp = DateTime.now().toIso8601String();
    print('''
╔══════════════════════════════════════════════════════════════
║ [LLM OUTPUT] @ $timestamp
╠══════════════════════════════════════════════════════════════
║ $output
╚══════════════════════════════════════════════════════════════
    ''');
  }

  void logOSMQuery(String city, List<String> categories) {
    print('[OSM QUERY] city=$city, categories=${categories.join(",")}');
  }

  void logVibeSignatures(List<PlaceData> places) {
    for (final place in places) {
      print('[VIBE] ${place.name}: ${place.vibeSignature}');
    }
  }

  void logDistanceMatrix(Map<String, Map<String, double>> matrix) {
    print('[DISTANCE MATRIX] ${jsonEncode(matrix)}');
  }

  void logUserEvent(String action, Map<String, dynamic> data) {
    print('[USER EVENT] action=$action, data=${jsonEncode(data)}');
  }
}
```

---

## PART 7: KEY PRINCIPLES

### Principle 1: LLM-Only Decision Making
- The LLM decides which places to show, how to group them, and what to recommend.
- The Dart layer provides tools (OSM, distance, clustering) but doesn't decide.

### Principle 2: Vibe-Based Reasoning
- All recommendations are justified with vibe signatures and metadata.
- Example: "I chose this because it's a 1900s local-owned bookstore with a cafe inside."

### Principle 3: Spatial Awareness
- The LLM understands distance, proximity, and efficient routing.
- Day clusters are optimized for walkability and logical flow.

### Principle 4: Transparency
- Every LLM input and output is logged and visible to the user.
- Users can see WHY the AI made each recommendation.

### Principle 5: Offline-First
- Maps use cached tiles (flutter_map_tile_caching).
- LLM runs locally with no internet dependency.

---

## PART 8: TESTING & VALIDATION

### Test Case 1: OSM Query
```dart
test('fetchAttractions returns rich metadata', () async {
  final osm = OverpassService();
  final places = await osm.fetchAttractions(
    city: 'Berlin',
    categories: ['museum', 'cafe'],
  );

  expect(places, isNotEmpty);
  expect(places.first.tags.keys, contains('tourism'));
});
```

### Test Case 2: Vibe Signature
```dart
test('generateVibeSignature creates compact string', () {
  final processor = DiscoveryProcessor();
  final place = PlaceData(...);
  final vibe = processor.generateVibeSignature(place);

  expect(vibe, contains(';'));
  expect(vibe.split(';').length, greaterThan(0));
});
```

### Test Case 3: LLM Planning
```dart
test('agentLLM creates valid A2UI output', () async {
  final llm = AgentLLMService(...);
  final result = await llm.planTrip(
    city: 'Berlin',
    categories: ['museum'],
    userVibe: 'History',
  );

  expect(result, contains('components'));
});
```

---

## PART 9: DEBUGGING CHECKLIST

- [ ] Local LLM starts without API key
- [ ] OSM API returns data with rich tags
- [ ] Vibe signatures are generated for all places
- [ ] Distance matrix calculates correctly
- [ ] LLM receives structured input
- [ ] LLM produces valid A2UI JSON
- [ ] GenUI widgets render correctly
- [ ] User interactions trigger re-planning
- [ ] Maps render with offline tiles
- [ ] Logging shows complete flow

---

## PART 10: DEPLOYMENT NOTES

### iOS
- Ensure CoreML support is enabled
- Test on simulator first, then device
- Check model size fits in App Bundle

### Android
- Use TensorFlow Lite for local inference
- Verify model runs on ARM processors
- Test on both emulator and device

### Web
- Local LLM may not work; consider API fallback
- Ensure tile caching works with service workers

---

## REFERENCES

- [Google AI Edge SDK](https://ai.google.dev/edge)
- [Gemini Nano](https://ai.google.dev/models)
- [Flutter GenUI](https://github.com/google/flutter_genui)
- [Overpass API](https://overpass-api.de/)
- [OpenStreetMap Tags](https://wiki.openstreetmap.org/wiki/Map_Features)
- [A2UI Protocol](https://github.com/google/ai-prototyping/tree/main/a2ui)

---

**Last Updated**: 2026-01-21  
**Status**: Ready for Phase 5 Implementation  
**Maintainer**: AI Travel Agent Team
