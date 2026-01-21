import 'package:logging/logging.dart';
import 'universal_tag_harvester.dart';
import 'semantic_discovery_engine.dart';
import 'llm_discovery_reasoner.dart';

/// Discovery Orchestrator - Coordinates the entire discovery pipeline
/// 
/// Pipeline:
/// 1. Harvest → Extract all OSM tags
/// 2. Process → Create vibe signatures
/// 3. Reason → LLM analyzes signatures for patterns
/// 4. Deliver → Return curated recommendations
class DiscoveryOrchestrator {
  final _log = Logger('DiscoveryOrchestrator');
  
  final harvester = UniversalTagHarvester();
  final discoveryEngine = SemanticDiscoveryEngine();
  final reasoner = LLMDiscoveryReasoner();

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
