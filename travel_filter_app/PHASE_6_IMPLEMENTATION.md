# Phase 6: GenUI Integration & Full LLM Orchestration

## Current Status
✅ Phase 5 Complete:
- Universal Tag Harvester (OSM data extraction)
- Semantic Discovery Engine (vibe signature creation)
- Discovery Orchestrator (coordination layer)
- Local LLM integration (Gemini Nano)
- Transparency logging throughout

## Phase 6: The GenUI Integration Layer

### What is GenUI?
GenUI (Generative UI) is Google's AI-driven UI generation framework. The LLM generates JSON that describes UI components, and the flutter_genui package renders them.

### Architecture Overview
```
User Input
    ↓
Phase5Home (UI State)
    ↓
LLMReasoningEngine (with tool calling)
    ↓
Tool Execution (OSM, Spatial Clustering)
    ↓
GenUI Component Catalog (JSON Schema definitions)
    ↓
GenUiSurface (Renders AI-generated components)
    ↓
Interactive UI (User interacts → feedback to LLM)
```

---

## Step 1: Define the Component Catalog (JSON Schemas)

The LLM needs to know EXACTLY what widgets it can generate. We define this using JSON Schema.

### Components to Catalog:

#### 1.1 PlaceDiscoveryCard
```json
{
  "componentId": "PlaceDiscoveryCard",
  "schema": {
    "type": "object",
    "properties": {
      "name": { "type": "string", "description": "Place name" },
      "vibeSignature": { "type": "string", "description": "Semicolon-delimited vibe tags" },
      "rating": { "type": "number", "minimum": 0, "maximum": 5 },
      "category": { "type": "string", "enum": ["museum", "cafe", "landmark", "nature", "shopping", "nightlife", "spiritual", "cultural"] },
      "distanceKm": { "type": "number", "description": "Distance from user/anchor point in km" },
      "imageUrl": { "type": "string", "format": "uri" },
      "accessibilityFlags": { "type": "array", "items": { "type": "string" }, "description": ["wheelchair", "free", "no_smoking"] }
    },
    "required": ["name", "category", "vibeSignature"]
  }
}
```

#### 1.2 SmartMapSurface
```json
{
  "componentId": "SmartMapSurface",
  "schema": {
    "type": "object",
    "properties": {
      "centerLat": { "type": "number" },
      "centerLng": { "type": "number" },
      "zoomLevel": { "type": "number", "minimum": 5, "maximum": 18 },
      "places": { 
        "type": "array", 
        "items": {
          "type": "object",
          "properties": {
            "id": { "type": "string" },
            "lat": { "type": "number" },
            "lng": { "type": "number" },
            "name": { "type": "string" },
            "icon": { "type": "string", "enum": ["museum", "food", "landmark", "nature", "shopping"] }
          }
        }
      },
      "polylines": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "points": { "type": "array", "items": { "type": "object", "properties": { "lat": { "type": "number" }, "lng": { "type": "number" } } } },
            "color": { "type": "string", "pattern": "^#[0-9a-fA-F]{6}$" },
            "label": { "type": "string" }
          }
        }
      }
    },
    "required": ["centerLat", "centerLng", "places"]
  }
}
```

#### 1.3 RouteItinerary (Day Clusters)
```json
{
  "componentId": "RouteItinerary",
  "schema": {
    "type": "object",
    "properties": {
      "days": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "dayNumber": { "type": "integer", "minimum": 1 },
            "theme": { "type": "string", "description": "Day theme (e.g., 'Historic Wandering', 'Cafe Culture')" },
            "places": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "name": { "type": "string" },
                  "timeSlot": { "type": "string", "pattern": "^\\d{2}:\\d{2}$" },
                  "duration": { "type": "string", "description": "e.g., '1h 30m'" },
                  "reason": { "type": "string", "description": "Why the LLM chose this place" }
                }
              }
            },
            "estimatedDistance": { "type": "number", "description": "Total km for the day" }
          },
          "required": ["dayNumber", "theme", "places"]
        }
      }
    },
    "required": ["days"]
  }
}
```

---

## Step 2: Implement GenUI Component Catalog Service

File: `lib/services/genui_component_catalog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:json_schema/json_schema.dart';

class GenUiComponentCatalog {
  static final Map<String, JsonSchema> _schemas = {
    'PlaceDiscoveryCard': _buildPlaceDiscoveryCardSchema(),
    'SmartMapSurface': _buildSmartMapSurfaceSchema(),
    'RouteItinerary': _buildRouteItinerarySchema(),
  };

  static JsonSchema _buildPlaceDiscoveryCardSchema() {
    return JsonSchema.createSchema({
      'type': 'object',
      'properties': {
        'name': {'type': 'string'},
        'vibeSignature': {'type': 'string'},
        'rating': {'type': 'number', 'minimum': 0, 'maximum': 5},
        'category': {'type': 'string'},
        'distanceKm': {'type': 'number'},
        'imageUrl': {'type': 'string'},
        'accessibilityFlags': {'type': 'array', 'items': {'type': 'string'}},
      },
      'required': ['name', 'category', 'vibeSignature'],
    });
  }

  static JsonSchema _buildSmartMapSurfaceSchema() {
    return JsonSchema.createSchema({
      'type': 'object',
      'properties': {
        'centerLat': {'type': 'number'},
        'centerLng': {'type': 'number'},
        'zoomLevel': {'type': 'number'},
        'places': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'id': {'type': 'string'},
              'lat': {'type': 'number'},
              'lng': {'type': 'number'},
              'name': {'type': 'string'},
              'icon': {'type': 'string'},
            },
          },
        },
        'polylines': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'points': {'type': 'array'},
              'color': {'type': 'string'},
              'label': {'type': 'string'},
            },
          },
        },
      },
      'required': ['centerLat', 'centerLng', 'places'],
    });
  }

  static JsonSchema _buildRouteItinerarySchema() {
    return JsonSchema.createSchema({
      'type': 'object',
      'properties': {
        'days': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'dayNumber': {'type': 'integer'},
              'theme': {'type': 'string'},
              'places': {'type': 'array'},
              'estimatedDistance': {'type': 'number'},
            },
            'required': ['dayNumber', 'theme', 'places'],
          },
        },
      },
      'required': ['days'],
    });
  }

  /// Get all component schemas for LLM tool definition
  static Map<String, dynamic> getAllSchemasForLLM() {
    return {
      'componentCatalog': {
        'PlaceDiscoveryCard': {
          'description': 'A card displaying a single place discovery with vibe signature',
          'schema': _schemas['PlaceDiscoveryCard']?.toJson(),
        },
        'SmartMapSurface': {
          'description': 'An interactive map showing places, routes, and polylines',
          'schema': _schemas['SmartMapSurface']?.toJson(),
        },
        'RouteItinerary': {
          'description': 'A day-by-day itinerary broken into day clusters',
          'schema': _schemas['RouteItinerary']?.toJson(),
        },
      },
    };
  }

  /// Validate component data against schema
  static bool validateComponent(String componentId, Map<String, dynamic> data) {
    final schema = _schemas[componentId];
    if (schema == null) return false;
    
    try {
      return schema.validate(data).isValid;
    } catch (e) {
      print('Validation error for $componentId: $e');
      return false;
    }
  }
}
```

---

## Step 3: Implement LLM Reasoning Engine with Tool Calling

File: `lib/services/llm_reasoning_engine_v2.dart`

This is the CORE of Phase 6. The LLM must:
1. Receive user input + vibe preferences
2. Call the OSM tool to get places + vibe signatures
3. Call spatial clustering to group places into days
4. Generate GenUI JSON for rendering

```dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

class LLMReasoningEngineV2 {
  final GenerativeModel _model;
  final _log = Logger('LLMReasoningEngineV2');

  // Tool definitions that the LLM can call
  late final List<Tool> _tools;

  LLMReasoningEngineV2(this._model) {
    _initializeTools();
  }

  void _initializeTools() {
    _tools = [
      Tool(
        functionDeclarations: [
          FunctionDeclaration(
            name: 'fetch_osm_places',
            description: 'Fetch places from OpenStreetMap based on city and categories',
            inputSchema: Schema(
              type: SchemaType.object,
              properties: {
                'city': Schema(type: SchemaType.string, description: 'City name'),
                'country': Schema(type: SchemaType.string, description: 'Country name'),
                'categories': Schema(
                  type: SchemaType.array,
                  items: Schema(type: SchemaType.string),
                  description: 'OSM categories: tourism, amenity, leisure, historic, etc.',
                ),
              },
              requiredProperties: ['city', 'country'],
            ),
          ),
          FunctionDeclaration(
            name: 'spatial_cluster_places',
            description: 'Group places into day clusters based on proximity (1km threshold)',
            inputSchema: Schema(
              type: SchemaType.object,
              properties: {
                'places': Schema(
                  type: SchemaType.array,
                  description: 'List of places with lat/lng coordinates',
                ),
                'numDays': Schema(type: SchemaType.integer, description: 'Number of days for trip'),
              },
              requiredProperties: ['places', 'numDays'],
            ),
          ),
          FunctionDeclaration(
            name: 'generate_genui_component',
            description: 'Generate a GenUI component (PlaceDiscoveryCard, SmartMapSurface, or RouteItinerary)',
            inputSchema: Schema(
              type: SchemaType.object,
              properties: {
                'componentType': Schema(
                  type: SchemaType.string,
                  description: 'Component to generate: PlaceDiscoveryCard, SmartMapSurface, or RouteItinerary',
                ),
                'data': Schema(
                  type: SchemaType.object,
                  description: 'Component-specific data matching the catalog schema',
                ),
              },
              requiredProperties: ['componentType', 'data'],
            ),
          ),
        ],
      ),
    ];
  }

  /// Main reasoning loop with tool calling
  Future<GenerateContentResponse> planTrip({
    required String city,
    required String country,
    required List<String> userVibes,
    required int tripDurationDays,
    required List<String> categories,
  }) async {
    _log.info('🎯 TRIP PLANNING: $city, $country - $tripDurationDays days');
    _log.info('👤 User Vibes: $userVibes');

    // System instruction for the LLM
    final systemInstruction = '''You are a Spatial Travel Planner. Your job is to:
1. Call fetch_osm_places to get places in the city
2. Analyze places against user vibes: $userVibes
3. Call spatial_cluster_places to group places by proximity into days
4. Call generate_genui_component to create UI components
5. Emit ONLY valid GenUI components that match the catalog

Remember: The user prefers: ${userVibes.join(', ')}
Focus on: independent/local places, vibe-matching, hidden gems.
Avoid: touristy/crowded generic chains unless explicitly requested.
''';

    final userMessage = '''Plan a $tripDurationDays-day trip to $city, $country.
User vibes: ${userVibes.join(', ')}
Categories to explore: ${categories.join(', ')}

First, fetch places using fetch_osm_places.
Then, cluster them using spatial_cluster_places.
Finally, generate GenUI components using generate_genui_component to render an itinerary.
''';

    // Start conversation
    final content = [
      Content.text(userMessage),
    ];

    try {
      // Initial request with tools
      _log.info('📤 Sending initial request with tool definitions');
      final response = await _model.generateContent(
        content,
        tools: _tools,
      );

      _log.info('📥 Response received with ${response.candidates.length} candidates');

      // Check if LLM wants to call tools
      for (final candidate in response.candidates) {
        if (candidate.content.parts.isEmpty) continue;

        for (final part in candidate.content.parts) {
          if (part is FunctionCall) {
            _log.info('🔧 LLM called function: ${part.name}');
            _log.info('📋 Function args: ${jsonEncode(part.args)}');

            // Execute the tool call
            final toolResult = await _executeTool(part.name, part.args);
            _log.info('✅ Tool result: ${toolResult.toString().substring(0, 200)}...');

            // Feed result back to LLM
            content.add(candidate.content);
            content.add(Content.functionResponse(
              name: part.name,
              response: toolResult,
            ));

            // Continue conversation
            final followUp = await _model.generateContent(content, tools: _tools);
            return followUp;
          }
        }
      }

      return response;
    } catch (e) {
      _log.severe('❌ Trip planning failed: $e');
      rethrow;
    }
  }

  /// Execute tool calls from LLM
  Future<Map<String, dynamic>> _executeTool(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    switch (toolName) {
      case 'fetch_osm_places':
        return await _toolFetchOsmPlaces(args);
      case 'spatial_cluster_places':
        return await _toolSpatialCluster(args);
      case 'generate_genui_component':
        return await _toolGenerateComponent(args);
      default:
        throw Exception('Unknown tool: $toolName');
    }
  }

  /// Tool: Fetch OSM Places
  Future<Map<String, dynamic>> _toolFetchOsmPlaces(Map<String, dynamic> args) async {
    final city = args['city'] as String;
    final country = args['country'] as String;
    final categories = List<String>.from(args['categories'] ?? []);

    _log.info('🌍 Fetching OSM places: $city, $country');

    // Call the DiscoveryOrchestrator
    // TODO: Inject DiscoveryOrchestrator into this service
    // For now, return mock data
    
    return {
      'status': 'success',
      'count': 25,
      'places': [
        {
          'name': 'Local Coffee Place',
          'lat': 48.8566,
          'lng': 2.3522,
          'vibeSignature': 'l:indie;a:a:cozy;am:cuis:french;s:free;acc:wc:yes',
          'category': 'cafe',
          'rating': 4.5,
        },
        // More places...
      ],
    };
  }

  /// Tool: Spatial Clustering
  Future<Map<String, dynamic>> _toolSpatialCluster(Map<String, dynamic> args) async {
    final places = args['places'] as List;
    final numDays = args['numDays'] as int;

    _log.info('📍 Clustering ${places.length} places into $numDays days');

    // Call SpatialClusteringService
    // TODO: Inject SpatialClusteringService into this service

    return {
      'status': 'success',
      'dayClusters': [
        {
          'day': 1,
          'places': places.take(8).toList(),
          'theme': 'Historic Wandering',
        },
        // More days...
      ],
    };
  }

  /// Tool: Generate GenUI Component
  Future<Map<String, dynamic>> _toolGenerateComponent(Map<String, dynamic> args) async {
    final componentType = args['componentType'] as String;
    final data = args['data'] as Map<String, dynamic>;

    _log.info('🎨 Generating GenUI component: $componentType');

    // Validate against schema
    if (!GenUiComponentCatalog.validateComponent(componentType, data)) {
      _log.warning('⚠️ Component validation failed for $componentType');
      return {'status': 'error', 'message': 'Invalid component data'};
    }

    return {
      'status': 'success',
      'componentId': componentType,
      'data': data,
    };
  }
}
```

---

## Step 4: Implement GenUI Surface Renderer

File: `lib/widgets/genui_surface.dart`

```dart
import 'package:flutter/material.dart';
import '../services/genui_component_catalog.dart';

class GenUiSurface extends StatefulWidget {
  final List<Map<String, dynamic>> components;
  final Function(String eventName, Map<String, dynamic> data)? onEvent;

  const GenUiSurface({
    required this.components,
    this.onEvent,
  });

  @override
  State<GenUiSurface> createState() => _GenUiSurfaceState();
}

class _GenUiSurfaceState extends State<GenUiSurface> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.components.length,
      itemBuilder: (context, index) {
        final component = widget.components[index];
        final componentType = component['componentId'] as String?;
        final data = component['data'] as Map<String, dynamic>?;

        if (componentType == null || data == null) {
          return SizedBox.shrink();
        }

        return _buildComponent(componentType, data);
      },
    );
  }

  Widget _buildComponent(String componentType, Map<String, dynamic> data) {
    switch (componentType) {
      case 'PlaceDiscoveryCard':
        return _buildPlaceDiscoveryCard(data);
      case 'SmartMapSurface':
        return _buildSmartMap(data);
      case 'RouteItinerary':
        return _buildItinerary(data);
      default:
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Unknown component: $componentType'),
          ),
        );
    }
  }

  Widget _buildPlaceDiscoveryCard(Map<String, dynamic> data) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'] ?? 'Unknown',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'Vibe: ${data['vibeSignature'] ?? ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (data['rating'] != null)
              Text('Rating: ${data['rating']}/5'),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                widget.onEvent?.call('place_selected', data);
              },
              child: Text('Add to Trip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartMap(Map<String, dynamic> data) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Container(
        height: 300,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 48),
              SizedBox(height: 8),
              Text('Map: ${data['places']?.length ?? 0} places'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItinerary(Map<String, dynamic> data) {
    final days = data['days'] as List? ?? [];
    
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Itinerary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            ...days.asMap().entries.map((entry) {
              final day = entry.value as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day ${day['dayNumber']}: ${day['theme'] ?? 'Exploration'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 8),
                    ...(day['places'] as List?)?.map((place) {
                          return Text(
                            '• ${place['name']} (${place['timeSlot'] ?? 'TBD'})',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }).toList() ?? [],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
```

---

## Step 5: Integration with Phase5Home

Update `phase5_home.dart` to use the new LLM reasoning engine:

```dart
// In Phase5Home state
Future<void> _planTrip() async {
  setState(() => _isLoading = true);

  try {
    final reasoningEngine = LLMReasoningEngineV2(_model);
    
    final response = await reasoningEngine.planTrip(
      city: _selectedCity,
      country: _selectedCountry,
      userVibes: _selectedVibes,
      tripDurationDays: _tripDuration,
      categories: ['tourism', 'amenity', 'leisure'],
    );

    // Parse GenUI components from response
    final components = _parseGenUiComponents(response);
    
    setState(() {
      _generatedComponents = components;
      _isLoading = false;
    });
  } catch (e) {
    _log.severe('Trip planning failed: $e');
    setState(() => _isLoading = false);
  }
}
```

---

## Remaining Work

### Phase 6 Checklist:
- [ ] Implement GenUiComponentCatalog (step 1)
- [ ] Implement LLMReasoningEngineV2 with tool calling (step 2-3)
- [ ] Implement GenUiSurface renderer (step 4)
- [ ] Integrate with Phase5Home (step 5)
- [ ] Test end-to-end flow
- [ ] Add error handling & fallbacks
- [ ] Optimize token usage
- [ ] Add analytics/logging

### Phase 7 (Beyond):
- Interactive feedback loop (user taps on component → LLM reconsiders)
- Offline map caching with flutter_map_tile_caching
- Real-time route optimization
- Multi-language support

---

## Key Success Metrics
1. ✅ LLM successfully calls OSM tool
2. ✅ Spatial clustering groups places correctly
3. ✅ GenUI components render properly
4. ✅ Full loop: User input → LLM reasoning → UI generation
