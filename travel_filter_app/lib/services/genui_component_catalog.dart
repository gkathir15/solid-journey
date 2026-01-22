import 'package:json_schema/json_schema.dart';

/// GenUI Component Catalog - The "LEGO Bricks" the LLM can use
/// 
/// Each component has:
/// - Widget definition (Flutter widget)
/// - JSON Schema (so LLM knows what fields to fill)
/// - Rendering logic
class GenUiComponentCatalog {
  /// All available components
  static const Map<String, GenUiComponentDefinition> components = {
    'PlaceDiscoveryCard': PlaceDiscoveryCardComponent.definition,
    'SmartMapSurface': SmartMapSurfaceComponent.definition,
    'RouteItinerary': RouteItineraryComponent.definition,
    'DayClusterCard': DayClusterCardComponent.definition,
    'VibeSignatureDisplay': VibeSignatureDisplayComponent.definition,
  };

  /// Get component by name
  static GenUiComponentDefinition? getComponent(String name) {
    return components[name];
  }

  /// List all available components
  static List<String> getAvailableComponents() {
    return components.keys.toList();
  }

  /// Validate that LLM output matches a component's schema
  static bool validateComponent(String componentName, Map<String, dynamic> data) {
    final definition = getComponent(componentName);
    if (definition == null) return false;

    try {
      final schema = jsonSchemaFromJson(definition.jsonSchema);
      return schema.validate(data).isValid;
    } catch (e) {
      return false;
    }
  }
}

/// Base definition for a GenUI component
class GenUiComponentDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> jsonSchema;
  final Map<String, dynamic> example;

  GenUiComponentDefinition({
    required this.name,
    required this.description,
    required this.jsonSchema,
    required this.example,
  });
}

/// PlaceDiscoveryCard Component
/// Shows a single place with: Name, Vibe Signature, Image, Action Button
class PlaceDiscoveryCardComponent {
  static final definition = GenUiComponentDefinition(
    name: 'PlaceDiscoveryCard',
    description:
        'Card displaying a single place with vibe signature and image',
    jsonSchema: {
      'type': 'object',
      'required': ['id', 'name', 'vibe_signature'],
      'properties': {
        'id': {'type': 'string', 'description': 'Unique place ID from OSM'},
        'name': {
          'type': 'string',
          'description': 'Place name',
          'maxLength': 100,
        },
        'vibe_signature': {
          'type': 'string',
          'description': 'Compact vibe signature (e.g., l:indie;a:culture)',
        },
        'location': {
          'type': 'object',
          'properties': {
            'lat': {'type': 'number'},
            'lon': {'type': 'number'},
          },
        },
        'image_url': {
          'type': 'string',
          'description': 'URL to place image (optional)',
        },
        'reason': {
          'type': 'string',
          'description': 'LLM-generated reason why this place matches user vibe',
        },
        'score': {
          'type': 'number',
          'description': 'Confidence score 0-1',
        },
      },
    },
    example: {
      'id': 'OSM_12345',
      'name': 'Local Bookstore Café',
      'vibe_signature': 'l:indie;a:quiet;am:cuis:coffee;s:free;acc:wc:yes',
      'location': {'lat': 48.8566, 'lon': 2.3522},
      'reason': 'Independent bookstore with cozy café - perfect for your cultural + local vibe',
      'score': 0.92,
    },
  );
}

/// SmartMapSurface Component
/// Renders OSM-based map with place pins, route, and filters
class SmartMapSurfaceComponent {
  static final definition = GenUiComponentDefinition(
    name: 'SmartMapSurface',
    description:
        'Interactive OSM-powered map showing places and route for the day',
    jsonSchema: {
      'type': 'object',
      'required': ['city', 'places'],
      'properties': {
        'city': {
          'type': 'string',
          'description': 'City name for map centering',
        },
        'places': {
          'type': 'array',
          'description': 'Array of place locations to pin',
          'items': {
            'type': 'object',
            'properties': {
              'id': {'type': 'string'},
              'name': {'type': 'string'},
              'lat': {'type': 'number'},
              'lon': {'type': 'number'},
              'vibe': {'type': 'string'},
            },
          },
        },
        'route_type': {
          'type': 'string',
          'enum': ['linear', 'optimized', 'scenic'],
          'description': 'How to draw the route between places',
        },
        'show_clusters': {
          'type': 'boolean',
          'description': 'Show spatial proximity clustering',
        },
        'cache_tiles': {
          'type': 'boolean',
          'description': 'Pre-cache map tiles for offline use',
        },
      },
    },
    example: {
      'city': 'Paris',
      'places': [
        {
          'id': 'OSM_1',
          'name': 'Musée',
          'lat': 48.861111,
          'lon': 2.295556,
          'vibe': 'historic,cultural'
        },
        {
          'id': 'OSM_2',
          'name': 'Café',
          'lat': 48.866111,
          'lon': 2.335556,
          'vibe': 'local,cozy'
        },
      ],
      'route_type': 'optimized',
      'show_clusters': true,
      'cache_tiles': true,
    },
  );
}

/// RouteItinerary Component
/// Vertical timeline of days and places to visit
class RouteItineraryComponent {
  static final definition = GenUiComponentDefinition(
    name: 'RouteItinerary',
    description: 'Timeline-style itinerary showing days and place clusters',
    jsonSchema: {
      'type': 'object',
      'required': ['days'],
      'properties': {
        'days': {
          'type': 'array',
          'description': 'Array of day clusters',
          'items': {
            'type': 'object',
            'properties': {
              'day_number': {'type': 'integer'},
              'theme': {'type': 'string'},
              'places': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'id': {'type': 'string'},
                    'name': {'type': 'string'},
                    'time_slot': {'type': 'string'},
                  },
                },
              },
              'summary': {'type': 'string'},
            },
          },
        },
        'interactive': {
          'type': 'boolean',
          'description': 'Allow user interaction (reorder, edit)',
        },
      },
    },
    example: {
      'days': [
        {
          'day_number': 1,
          'theme': 'Heritage Deep Dive',
          'places': [
            {'id': 'OSM_1', 'name': 'Louvre', 'time_slot': '9am-12pm'},
            {'id': 'OSM_2', 'name': 'Musée', 'time_slot': '1pm-3pm'},
          ],
          'summary': 'Explore world-class museums and 18th-century landmarks',
        },
      ],
      'interactive': true,
    },
  );
}

/// DayClusterCard Component
/// Shows summary of a single day's cluster
class DayClusterCardComponent {
  static final definition = GenUiComponentDefinition(
    name: 'DayClusterCard',
    description: 'Card showing day theme, place count, and estimated travel',
    jsonSchema: {
      'type': 'object',
      'required': ['day', 'theme'],
      'properties': {
        'day': {
          'type': 'integer',
          'description': 'Day number',
        },
        'theme': {
          'type': 'string',
          'description': 'Day theme/vibe',
        },
        'place_count': {
          'type': 'integer',
          'description': 'Number of places in this day cluster',
        },
        'estimated_distance_km': {
          'type': 'number',
          'description': 'Total estimated walking/travel distance',
        },
        'best_time': {
          'type': 'string',
          'description': 'Suggested time slot (e.g., "9am-12pm")',
        },
        'highlights': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Key highlights for this day',
        },
      },
    },
    example: {
      'day': 1,
      'theme': 'Heritage & History',
      'place_count': 5,
      'estimated_distance_km': 3.2,
      'best_time': '9am-6pm',
      'highlights': ['Ancient ruins', 'Local markets', 'Street art alley'],
    },
  );
}

/// VibeSignatureDisplay Component
/// Shows a visual breakdown of a place's vibe signature
class VibeSignatureDisplayComponent {
  static final definition = GenUiComponentDefinition(
    name: 'VibeSignatureDisplay',
    description:
        'Visual breakdown of OSM tags into human-readable vibe categories',
    jsonSchema: {
      'type': 'object',
      'required': ['signature'],
      'properties': {
        'signature': {
          'type': 'string',
          'description': 'Compact signature to display',
        },
        'place_name': {
          'type': 'string',
          'description': 'Name of place for context',
        },
        'show_raw': {
          'type': 'boolean',
          'description': 'Show raw signature alongside human-readable version',
        },
      },
    },
    example: {
      'signature': 'h:c:20th;l:indie;a:a:culture;s:free;acc:wc:yes',
      'place_name': 'Local Art Gallery',
      'show_raw': false,
    },
  );
}

/// LLM System Instruction - Tell the LLM what it can do
const String genUiLlmSystemInstruction = '''You are a Travel Discovery AI Agent with the ability to render dynamic UIs.

AVAILABLE COMPONENTS:
You can emit the following GenUI components to render the user interface:

1. PlaceDiscoveryCard - Show individual places with vibes and images
2. SmartMapSurface - Render interactive map with place pins and routes
3. RouteItinerary - Show timeline of days and place clusters
4. DayClusterCard - Summarize a day's exploration theme
5. VibeSignatureDisplay - Show the vibe breakdown for a place

RULES:
- Only emit components that exist in the catalog
- Each component output must be valid JSON matching the schema
- Include "reason" fields to explain your choices
- Reference user vibes when ranking recommendations
- Prioritize hidden gems alongside popular attractions
- Use spatial clustering to create logical day itineraries

WORKFLOW:
When planning a trip:
1. Emit RouteItinerary showing the overall structure
2. For each day, emit DayClusterCard showing the theme
3. Emit SmartMapSurface with that day's places
4. For notable places, emit PlaceDiscoveryCard with reasoning

OUTPUT FORMAT:
Return a JSON object with structure:
{
  "components": [
    {
      "type": "ComponentName",
      "props": { ...component-specific props... },
      "metadata": { "reasoning": "...", "confidence": 0.95 }
    }
  ]
}

TRANSPARENCY:
- Always explain WHY you chose each place
- Reference vibe signatures when available
- Show your reasoning in the metadata field
''';
