import 'package:logging/logging.dart';
import 'universal_tag_harvester.dart';
import 'semantic_discovery_engine.dart';
import 'llm_discovery_reasoner.dart';
import 'spatial_clustering_service.dart';

/// Discovery Orchestrator - Coordinates the entire discovery pipeline
/// 
/// Pipeline:
/// 1. Harvest → Extract all OSM tags
/// 2. Process → Create vibe signatures
/// 3. Reason → LLM analyzes signatures for patterns
/// 4. Cluster → Group into day-based itineraries
/// 5. Deliver → Return curated recommendations with GenUI format
class DiscoveryOrchestrator {
  final _log = Logger('DiscoveryOrchestrator');
  
  final harvester = UniversalTagHarvester();
  final discoveryEngine = SemanticDiscoveryEngine();
  final reasoner = LLMDiscoveryReasoner();
  final clusteringService = SpatialClusteringService();

  /// Main discovery pipeline
  Future<DiscoveryOutput> discover({
    required String city,
    required List<String> categories,
    required String userVibe,
    required String userContext,
  }) async {
    _log.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log.info('🔍 DISCOVERY ORCHESTRATOR STARTING');
    _log.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    _log.info('City: $city');
    _log.info('Categories: $categories');
    _log.info('User Vibe: $userVibe');
    _log.info('Context: $userContext');
    _log.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // PHASE 1: HARVEST
      _log.info('');
      _log.info('PHASE 1: HARVESTING OSM METADATA');
      _log.info('─────────────────────────────────────────────');
      final rawElements = await harvester.harvestAllTags(
        city: city,
        primaryCategories: categories,
      );
      _log.info('✅ Harvested ${rawElements.length} elements');

      // PHASE 2: PROCESS
      _log.info('');
      _log.info('PHASE 2: PROCESSING INTO VIBE SIGNATURES');
      _log.info('─────────────────────────────────────────────');
      final signatures = <VibeSignature>[];
      for (final element in rawElements) {
        final signature = discoveryEngine.processElement(element);
        signatures.add(signature);
      }
      _log.info('✅ Created ${signatures.length} vibe signatures');
      _log.info('');
      
      // Log sample signatures
      _log.info('SAMPLE SIGNATURES:');
      for (final sig in signatures.take(5)) {
        _log.info('  ${sig.name}: ${sig.compactSignature}');
      }

      // PHASE 3: REASON
      _log.info('');
      _log.info('PHASE 3: LLM DISCOVERY REASONING');
      _log.info('─────────────────────────────────────────────');
      final discoveryResult = await reasoner.discoverAttractionsForVibe(
        userVibe: userVibe,
        userContext: userContext,
        attractions: signatures,
      );
      _log.info('✅ Found ${discoveryResult.primaryRecommendations.length} '
          'primary + ${discoveryResult.hiddenGems.length} hidden gems');

      // PHASE 4: DELIVER
      _log.info('');
      _log.info('PHASE 4: FINAL DISCOVERY OUTPUT');
      _log.info('─────────────────────────────────────────────');

      final output = DiscoveryOutput(
        city: city,
        userVibe: userVibe,
        totalAnalyzed: signatures.length,
        discoveryResult: discoveryResult,
        allSignatures: signatures,
      );

      _log.info('✅ DISCOVERY COMPLETE');
      _log.info('');
      _log.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _log.info('FINAL RESULTS:');
      _log.info('  Total Analyzed: ${output.totalAnalyzed}');
      _log.info('  Primary Recommendations: ${output.discoveryResult.primaryRecommendations.length}');
      _log.info('  Hidden Gems: ${output.discoveryResult.hiddenGems.length}');
      _log.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return output;
    } catch (e) {
      _log.severe('❌ Discovery failed: $e');
      rethrow;
    }
  }

  /// GenUI-integrated orchestration - Used by the UI layer
  /// Returns a complete itinerary ready for GenUI rendering
  Future<Map<String, dynamic>> orchestrate({
    required String city,
    required String country,
    required List<String> selectedVibes,
    int durationDays = 3,
  }) async {
    _log.info('🎯 ORCHESTRATE: Planning ${country}/${city} - Vibes: $selectedVibes');

    try {
      // Fetch all categories as default
      final categories = ['tourism', 'amenity', 'leisure'];
      
      // Run discovery pipeline
      final output = await discover(
        city: city,
        categories: categories,
        userVibe: selectedVibes.join(', '),
        userContext: 'Trip planning for $country',
      );

      // Prepare attractions for clustering
      final attractionsList = output.discoveryResult.primaryRecommendations
          .map((rec) {
            return {
              'name': rec['name'] ?? 'Unknown',
              'lat': rec['lat'] ?? 0.0,
              'lon': rec['lon'] ?? 0.0,
              'category': rec['category'] ?? 'other',
              'vibe': (rec['vibe'] as List<dynamic>? ?? []).cast<String>(),
              'rating': rec['rating'] ?? 3.0,
              'description': rec['description'] ?? '',
            };
          })
          .toList();

      // Create day clusters
      _log.info('Creating ${durationDays}-day itinerary...');
      final dayClusters = await clusteringService.createDayClustersByCount(
        attractionsList,
        durationDays: durationDays,
      );

      // Build response for GenUI
      final days = dayClusters.asMap().entries.map((e) {
        final cluster = e.value;
        
        return {
          'dayNumber': cluster.dayNumber,
          'theme': _generateDayTheme(cluster, selectedVibes),
          'places': cluster.attractions
              .asMap()
              .entries
              .map((pe) {
                final place = pe.value;
                return {
                  'name': place['name'] ?? 'Unknown',
                  'order': pe.key + 1,
                  'vibe': place['vibe'] ?? [],
                  'reason': _generatePlaceReason(place, selectedVibes),
                };
              })
              .toList(),
          'totalDistance': cluster.distanceCovered,
        };
      }).toList();

      final itinerary = {
        'days': days,
        'tripSummary': _generateTripSummary(city, country, selectedVibes, days.length),
      };

      _log.info('✅ Itinerary generated: ${days.length} days');

      return {
        'success': true,
        'itinerary': itinerary,
        'metadata': {
          'city': city,
          'country': country,
          'vibes': selectedVibes,
          'duration': durationDays,
          'attractionsAnalyzed': output.totalAnalyzed,
        },
      };
    } catch (e) {
      _log.severe('❌ Orchestration failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  String _generateDayTheme(DayCluster cluster, List<String> vibes) {
    if (vibes.contains('nature')) return 'Nature Exploration';
    if (vibes.contains('historic')) return 'Historical Journey';
    if (vibes.contains('vibrant')) return 'Urban Adventure';
    if (vibes.contains('quiet')) return 'Peaceful Discovery';
    return 'Local Exploration';
  }

  String _generatePlaceReason(Map<String, dynamic> place, List<String> vibes) {
    final category = place['category'] ?? 'attraction';
    final placeVibes = (place['vibe'] as List<dynamic>? ?? []).cast<String>();
    
    final matchedVibes = vibes
        .where((v) => placeVibes.contains(v))
        .toList();
    
    if (matchedVibes.isNotEmpty) {
      return 'Perfect match for your "${matchedVibes.join(', ')}" preference';
    }
    return 'Great $category matching your travel style';
  }

  String _generateTripSummary(String city, String country, List<String> vibes, int days) {
    return 'Your $days-day journey through ${city}, $country focused on: ${vibes.join(", ")}. '
        'This itinerary highlights local gems, cultural treasures, and hidden attractions.';
  }
}

/// Complete output from discovery pipeline
class DiscoveryOutput {
  final String city;
  final String userVibe;
  final int totalAnalyzed;
  final DiscoveryResult discoveryResult;
  final List<VibeSignature> allSignatures;

  DiscoveryOutput({
    required this.city,
    required this.userVibe,
    required this.totalAnalyzed,
    required this.discoveryResult,
    required this.allSignatures,
  });

  /// Get primary recommendations as LLM format
  List<Map<String, dynamic>> getPrimaryLLMFormat() {
    return discoveryResult.primaryRecommendations;
  }

  /// Get all signatures as LLM format (for agent reasoning)
  List<Map<String, dynamic>> getAllSignaturesLLMFormat() {
    return allSignatures.map((sig) => sig.toLLMFormat()).toList();
  }

  /// Export for use in next phase (clustering, etc.)
  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'userVibe': userVibe,
      'totalAnalyzed': totalAnalyzed,
      'discoveryResults': discoveryResult.toJson(),
      'allSignatures': allSignatures.map((s) => s.toFullFormat()).toList(),
    };
  }
}
