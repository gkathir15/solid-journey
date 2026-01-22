import 'dart:convert';
import 'package:logging/logging.dart';
import 'llm_reasoning_engine.dart';
import 'genui_component_catalog.dart';

/// GenUI Orchestration Layer
/// 
/// Connects LLM output to actual widget rendering.
/// Implements the A2UI protocol for dynamic component generation.
class GenUiOrchestrationLayer {
  final _log = Logger('GenUiOrchestration');

  /// Process LLM reasoning result and generate GenUI component instructions
  Future<GenUiSurfaceUpdate> orchestrateUiFromLLMResult({
    required LLMPlanningResult llmResult,
  }) async {
    _log.info('🎨 GenUI ORCHESTRATION LAYER');
    _log.info('━' * 70);
    _log.info('Processing LLM result for ${llmResult.city}');
    _log.info('Duration: ${llmResult.durationDays} days');

    try {
      // STEP 1: Extract components from LLM instructions
      _log.info('\n🔧 STEP 1: EXTRACTING COMPONENTS FROM LLM OUTPUT');
      _log.info('─' * 70);

      final components = <GenUiComponentSpec>[];

      // Generate RouteItinerary as the main structure
      final itineraryComponent = _buildRouteItineraryComponent(llmResult);
      components.add(itineraryComponent);
      _log.info('✅ Added RouteItinerary component');

      // Generate DayClusterCard for each day
      _log.info('\n📅 STEP 2: GENERATING DAY CLUSTER COMPONENTS');
      _log.info('─' * 70);

      for (final dayCluster in llmResult.dayClusters) {
        final dayCard = _buildDayClusterCardComponent(dayCluster);
        components.add(dayCard);
        _log.info('✅ Added DayClusterCard for Day ${dayCluster['day']}');
      }

      // Generate SmartMapSurface
      _log.info('\n🗺️  STEP 3: GENERATING MAP COMPONENT');
      _log.info('─' * 70);

      final mapComponent = _buildSmartMapSurfaceComponent(llmResult);
      components.add(mapComponent);
      _log.info('✅ Added SmartMapSurface component');

      // Generate PlaceDiscoveryCards for top recommendations
      _log.info('\n🎯 STEP 4: GENERATING PLACE DISCOVERY CARDS');
      _log.info('─' * 70);

      final placeCards = _buildPlaceDiscoveryCardsComponent(llmResult);
      components.addAll(placeCards);
      _log.info('✅ Added ${placeCards.length} PlaceDiscoveryCard components');

      // STEP 2: Validate all components
      _log.info('\n✔️ STEP 5: VALIDATING COMPONENT SCHEMAS');
      _log.info('─' * 70);

      final validationResults = <String, bool>{};
      for (final component in components) {
        final isValid = GenUiComponentCatalog.validateComponent(
          component.type,
          component.props,
        );
        validationResults[component.type] = isValid;
        _log.fine(
            '  ${isValid ? "✅" : "❌"} ${component.type}: ${isValid ? "Valid" : "Invalid"}');
      }

      final allValid = validationResults.values.every((v) => v);
      if (!allValid) {
        _log.warning('⚠️  Some components failed validation');
      } else {
        _log.info('✅ All ${components.length} components validated');
      }

      // STEP 3: Create surface update
      _log.info('\n🎨 STEP 6: CREATING SURFACE UPDATE');
      _log.info('─' * 70);

      final surfaceUpdate = GenUiSurfaceUpdate(
        components: components,
        metadata: {
          'city': llmResult.city,
          'country': llmResult.country,
          'duration': llmResult.durationDays,
          'userVibes': llmResult.userVibes,
          'totalPlaces': llmResult.discoveredPlaces.totalCount,
          'llmElapsedMs': llmResult.elapsedMs,
          'generatedAt': DateTime.now().toIso8601String(),
        },
      );

      _log.info('✅ Surface update ready with ${components.length} components');
      _log.info('━' * 70);

      return surfaceUpdate;
    } catch (e, stack) {
      _log.severe('❌ GenUI orchestration failed: $e');
      _log.severe('Stack: $stack');
      rethrow;
    }
  }

  /// Build RouteItinerary component
  GenUiComponentSpec _buildRouteItineraryComponent(LLMPlanningResult result) {
    final days = result.dayClusters.map((cluster) {
      return {
        'day_number': cluster['day'] as int,
        'theme': cluster['theme'] as String,
        'places': (cluster['places'] as List)
            .map((p) {
              final place = p as Map<String, dynamic>;
              return {
                'id': place['id'] ?? 'unknown',
                'name': place['name'] ?? 'Unknown Place',
                'time_slot': cluster['bestTime'] ?? '9am-5pm',
              };
            })
            .toList(),
        'summary':
            'Explore ${(cluster['places'] as List).length} amazing places themed around "${cluster['theme']}"',
      };
    }).toList();

    return GenUiComponentSpec(
      type: 'RouteItinerary',
      props: {
        'days': days,
        'interactive': true,
      },
      metadata: {
        'reasoning': 'Master itinerary for ${result.durationDays}-day trip',
        'confidence': 0.99,
      },
    );
  }

  /// Build DayClusterCard component
  GenUiComponentSpec _buildDayClusterCardComponent(
      Map<String, dynamic> dayCluster) {
    final places = (dayCluster['places'] as List? ?? []).cast<Map<String, dynamic>>();

    return GenUiComponentSpec(
      type: 'DayClusterCard',
      props: {
        'day': dayCluster['day'] as int,
        'theme': dayCluster['theme'] as String,
        'place_count': places.length,
        'estimated_distance_km': (dayCluster['estimatedDistance'] as num?)?.toDouble() ?? 0.0,
        'best_time': dayCluster['bestTime'] as String,
        'highlights': places
            .take(3)
            .map((p) => p['name'] ?? 'Unknown')
            .toList()
            .cast<String>(),
      },
      metadata: {
        'reasoning': 'Day ${dayCluster['day']} focuses on: ${dayCluster['theme']}',
        'confidence': 0.92,
      },
    );
  }

  /// Build SmartMapSurface component
  GenUiComponentSpec _buildSmartMapSurfaceComponent(LLMPlanningResult result) {
    final allPlaces = <Map<String, dynamic>>[];

    // Collect all places from all day clusters
    for (final cluster in result.dayClusters) {
      final places = cluster['places'] as List? ?? [];
      for (final place in places) {
        final p = place as Map<String, dynamic>;
        allPlaces.add({
          'id': p['id'] ?? 'unknown',
          'name': p['name'] ?? 'Unknown',
          'lat': (p['location'] as Map?)?['lat'] as num? ?? 0,
          'lon': (p['location'] as Map?)?['lon'] as num? ?? 0,
          'vibe': p['signature'] ?? 'local',
        });
      }
    }

    return GenUiComponentSpec(
      type: 'SmartMapSurface',
      props: {
        'city': result.city,
        'places': allPlaces,
        'route_type': 'optimized',
        'show_clusters': true,
        'cache_tiles': true,
      },
      metadata: {
        'reasoning': 'Interactive map showing all ${allPlaces.length} discovered places',
        'confidence': 0.95,
      },
    );
  }

  /// Build PlaceDiscoveryCard components
  List<GenUiComponentSpec> _buildPlaceDiscoveryCardsComponent(
      LLMPlanningResult result) {
    final cards = <GenUiComponentSpec>[];

    // Add primary recommendations
    final primaryPlaces =
        result.discoveredPlaces.primaryRecommendations ?? [];
    for (final place in primaryPlaces.take(5)) {
      final p = place as Map<String, dynamic>;
      cards.add(GenUiComponentSpec(
        type: 'PlaceDiscoveryCard',
        props: {
          'id': p['id'] ?? 'unknown',
          'name': p['name'] ?? 'Unknown',
          'vibe_signature': p['signature'] ?? 'local',
          'location': p['location'] ??
              {
                'lat': 0,
                'lon': 0,
              },
          'reason': p['reason'] ??
              'Great match for your travel vibe',
          'score': (p['score'] as num?)?.toDouble() ?? 0.8,
        },
        metadata: {
          'type': 'primary',
          'confidence': (p['score'] as num?)?.toDouble() ?? 0.8,
        },
      ));
    }

    // Add hidden gems
    final hiddenGems = result.discoveredPlaces.hiddenGems ?? [];
    for (final place in hiddenGems.take(3)) {
      final p = place as Map<String, dynamic>;
      cards.add(GenUiComponentSpec(
        type: 'PlaceDiscoveryCard',
        props: {
          'id': p['id'] ?? 'unknown',
          'name': p['name'] ?? 'Unknown',
          'vibe_signature': p['signature'] ?? 'local',
          'location': p['location'] ??
              {
                'lat': 0,
                'lon': 0,
              },
          'reason': p['reason'] ??
              'Hidden gem that matches your vibe',
          'score': (p['score'] as num?)?.toDouble() ?? 0.75,
        },
        metadata: {
          'type': 'hidden_gem',
          'confidence': (p['score'] as num?)?.toDouble() ?? 0.75,
        },
      ));
    }

    return cards;
  }
}

/// Specification for a single GenUI component
class GenUiComponentSpec {
  final String type;
  final Map<String, dynamic> props;
  final Map<String, dynamic> metadata;

  GenUiComponentSpec({
    required this.type,
    required this.props,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'props': props,
      'metadata': metadata,
    };
  }
}

/// Complete GenUI Surface Update - Ready to render
class GenUiSurfaceUpdate {
  final List<GenUiComponentSpec> components;
  final Map<String, dynamic> metadata;

  GenUiSurfaceUpdate({
    required this.components,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'components': components.map((c) => c.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// Get components by type
  List<GenUiComponentSpec> getComponentsByType(String type) {
    return components.where((c) => c.type == type).toList();
  }

  /// Get total component count
  int get componentCount => components.length;

  /// Get component types used
  Set<String> get componentTypes =>
      components.map((c) => c.type).toSet();
}
