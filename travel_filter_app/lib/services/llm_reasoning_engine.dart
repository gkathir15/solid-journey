import 'dart:convert';
import 'package:logging/logging.dart';
import 'semantic_discovery_engine.dart';
import 'discovery_orchestrator.dart';

/// LLM Reasoning Engine - The Brain of the Travel Agent
/// 
/// This engine orchestrates the entire flow:
/// 1. Receives user input + vibe preferences
/// 2. Calls tools (OSM discovery, spatial clustering)
/// 3. Analyzes results with LLM reasoning
/// 4. Generates GenUI component instructions
/// 5. Returns structured output for GenUI rendering
class LLMReasoningEngine {
  final _log = Logger('LLMReasoningEngine');
  final DiscoveryOrchestrator discoveryOrchestrator;

  LLMReasoningEngine({required this.discoveryOrchestrator});

  /// Main reasoning entry point
  Future<LLMPlanningResult> planTrip({
    required String country,
    required String city,
    required List<String> userVibes,
    required int durationDays,
  }) async {
    final startTime = DateTime.now();
    _log.info('🧠 LLM REASONING ENGINE: Planning trip');
    _log.info('━' * 70);
    _log.info('📍 Location: $city, $country');
    _log.info('🎨 Vibes: ${userVibes.join(", ")}');
    _log.info('📅 Duration: $durationDays days');
    _log.info('━' * 70);

    try {
      // STEP 1: Call OSM Discovery Tool
      _log.info('\n🔧 STEP 1: INVOKING OSM DISCOVERY TOOL');
      _log.info('─' * 70);
      final discoveredPlaces = await discoveryOrchestrator.orchestrate(
        city: city,
        country: country,
        userVibes: userVibes,
        context: 'Trip planning for $city',
      );

      _log.info('✅ Tool returned: ${discoveredPlaces.totalCount} places');
      _log.info(
          '   - Primary: ${discoveredPlaces.primaryRecommendations.length}');
      _log.info('   - Hidden gems: ${discoveredPlaces.hiddenGems.length}');

      // STEP 2: Analyze with LLM reasoning
      _log.info('\n🧠 STEP 2: LLM PATTERN ANALYSIS');
      _log.info('─' * 70);

      final patterns = await _analyzePatterns(
        places: discoveredPlaces,
        userVibes: userVibes,
        city: city,
      );

      _log.info('✅ Patterns identified:');
      for (final pattern in patterns) {
        _log.info('   - ${pattern['type']}: ${pattern['description']}');
      }

      // STEP 3: Spatial clustering for day itinerary
      _log.info('\n📍 STEP 3: SPATIAL CLUSTERING & DAY PLANNING');
      _log.info('─' * 70);

      final dayClusters = await _createDayClusters(
        places: discoveredPlaces,
        durationDays: durationDays,
      );

      _log.info('✅ Created $durationDays day clusters:');
      for (int i = 0; i < dayClusters.length; i++) {
        final cluster = dayClusters[i];
        _log.info(
            '   Day ${i + 1}: ${cluster['places'].length} places, theme: ${cluster['theme']}');
      }

      // STEP 4: Generate GenUI instructions
      _log.info('\n🎨 STEP 4: GENERATING GenUI COMPONENT INSTRUCTIONS');
      _log.info('─' * 70);

      final genUIInstructions = _generateGenUIInstructions(
        dayClusters: dayClusters,
        patterns: patterns,
        city: city,
      );

      _log.info('✅ Generated GenUI instructions for:');
      for (final instr in genUIInstructions) {
        _log.info('   - ${instr['component']}: ${instr['action']}');
      }

      // STEP 5: Compile final result
      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      _log.info('\n✨ REASONING COMPLETE in ${elapsedMs}ms');
      _log.info('━' * 70);

      return LLMPlanningResult(
        city: city,
        country: country,
        userVibes: userVibes,
        durationDays: durationDays,
        discoveredPlaces: discoveredPlaces,
        patterns: patterns,
        dayClusters: dayClusters,
        genUIInstructions: genUIInstructions,
        elapsedMs: elapsedMs,
      );
    } catch (e, stack) {
      _log.severe('❌ LLM reasoning failed: $e');
      _log.severe('Stack: $stack');
      rethrow;
    }
  }

  /// Analyze patterns in discovered places
  Future<List<Map<String, dynamic>>> _analyzePatterns({
    required dynamic places,
    required List<String> userVibes,
    required String city,
  }) async {
    // In production, this would call Gemini Nano
    // For now, we simulate LLM pattern recognition

    final patterns = <Map<String, dynamic>>[];

    // Pattern 1: Heritage concentration
    if (userVibes.contains('historic') || userVibes.contains('cultural')) {
      patterns.add({
        'type': 'Heritage Cluster',
        'description': 'High concentration of 18th-19th century sites',
        'vibes': ['historic', 'cultural', 'educational'],
        'confidence': 0.95,
      });
    }

    // Pattern 2: Local flavor
    if (userVibes.contains('local') || userVibes.contains('off_the_beaten_path')) {
      patterns.add({
        'type': 'Local Gems',
        'description': 'Independent, non-chain establishments with authentic character',
        'vibes': ['local', 'authentic', 'off_the_beaten_path'],
        'confidence': 0.92,
      });
    }

    // Pattern 3: Nightlife/Social
    if (userVibes.contains('nightlife') || userVibes.contains('cafe_culture')) {
      patterns.add({
        'type': 'Social Hotspots',
        'description': 'Cafes, bars, and social venues clustered for easy exploration',
        'vibes': ['nightlife', 'cafe_culture', 'social'],
        'confidence': 0.88,
      });
    }

    // Pattern 4: Nature escapes
    if (userVibes.contains('nature') || userVibes.contains('serene')) {
      patterns.add({
        'type': 'Nature Escapes',
        'description': 'Green spaces and natural viewpoints for peaceful breaks',
        'vibes': ['nature', 'serene', 'quiet'],
        'confidence': 0.90,
      });
    }

    _log.info('📊 Identified ${patterns.length} major patterns');
    return patterns;
  }

  /// Create day clusters based on spatial proximity
  Future<List<Map<String, dynamic>>> _createDayClusters({
    required dynamic places,
    required int durationDays,
  }) async {
    final clusters = <Map<String, dynamic>>[];

    // Simulate spatial clustering (in production, use actual distance matrix)
    final primaryPlaces = places.primaryRecommendations ?? [];
    final hiddenGems = places.hiddenGems ?? [];
    final allPlaces = [...primaryPlaces, ...hiddenGems];

    // Distribute places across days
    final placesPerDay = (allPlaces.length / durationDays).ceil();

    for (int day = 0; day < durationDays; day++) {
      final start = day * placesPerDay;
      final end = (start + placesPerDay).clamp(0, allPlaces.length);

      final dayPlaces =
          allPlaces.sublist(start, end).cast<Map<String, dynamic>>();

      clusters.add({
        'day': day + 1,
        'theme': _generateDayTheme(dayPlaces, day),
        'places': dayPlaces,
        'estimatedDistance': _calculateClusterDistance(dayPlaces),
        'bestTime': _suggestBestTime(dayPlaces, day),
      });
    }

    return clusters;
  }

  /// Generate a theme for each day
  String _generateDayTheme(List<Map<String, dynamic>> dayPlaces, int dayIndex) {
    if (dayPlaces.isEmpty) return 'Exploration Day';

    final themes = [
      'Heritage Deep Dive',
      'Local Discoveries',
      'Cultural Immersion',
      'Hidden Gems',
      'Community Vibes',
    ];

    return themes[dayIndex % themes.length];
  }

  /// Calculate approximate distance for a cluster
  double _calculateClusterDistance(List<Map<String, dynamic>> places) {
    // Simplified: assume avg 1km between stops
    return (places.length * 0.5) + 2.0; // km
  }

  /// Suggest best time to visit
  String _suggestBestTime(List<Map<String, dynamic>> places, int dayIndex) {
    if (dayIndex == 0) return 'Morning 9am-12pm';
    if (dayIndex % 2 == 0) return 'Afternoon 2pm-6pm';
    return 'Evening 6pm-9pm';
  }

  /// Generate GenUI component instructions
  List<Map<String, dynamic>> _generateGenUIInstructions({
    required List<Map<String, dynamic>> dayClusters,
    required List<Map<String, dynamic>> patterns,
    required String city,
  }) {
    final instructions = <Map<String, dynamic>>[];

    // 1. Render map surface
    instructions.add({
      'component': 'SmartMapSurface',
      'action': 'Initialize',
      'data': {
        'city': city,
        'centerOnFirstPlace': true,
        'showAllPlaces': true,
      },
    });

    // 2. Render day itinerary
    instructions.add({
      'component': 'RouteItinerary',
      'action': 'Render',
      'data': {
        'dayClusters': dayClusters,
        'scrollable': true,
      },
    });

    // 3. Render place discovery cards
    for (final cluster in dayClusters) {
      instructions.add({
        'component': 'DayClusterCard',
        'action': 'Add',
        'data': {
          'day': cluster['day'],
          'theme': cluster['theme'],
          'placeCount': (cluster['places'] as List).length,
          'distance': cluster['estimatedDistance'],
        },
      });
    }

    return instructions;
  }
}

/// Result of LLM reasoning - Ready for GenUI
class LLMPlanningResult {
  final String city;
  final String country;
  final List<String> userVibes;
  final int durationDays;
  final dynamic discoveredPlaces;
  final List<Map<String, dynamic>> patterns;
  final List<Map<String, dynamic>> dayClusters;
  final List<Map<String, dynamic>> genUIInstructions;
  final int elapsedMs;

  LLMPlanningResult({
    required this.city,
    required this.country,
    required this.userVibes,
    required this.durationDays,
    required this.discoveredPlaces,
    required this.patterns,
    required this.dayClusters,
    required this.genUIInstructions,
    required this.elapsedMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'country': country,
      'userVibes': userVibes,
      'durationDays': durationDays,
      'discoveredPlaces': discoveredPlaces,
      'patterns': patterns,
      'dayClusters': dayClusters,
      'genUIInstructions': genUIInstructions,
      'elapsedMs': elapsedMs,
    };
  }
}
