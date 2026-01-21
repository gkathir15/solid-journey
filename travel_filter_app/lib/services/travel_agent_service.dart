import 'dart:convert';
import 'package:logging/logging.dart';
import 'osm_service.dart';
import 'spatial_clustering_service.dart';

/// Travel Agent Service - The LLM-powered decision maker
/// 
/// This service represents the AI agent that:
/// 1. Receives user requirements (city, categories, duration)
/// 2. Calls OSM tools to fetch real data
/// 3. Analyzes spatial relationships
/// 4. Groups attractions into day clusters
/// 5. Returns optimized itinerary
class TravelAgentService {
  final _log = Logger('TravelAgent');
  final osmService = OSMService();
  final clusteringService = SpatialClusteringService();

  /// Main agent orchestration method
  Future<TravelItinerary> planTrip({
    required String city,
    required List<String> categories,
    required int durationDays,
    required String userVibe,
  }) async {
    _log.info('🎯 TRAVEL AGENT: Planning trip to $city');
    _log.info('User Vibe: $userVibe');
    _log.info('Duration: $durationDays days');
    _log.info('Categories: $categories');

    try {
      // Step 1: TOOL CALL - Fetch attractions
      _log.info('🔧 TOOL CALL: fetchAttractions($city, $categories)');
      final attractions = await osmService.fetchAttractions(
        city: city,
        categories: categories,
      );

      if (attractions.isEmpty) {
        throw Exception('No attractions found for $city');
      }

      _log.info('✅ Tool returned ${attractions.length} attractions');

      // Step 2: TOOL CALL - Calculate distance matrix
      _log.info('🔧 TOOL CALL: calculateDistanceMatrix()');
      final distanceMatrix = await osmService.calculateDistanceMatrix(attractions);
      _log.info('✅ Distance matrix computed');

      // Step 3: REASONING - Create spatial clusters
      _log.info('🧠 REASONING: Creating spatial clusters');
      final dayClusters = await clusteringService.createDayClusters(
        attractions,
        distanceMatrix,
      );

      // Step 4: REASONING - Analyze user vibe
      _log.info('🧠 REASONING: Analyzing user vibe - $userVibe');
      final filtered = _filterByVibe(dayClusters, userVibe);

      // Step 5: REASONING - Optimize duration
      _log.info('🧠 REASONING: Optimizing for $durationDays-day trip');
      final optimized = _optimizeForDuration(filtered, durationDays);

      _log.info('✅ TRAVEL AGENT: Trip planned successfully');
      _log.info('Final itinerary: ${optimized.length} days');

      return TravelItinerary(
        city: city,
        dayClusters: optimized,
        totalAttractions: attractions.length,
        userVibe: userVibe,
      );
    } catch (e) {
      _log.severe('❌ Travel planning failed: $e');
      rethrow;
    }
  }

  /// Filter attractions based on user vibe
  List<DayCluster> _filterByVibe(List<DayCluster> clusters, String vibe) {
    _log.fine('Filtering for vibe: $vibe');

    if (vibe.toLowerCase().contains('cultural')) {
      return clusters
          .where((c) =>
              c.attractions.any((a) => a['category'].toString().contains('museum')))
          .toList();
    } else if (vibe.toLowerCase().contains('nature')) {
      return clusters
          .where((c) =>
              c.attractions.any((a) => a['category'].toString().contains('park')))
          .toList();
    }

    return clusters;
  }

  /// Optimize clusters for trip duration
  List<DayCluster> _optimizeForDuration(List<DayCluster> clusters, int days) {
    _log.fine('Optimizing $days days from ${clusters.length} clusters');
    return clusters.take(days).toList();
  }
}

/// Final itinerary returned to user
class TravelItinerary {
  final String city;
  final List<DayCluster> dayClusters;
  final int totalAttractions;
  final String userVibe;

  TravelItinerary({
    required this.city,
    required this.dayClusters,
    required this.totalAttractions,
    required this.userVibe,
  });

  String getSummary() {
    return 'Trip to $city: ${dayClusters.length} days, '
        '$totalAttractions attractions, Vibe: $userVibe';
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'days': dayClusters.length,
      'totalAttractions': totalAttractions,
      'userVibe': userVibe,
      'itinerary': dayClusters.map((d) => d.toJson()).toList(),
    };
  }
}
