import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config.dart';
import 'a2ui_message_processor.dart';
import '../services/discovery_orchestrator.dart';

/// LLM Reasoning Engine: Coordinates the entire AI-first planning flow
/// - Takes user preferences and OSM data
/// - Uses local Gemini Nano to reason about vibe patterns
/// - Generates A2UI messages for dynamic UI rendering
/// - Handles tool calling and spatial reasoning
class LLMReasoningEngine {
  final DiscoveryOrchestrator discoveryOrchestrator;
  final A2uiMessageProcessor messageProcessor;

  LLMReasoningEngine({
    required this.discoveryOrchestrator,
    required this.messageProcessor,
  });

  /// Main entry point: Plan a trip end-to-end
  Future<Map<String, dynamic>> planTrip({
    required String city,
    required String country,
    required List<String> userVibes,
    required int tripDays,
  }) async {
    try {
      debugPrint('[LLM Engine] 🚀 Starting trip planning');
      debugPrint('[LLM Engine] City: $city, Country: $country');
      debugPrint('[LLM Engine] Vibes: $userVibes, Days: $tripDays');

      // STEP 1: Discover places with vibe signatures
      debugPrint('[LLM Engine] ─── STEP 1: DISCOVERING PLACES ───');
      final discoveredPlaces = await _discoverPlaces(city, country, userVibes);
      debugPrint(
          '[LLM Engine] ✅ Discovered ${discoveredPlaces.length} unique places');

      if (discoveredPlaces.isEmpty) {
        throw Exception('No places discovered for the given criteria');
      }

      // STEP 2: Use LLM to analyze vibe patterns and group into day clusters
      debugPrint('[LLM Engine] ─── STEP 2: LLM REASONING ───');
      final clusters = await _reasonAboutClusters(
        places: discoveredPlaces,
        userVibes: userVibes,
        tripDays: tripDays,
      );

      // STEP 3: Generate A2UI messages for rendering
      debugPrint('[LLM Engine] ─── STEP 3: GENERATING UI ───');
      final uiMessages = _generateUIMessages(clusters, userVibes, discoveredPlaces);

      // STEP 4: Process messages through the message processor
      debugPrint('[LLM Engine] ─── STEP 4: RENDERING UI ───');
      await messageProcessor.processLLMMessage(jsonEncode(uiMessages));

      debugPrint('[LLM Engine] ✅ Trip planning complete');

      return {
        'success': true,
        'places': discoveredPlaces,
        'clusters': clusters,
        'uiMessages': uiMessages,
      };
    } catch (e) {
      debugPrint('[LLM Engine] ❌ Error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// STEP 1: Discover places using the Discovery Orchestrator
  Future<List<Map<String, dynamic>>> _discoverPlaces(
    String city,
    String country,
    List<String> userVibes,
  ) async {
    try {
      debugPrint('[LLM Engine] 🔍 Querying OSM for places...');

      // Call discovery orchestrator
      final result = await discoveryOrchestrator.orchestrate(
        city: city,
        country: country,
        selectedVibes: userVibes,
        durationDays: tripDays,
      );

      debugPrint('[LLM Engine] Discovery result: $result');

      // Extract places from discovery result
      final places = (result?['places'] as List<dynamic>? ?? [])
          .map((p) => {
                'name': p['name'] ?? 'Unknown',
                'lat': p['lat'],
                'lon': p['lon'],
                'vibes': (p['vibes'] as List<dynamic>? ?? []).cast<String>(),
                'signature': p['signature'] ?? '',
                'osmId': p['osmId'] ?? '',
                'tags': p['tags'] ?? {},
              })
          .toList();

      debugPrint('[LLM Engine] ✅ Discovered ${places.length} places');
      return places.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[LLM Engine] ❌ Discovery error: $e');
      rethrow;
    }
  }

  /// STEP 2: Use LLM to reason about spatial clustering and day grouping
  Future<List<Map<String, dynamic>>> _reasonAboutClusters({
    required List<Map<String, dynamic>> places,
    required List<String> userVibes,
    required int tripDays,
  }) async {
    try {
      debugPrint('[LLM Engine] 🤔 LLM reasoning about clusters...');
      debugPrint('[LLM Engine] Input: ${places.length} places for $tripDays days');

      // Build reasoning prompt
      final prompt = _buildReasoningPrompt(places, userVibes, tripDays);
      debugPrint('[LLM Engine] Prompt:\n$prompt');

      // TODO: Call actual LLM here (Gemini Nano)
      // For now, use mock reasoning
      final clusters = _mockLLMReasoning(places, tripDays);

      debugPrint('[LLM Engine] ✅ Generated ${clusters.length} day clusters');
      return clusters;
    } catch (e) {
      debugPrint('[LLM Engine] ❌ Reasoning error: $e');
      rethrow;
    }
  }

  /// Build the reasoning prompt for the LLM
  String _buildReasoningPrompt(
    List<Map<String, dynamic>> places,
    List<String> userVibes,
    int tripDays,
  ) {
    final placesDescription = places
        .take(10)
        .map((p) => '- ${p['name']}: vibes=[${p['vibes'].join(', ')}]')
        .join('\n');

    return '''
You are a Spatial Travel Planner AI. Your task is to analyze discovered places and create optimal day clusters.

USER PREFERENCES:
- Vibes: ${userVibes.join(', ')}
- Trip Duration: $tripDays days

DISCOVERED PLACES (showing first 10):
$placesDescription

REASONING INSTRUCTIONS:
1. Group places that are within 1km of each other
2. Each day should have 3-5 places maximum
3. Prioritize places that match user vibes
4. Create thematic days (e.g., "Historic Quarter", "Foodie Adventure")
5. Balance between major attractions and hidden gems

OUTPUT FORMAT:
Respond with a JSON object containing day clusters as follows:
{
  "clusters": [
    {
      "dayNumber": 1,
      "theme": "Historic Heart",
      "places": [
        {"name": "Place A", "order": 1, "reason": "Why chosen"}
      ],
      "reasoning": "Why these places together"
    }
  ],
  "reasoning": "Overall trip narrative"
}
''';
  }

  /// Mock LLM reasoning (for development/testing)
  List<Map<String, dynamic>> _mockLLMReasoning(
    List<Map<String, dynamic>> places,
    int tripDays,
  ) {
    debugPrint('[LLM Engine] Using mock LLM reasoning');

    final clusters = <Map<String, dynamic>>[];
    final placesPerDay = (places.length / tripDays).ceil();

    for (int day = 1; day <= tripDays && places.isNotEmpty; day++) {
      final dayPlaces = places
          .skip((day - 1) * placesPerDay)
          .take(placesPerDay)
          .toList();

      if (dayPlaces.isEmpty) break;

      final theme = _generateDayTheme(dayPlaces, day);

      clusters.add({
        'dayNumber': day,
        'theme': theme,
        'places': dayPlaces
            .asMap()
            .entries
            .map((e) => {
                  'name': e.value['name'],
                  'order': e.key + 1,
                  'vibes': e.value['vibes'],
                  'reason':
                      'Matches your ${e.value['vibes'].join(", ")} preferences',
                })
            .toList(),
        'totalDistance': null,
        'reasoning': 'Thematic day focused on $theme',
      });
    }

    return clusters;
  }

  /// Generate a thematic name for a day based on places
  String _generateDayTheme(List<Map<String, dynamic>> places, int dayNumber) {
    final themes = [
      'Historic Heart',
      'Foodie Adventure',
      'Nature & Serenity',
      'Urban Edge',
      'Cultural Immersion',
      'Hidden Gems',
      'Adventure Day',
      'Relaxation & Vibes',
    ];

    if (dayNumber <= themes.length) {
      return themes[dayNumber - 1];
    }
    return 'Exploration Day $dayNumber';
  }

  /// STEP 3: Generate A2UI messages for rendering
  Map<String, dynamic> _generateUIMessages(
    List<Map<String, dynamic>> clusters,
    List<String> userVibes,
    List<Map<String, dynamic>> places,
  ) {
    final messages = <Map<String, dynamic>>[];

    // Message 1: VibeSelector confirmation
    messages.add({
      'type': 'component_render',
      'componentType': 'VibeSelector',
      'data': {
        'selectedVibes': userVibes,
        'availableVibes': Config.commonVibes,
      },
    });

    // Message 2: SmartMapSurface with all places
    messages.add({
      'type': 'component_render',
      'componentType': 'SmartMapSurface',
      'data': {
        'places': places
            .map((p) => {
                  'name': p['name'],
                  'lat': p['lat'],
                  'lon': p['lon'],
                  'vibe': p['vibes'],
                })
            .toList(),
        'vibeFilter': userVibes,
        'zoomLevel': 13,
      },
    });

    // Message 3: RouteItinerary with day clusters
    messages.add({
      'type': 'component_render',
      'componentType': 'RouteItinerary',
      'data': {
        'days': clusters,
        'tripSummary': _generateTripSummary(clusters, userVibes),
      },
    });

    return {'messages': messages};
  }

  /// Generate a narrative summary of the trip
  String _generateTripSummary(
    List<Map<String, dynamic>> clusters,
    List<String> userVibes,
  ) {
    final dayCount = clusters.length;
    final vibeStr = userVibes.take(3).join(', ');

    return 'Your ${dayCount}-day ${vibeStr} adventure awaits! '
        'Each day is carefully curated to match your travel style.';
  }
}
