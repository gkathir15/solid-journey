# Phase 5: GenUI-Driven AI Travel Agent Architecture
**Timestamp:** 2026-01-21T18:16:14.666Z

---

## Executive Summary

This is the **Master Architecture** for a cross-platform Flutter travel agent that uses:
- **Local LLM (Gemini Nano/Gemma)** for all reasoning
- **OpenStreetMap (OSM)** data via Overpass API
- **flutter_genui** with A2UI protocol for dynamic UI generation
- **Spatial clustering** for intelligent itinerary grouping
- **Vibe signatures** for semantic discovery

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                       UI Layer (GenUI)                       │
│  (PlaceDiscoveryCard, SmartMapSurface, RouteItinerary)      │
└──────────────────────┬──────────────────────────────────────┘
                       │ A2UI Messages
                       ▼
┌─────────────────────────────────────────────────────────────┐
│            GenUI Orchestration Layer (A2uiMessageProcessor) │
└──────────────────────┬──────────────────────────────────────┘
                       │ Component Dispatch
                       ▼
┌─────────────────────────────────────────────────────────────┐
│          Local LLM Engine (Gemini Nano via Google AI Edge)   │
│  System Prompt: "You are a Spatial Planner..."              │
│  Tools: [OSMSlimmer, DistanceMatrix, VibeAnalyzer]         │
└──────────────────────┬──────────────────────────────────────┘
                       │ Tool Invocations
                       ▼
┌─────────────────────────────────────────────────────────────┐
│         Data Discovery & Slimming Layer                      │
│  ├─ OSMService (Overpass API)                               │
│  ├─ DiscoveryProcessor (Vibe Signatures)                    │
│  ├─ SpatialClusterer (Day Grouping)                         │
│  └─ DistanceMatrixCalculator                                │
└──────────────────────┬──────────────────────────────────────┘
                       │ Minified JSON Data
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              External Data Sources                           │
│  ├─ OpenStreetMap (Overpass API)                            │
│  ├─ Tile Cache (flutter_map_tile_caching)                   │
│  └─ Offline Map Data                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation (Environment Setup)

### 1.1 Core Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # AI/ML
  google_generative_ai: ^latest  # For Gemini Nano
  flutter_genui: ^latest          # GenUI rendering
  
  # Mapping & OSM
  flutter_map: ^latest
  flutter_map_tile_caching: ^latest
  latlong2: ^latest
  
  # Networking
  http: ^latest
  
  # Data Processing
  json_annotation: ^latest
  
  # State Management
  provider: ^latest
  
  # Logging (Transparency)
  logger: ^latest
```

### 1.2 Configuration

**Google AI Edge SDK Setup:**
```
1. Download Gemini Nano weights from Google AI Edge GitHub
2. Place in: assets/models/gemini-nano/
3. Initialize in main.dart via GoogleGenerativeAiService
```

**For iOS:**
```bash
# In ios/Podfile
pod 'GoogleGenerativeAI'
pod 'MediaPipeTasksText'  # For local inference
```

**For Android:**
```gradle
// android/app/build.gradle
dependencies {
    implementation 'com.google.ai.edge:generative-ai:latest'
}
```

---

## Phase 2: Data Discovery Engine

### 2.1 The Universal Tag Harvester (OSMService)

**File:** `lib/services/osm_service.dart`

```dart
class OSMService {
  /// Queries Overpass API with comprehensive tag spectrum
  Future<List<PlaceData>> fetchAttractions({
    required String city,
    required List<String> categories,  // e.g., ['museum', 'cafe', 'viewpoint']
  }) async {
    // OverpassQL that pulls:
    // - Primary keys: amenity, tourism, historic, leisure, heritage, shop, craft, man_made, natural
    // - Secondary metadata: cuisine, diet:*, operator, opening_hours, fee, wheelchair, architecture, artist, description
    
    final query = buildOverpassQuery(city, categories);
    final response = await http.get(Uri.parse(overpassEndpoint + query));
    
    return parseOverpassResponse(response);
  }
  
  /// Calculates distance matrix for all places
  Future<Map<String, Map<String, double>>> calculateDistanceMatrix(
    List<PlaceData> places
  ) async {
    // Returns: { "place1": { "place2": 1.2km, "place3": 0.8km }, ... }
    return _computeDistances(places);
  }
}
```

**OverpassQL Template:**
```
[out:json][timeout:30];
{{geocodeArea:{city}}}->.searchArea;
(
  nwr["tourism"~"museum|attraction|viewpoint|historic"](area.searchArea);
  nwr["amenity"~"cafe|restaurant|pub|library|gallery"](area.searchArea);
  nwr["historic"](area.searchArea);
  nwr["leisure"~"park|garden|playground|hackerspace"](area.searchArea);
  nwr["heritage"](area.searchArea);
  nwr["shop"~"bookstore|antique|vintage"](area.searchArea);
  nwr["craft"~"brewery|coffee|tea"](area.searchArea);
  nwr["natural"~"peak|viewpoint|spring"](area.searchArea);
);
out center;
```

### 2.2 The Semantic Discovery Processor

**File:** `lib/services/discovery_processor.dart`

This transforms raw OSM tags into **Vibe Signatures** - compact, token-efficient representations.

```dart
class DiscoveryProcessor {
  /// Converts raw OSM data into a vibe signature
  VibeSignature processPlace(PlaceData place) {
    final tags = place.tags;
    
    // 1. The Heritage Link
    final heritageLinks = _extractHeritage(tags);  // e.g., "18thC_baroque"
    
    // 2. The Localness Test
    final localness = _checkLocalness(tags);  // "local_owned" or "chain"
    
    // 3. The Activity Profile
    final activityProfile = _mapActivityVibes(tags);  // ["social", "quiet", "edgy"]
    
    // 4. The Natural Anchor
    final naturalAnchor = _identifyNature(tags);  // "serene" or null
    
    // 5. Minification: Pack into semicolon-delimited string
    final signature = _minify({
      'vibe': [...activityProfile, naturalAnchor].where((v) => v != null),
      'heritage': heritageLinks,
      'local': localness,
      'amenity': tags['amenity'],
      'cuisine': tags['cuisine'],
      'fee': tags['fee'],
      'wheelchair': tags['wheelchair'],
    });
    
    return VibeSignature(
      name: place.name,
      osmId: place.id,
      signature: signature,  // e.g., "v:nature,quiet,free;h:18thC;l:local"
      fullTags: tags,  // Preserved for LLM justification
    );
  }
  
  String _minify(Map<String, dynamic> data) {
    // Convert to semicolon-delimited format
    return data.entries
      .where((e) => e.value != null && e.value.toString().isNotEmpty)
      .map((e) => '${e.key.substring(0, 1)}:${e.value}')
      .join(';');
  }
}

class VibeSignature {
  final String name;
  final String osmId;
  final String signature;  // Minified vibe string
  final Map<String, dynamic> fullTags;  // For detailed justification
}
```

**Vibe Signature Examples:**
```
Museum: "v:history,quiet,art;h:1850s;l:local;fee:yes;wheelchair:yes"
Cafe: "v:social,quiet,artsy;l:local;cuisine:specialty_coffee;wheelchair:yes"
Viewpoint: "v:nature,serene,free;natural:peak;fee:no"
Hidden Gem Bookstore: "v:quiet,indie,history;h:vintage;l:local;fee:no;wheelchair:limited"
```

### 2.3 Spatial Clustering Engine

**File:** `lib/services/spatial_clusterer.dart`

```dart
class SpatialClusterer {
  /// Groups places into "Day Clusters" based on proximity (1km radius)
  Future<List<DayCluster>> clusterForItinerary({
    required List<VibeSignature> places,
    required Map<String, Map<String, double>> distanceMatrix,
    required int tripDuration,  // Number of days
  }) async {
    // Algorithm:
    // 1. Identify "Anchor Points" (highest-rated, most central, or flagship places)
    // 2. Build clusters around anchors using 1km radius
    // 3. Sort by distance to create optimal routes
    // 4. Distribute across days
    
    return _performClustering(places, distanceMatrix, tripDuration);
  }
}

class DayCluster {
  final int dayNumber;
  final List<VibeSignature> places;
  final String theme;  // "History & Art" or "Hidden Gems"
  final double totalDistance;  // km
}
```

---

## Phase 3: Local LLM Reasoning Engine

### 3.1 Gemini Nano Configuration

**File:** `lib/services/ai_service.dart`

```dart
class AiService {
  late final GenerativeModel _model;
  
  AiService() {
    // Initialize with LOCAL Gemini Nano model
    _model = GenerativeModel(
      model: 'gemini-nano',  // This is the LOCAL model
      apiKey: '',  // No API key needed for local inference
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.95,
      ),
    );
  }
  
  Future<String> planTrip({
    required String userPrompt,
    required List<VibeSignature> discoveredPlaces,
    required List<DayCluster> clusters,
  }) async {
    final systemInstruction = '''
You are a Spatial Planner AI for travel experiences. Your role is to:

1. Analyze the user's vibe preferences and trip duration
2. Use the Discovery Signatures provided to understand place characteristics
3. Invoke the OSMSlimmer tool to fetch new places if needed
4. Recommend spatial groupings (Day Clusters) based on proximity and theme
5. Emit A2UI messages to render the UI components

CRITICAL RULES:
- Only use widgets from the provided catalog: [PlaceDiscoveryCard, SmartMapSurface, RouteItinerary]
- Justify every recommendation using the rich metadata (e.g., "This 1900s local bookstore cafe matches your 'quiet history' vibe")
- Always provide coordinates for map rendering
- Group places within 1km for same-day visits
- Prioritize high-rated and unique places as "Anchor Points"

When a user interacts with a component, re-think and emit updated A2UI messages.
    ''';
    
    // Build context with discovered places and their signatures
    final context = _buildContext(discoveredPlaces, clusters);
    
    // Send to local LLM
    final response = await _model.generateContent([
      Content.text(systemInstruction),
      Content.text(context),
      Content.text(userPrompt),
    ]);
    
    return response.text ?? '';
  }
  
  String _buildContext(List<VibeSignature> places, List<DayCluster> clusters) {
    return '''
DISCOVERED PLACES (with Vibe Signatures):
${places.map((p) => '- ${p.name}: ${p.signature}').join('\n')}

SUGGESTED CLUSTERS:
${clusters.asMap().entries.map((e) => 
  'Day ${e.key + 1}: ${e.value.places.map((p) => p.name).join(', ')}'
).join('\n')}
    ''';
  }
}
```

---

## Phase 4: GenUI Component Catalog

### 4.1 Widget Catalog Definition

**File:** `lib/genui/widget_catalog.dart`

```dart
class WidgetCatalog {
  static final Map<String, GenUIWidgetBuilder> catalog = {
    'PlaceDiscoveryCard': PlaceDiscoveryCardBuilder(),
    'SmartMapSurface': SmartMapSurfaceBuilder(),
    'RouteItinerary': RouteItineraryBuilder(),
  };
}

// Each widget has a JSON Schema for AI guidance
class PlaceDiscoveryCardSchema {
  static const schema = {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'Place name'},
      'vibeSignature': {'type': 'string', 'description': 'Minified vibe string'},
      'coordinate': {
        'type': 'object',
        'properties': {
          'latitude': {'type': 'number'},
          'longitude': {'type': 'number'},
        }
      },
      'imageUrl': {'type': 'string'},
      'description': {'type': 'string'},
    },
    'required': ['name', 'vibeSignature', 'coordinate'],
  };
}

class SmartMapSurfaceSchema {
  static const schema = {
    'type': 'object',
    'properties': {
      'places': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'lat': {'type': 'number'},
            'lng': {'type': 'number'},
            'vibeFilter': {'type': 'string'},  // Filter pins by vibe tag
          }
        }
      },
      'centerLat': {'type': 'number'},
      'centerLng': {'type': 'number'},
      'zoom': {'type': 'number'},
    },
  };
}

class RouteItinerarySchema {
  static const schema = {
    'type': 'object',
    'properties': {
      'days': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'dayNumber': {'type': 'integer'},
            'theme': {'type': 'string'},
            'places': {'type': 'array', 'items': {'type': 'string'}},
            'totalDistance': {'type': 'number'},
          }
        }
      }
    },
  };
}
```

### 4.2 Widget Implementations

**File:** `lib/genui/widgets/place_discovery_card.dart`

```dart
class PlaceDiscoveryCard extends StatelessWidget {
  final String name;
  final String vibeSignature;
  final LatLng coordinate;
  final String? description;
  
  const PlaceDiscoveryCard({
    required this.name,
    required this.vibeSignature,
    required this.coordinate,
    this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
          Text(vibeSignature, style: TextStyle(color: Colors.grey)),
          if (description != null) Text(description!),
          ElevatedButton(
            onPressed: () => _addToTrip(context),
            child: Text('Add to Trip'),
          ),
        ],
      ),
    );
  }
  
  void _addToTrip(BuildContext context) {
    // Capture event and send back to LLM
    // This triggers a DataModelUpdate
  }
}
```

**File:** `lib/genui/widgets/smart_map_surface.dart`

```dart
class SmartMapSurface extends StatelessWidget {
  final List<PlaceData> places;
  final LatLng center;
  final double zoom;
  final String? vibeFilter;
  
  const SmartMapSurface({
    required this.places,
    required this.center,
    this.zoom = 15,
    this.vibeFilter,
  });
  
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: center,
        zoom: zoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: places
            .where((p) => vibeFilter == null || p.vibeSignature.contains(vibeFilter!))
            .map((p) => Marker(
              point: LatLng(p.latitude, p.longitude),
              builder: (ctx) => GestureDetector(
                onTap: () => _onMarkerTap(context, p),
                child: Icon(Icons.location_on, color: Colors.red),
              ),
            ))
            .toList(),
        ),
      ],
    );
  }
  
  void _onMarkerTap(BuildContext context, PlaceData place) {
    // Capture interaction -> send to LLM as DataModelUpdate
  }
}
```

**File:** `lib/genui/widgets/route_itinerary.dart`

```dart
class RouteItinerary extends StatelessWidget {
  final List<DayCluster> days;
  
  const RouteItinerary({required this.days});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (ctx, idx) {
        final day = days[idx];
        return Card(
          child: ExpansionTile(
            title: Text('Day ${day.dayNumber}: ${day.theme}'),
            subtitle: Text('${day.totalDistance}km'),
            children: [
              ...day.places.map((p) => ListTile(
                title: Text(p.name),
                subtitle: Text(p.signature),
              )),
            ],
          ),
        );
      },
    );
  }
}
```

---

## Phase 5: GenUI Orchestration Layer

### 5.1 A2UI Message Processing

**File:** `lib/genui/a2ui_message_processor.dart`

```dart
class A2uiMessageProcessor {
  final WidgetCatalog catalog;
  
  /// Listen to LLM output and convert A2UI messages to widgets
  Future<List<Widget>> processMessage(String llmOutput) async {
    // Parse A2UI JSON from LLM response
    final a2uiMessages = parseA2UI(llmOutput);
    
    final widgets = <Widget>[];
    
    for (final msg in a2uiMessages) {
      final widgetBuilder = catalog.catalog[msg.type];
      if (widgetBuilder != null) {
        widgets.add(widgetBuilder.build(msg.payload));
      }
    }
    
    return widgets;
  }
}

class A2uiMessage {
  final String type;  // 'PlaceDiscoveryCard', 'SmartMapSurface', 'RouteItinerary'
  final Map<String, dynamic> payload;
}

List<A2uiMessage> parseA2UI(String llmOutput) {
  // Parse JSON embedded in LLM response
  // Example A2UI format:
  // ```a2ui
  // [
  //   {"type": "SmartMapSurface", "payload": {...}},
  //   {"type": "RouteItinerary", "payload": {...}}
  // ]
  // ```a2ui
}
```

### 5.2 GenUI Surface Container

**File:** `lib/screens/discovery_surface.dart`

```dart
class DiscoverySurface extends StatefulWidget {
  @override
  State<DiscoverySurface> createState() => _DiscoverySurfaceState();
}

class _DiscoverySurfaceState extends State<DiscoverySurface> {
  late final AiService _aiService;
  late final A2uiMessageProcessor _processor;
  
  List<Widget> _generatedWidgets = [];
  
  @override
  void initState() {
    super.initState();
    _aiService = AiService();
    _processor = A2uiMessageProcessor();
  }
  
  @override
  Widget build(BuildContext context) {
    return GenUiSurface(
      child: SingleChildScrollView(
        child: Column(
          children: _generatedWidgets,
        ),
      ),
    );
  }
  
  /// Called when user provides input
  void _onUserInput(String input) async {
    // 1. Send to AI (with discovered places context)
    final aiResponse = await _aiService.planTrip(
      userPrompt: input,
      discoveredPlaces: [],  // From previous discovery
      clusters: [],  // From previous clustering
    );
    
    // 2. Process A2UI messages from AI response
    final widgets = await _processor.processMessage(aiResponse);
    
    // 3. Update UI
    setState(() {
      _generatedWidgets = widgets;
    });
  }
  
  /// Called when user interacts with generated widget
  void _onWidgetInteraction(String widgetId, dynamic data) async {
    // Send DataModelUpdate back to LLM
    final updatedResponse = await _aiService.handleUserInteraction(
      widgetId: widgetId,
      data: data,
    );
    
    final widgets = await _processor.processMessage(updatedResponse);
    setState(() {
      _generatedWidgets = widgets;
    });
  }
}
```

---

## Phase 5: Data Flow & Communication Loop

### 5.1 User Interaction Flow

```
1. USER INPUT
   ├─ "I want a quiet history trip in Prague for 3 days"
   └─> DiscoverySurface._onUserInput()

2. OSM DATA FETCHING
   ├─ OSMService.fetchAttractions(city='Prague', categories=['museum','historic','cafe'])
   └─> Returns raw OSM data with all tags

3. DISCOVERY PROCESSING
   ├─ DiscoveryProcessor.processPlace() for each place
   ├─ Creates VibeSignatures: "v:history,quiet;h:17thC;l:local;fee:yes"
   └─> Returns minified JSON list

4. SPATIAL CLUSTERING
   ├─ SpatialClusterer.clusterForItinerary()
   ├─ Calculates distance matrix
   ├─ Groups places into Day Clusters
   └─> Returns List<DayCluster>

5. LOCAL LLM REASONING
   ├─ AiService.planTrip(userPrompt, discoveredPlaces, clusters)
   ├─ System instruction guides spatial planning
   ├─ LLM analyzes vibe signatures and patterns
   └─> Returns A2UI-formatted response

6. A2UI PARSING & RENDERING
   ├─ A2uiMessageProcessor.processMessage()
   ├─ Matches AI components to catalog widgets
   ├─ Builds: SmartMapSurface, RouteItinerary, PlaceDiscoveryCards
   └─> GenUiSurface renders dynamically

7. USER INTERACTION
   ├─ User taps "Add to Trip" on a PlaceDiscoveryCard
   ├─ DiscoverySurface._onWidgetInteraction(widgetId, data)
   └─> Sends DataModelUpdate back to LLM

8. REPLAN & RE-RENDER
   ├─ LLM receives interaction event
   ├─ Updates internal state (added place -> recalculate distance)
   ├─ Emits new A2UI message
   └─> UI re-renders with updated itinerary
```

---

## Phase 5: Tool Definitions for LLM

The LLM has access to these tools:

### Tool 1: OSMSlimmer
**Purpose:** Fetch and minify OSM data for a location
```json
{
  "name": "OSMSlimmer",
  "description": "Fetch attractions with vibe signatures",
  "parameters": {
    "city": "string",
    "categories": ["string"],
    "includeSecondaryMetadata": "boolean"
  }
}
```

### Tool 2: DistanceMatrix
**Purpose:** Calculate distances between discovered places
```json
{
  "name": "DistanceMatrix",
  "description": "Get distance matrix for places",
  "parameters": {
    "placeIds": ["string"]
  }
}
```

### Tool 3: VibeAnalyzer
**Purpose:** Analyze place signatures against user preferences
```json
{
  "name": "VibeAnalyzer",
  "description": "Match places to user's vibe preferences",
  "parameters": {
    "userVibe": "string",
    "places": ["object"]
  }
}
```

### Tool 4: A2uiRenderer
**Purpose:** Emit A2UI messages to render widgets
```json
{
  "name": "A2uiRenderer",
  "description": "Render UI components",
  "parameters": {
    "widgets": [
      {
        "type": "string (PlaceDiscoveryCard|SmartMapSurface|RouteItinerary)",
        "payload": "object"
      }
    ]
  }
}
```

---

## Implementation Checklist

### Immediate Tasks:
- [ ] Set up Google AI Edge SDK with Gemini Nano weights
- [ ] Implement OSMService with Overpass API integration
- [ ] Build DiscoveryProcessor with vibe signature minification
- [ ] Create SpatialClusterer for day grouping
- [ ] Initialize AiService with local model
- [ ] Build all GenUI widgets (PlaceDiscoveryCard, SmartMapSurface, RouteItinerary)
- [ ] Create A2uiMessageProcessor
- [ ] Build DiscoverySurface with interaction handling
- [ ] Add comprehensive transparency logging throughout

### Transparency Logging Points:
```dart
// In OSMService
logger.info('OSM_FETCH', {'city': city, 'categories': categories});
logger.debug('OSM_RESPONSE', {'places': places.length, 'tags': places[0].tags});

// In DiscoveryProcessor
logger.info('VIBE_SIGNATURE', {'place': place.name, 'signature': signature});

// In AiService
logger.info('LLM_INPUT', {'prompt': userPrompt, 'context_size': context.length});
logger.info('LLM_OUTPUT', {'response': response, 'duration_ms': elapsed});

// In A2uiMessageProcessor
logger.info('A2UI_PARSED', {'widgets': widgets.map((w) => w.type).toList()});

// In DiscoverySurface
logger.info('WIDGET_INTERACTION', {'widgetId': widgetId, 'data': data});
```

---

## Key Principles

1. **Local-First:** All LLM inference happens on-device. No API keys, no cloud.
2. **Token-Efficient:** Vibe signatures compress rich OSM data to minimize token usage.
3. **Spatial-Aware:** The LLM reasons about proximity and groups accordingly.
4. **Transparent:** Every input to and output from LLM is logged for inspection.
5. **GenUI-Driven:** The UI is entirely generated by the AI, not hard-coded.
6. **Tool-Enabled:** The LLM can invoke data discovery tools and reason about results.

---

## Next Steps

1. Implement Phase 5 code following this architecture
2. Test with iOS simulator first
3. Debug Android build issues
4. Add offline map tile caching for production
5. Optimize token usage based on real-world logs

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-21T18:16:14.666Z
