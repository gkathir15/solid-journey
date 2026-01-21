import 'dart:math' as math;
import 'package:logging/logging.dart';

/// Spatial Clustering Service - Groups attractions into "Day Clusters"
class SpatialClusteringService {
  final _log = Logger('SpatialClustering');

  /// Group attractions into day clusters based on proximity (with distance matrix)
  Future<List<DayCluster>> createDayClusters(
    List<Map<String, dynamic>> attractions,
    Map<String, Map<String, double>> distanceMatrix,
  ) async {
    _log.info('📍 Creating day clusters from ${attractions.length} attractions');

    final clusters = <DayCluster>[];
    final visited = <int>{};
    int dayNumber = 1;

    // Start with highest-rated attractions as anchors
    final sorted = List<Map<String, dynamic>>.from(attractions)
      ..sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
        return ratingB.compareTo(ratingA);
      });

    for (int i = 0; i < sorted.length; i++) {
      if (visited.contains(i)) continue;

      // Start new day cluster with this attraction as anchor
      final dayCluster = DayCluster(dayNumber: dayNumber);
      dayCluster.addAttraction(sorted[i], isAnchor: true);
      visited.add(i);

      // Find nearby attractions (within 1km)
      for (int j = i + 1; j < sorted.length; j++) {
        if (visited.contains(j)) continue;

        final dist = distanceMatrix[sorted[i]['id'].toString()]
                ?[sorted[j]['id'].toString()] ??
            9999;

        if (dist <= 1.0) {
          dayCluster.addAttraction(sorted[j]);
          visited.add(j);
        }

        // Limit cluster size
        if (dayCluster.attractions.length >= 8) break;
      }

      clusters.add(dayCluster);
      dayNumber++;
    }

    _log.info('✅ Created ${clusters.length} day clusters');
    return clusters;
  }

  /// Group attractions into day clusters (without distance matrix)
  /// Used by orchestrate flow - calculates distances on-the-fly
  Future<List<DayCluster>> createDayClustersByCount(
    List<Map<String, dynamic>> attractions, {
    required int durationDays,
  }) async {
    _log.info('📍 Creating $durationDays day clusters from ${attractions.length} attractions');

    final clusters = <DayCluster>[];
    
    // Sort by rating and distance diversity
    final sorted = List<Map<String, dynamic>>.from(attractions)
      ..sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
        return ratingB.compareTo(ratingA);
      });

    final itemsPerDay = (sorted.length / durationDays).ceil();
    
    for (int day = 0; day < durationDays && day * itemsPerDay < sorted.length; day++) {
      final dayCluster = DayCluster(dayNumber: day + 1);
      final startIdx = day * itemsPerDay;
      final endIdx = ((day + 1) * itemsPerDay).clamp(0, sorted.length);

      for (int i = startIdx; i < endIdx && i < sorted.length; i++) {
        dayCluster.addAttraction(
          sorted[i],
          isAnchor: i == startIdx,
        );
      }

      if (dayCluster.attractions.isNotEmpty) {
        clusters.add(dayCluster);
      }
    }

    _log.info('✅ Created ${clusters.length} day clusters');
    return clusters;
  }
}

/// Represents a single day's itinerary
class DayCluster {
  final int dayNumber;
  final List<Map<String, dynamic>> attractions = [];
  late Map<String, dynamic> anchorPoint;
  late double distanceCovered;

  DayCluster({required this.dayNumber}) {
    distanceCovered = 0.0;
  }

  void addAttraction(Map<String, dynamic> attraction, {bool isAnchor = false}) {
    attractions.add(attraction);
    if (isAnchor) {
      anchorPoint = attraction;
    }
    // Recalculate total distance
    distanceCovered = _calculateTotalDistance();
  }

  /// Get day summary
  String getSummary() {
    return 'Day $dayNumber: ${anchorPoint['name']} + ${attractions.length - 1} more';
  }

  /// Get route as JSON
  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'anchorPoint': anchorPoint,
      'attractions': attractions,
      'totalDistance': distanceCovered,
      'estimatedTime': '${attractions.length * 45} minutes',
    };
  }

  double _calculateTotalDistance() {
    double total = 0;
    for (int i = 0; i < attractions.length - 1; i++) {
      final dist = _haversine(
        attractions[i]['lat'] ?? 0.0,
        attractions[i]['lon'] ?? 0.0,
        attractions[i + 1]['lat'] ?? 0.0,
        attractions[i + 1]['lon'] ?? 0.0,
      );
      total += dist;
    }
    return total;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = 0.5 - 
        0.5 * math.cos((lat2 - lat1) * math.pi / 180) +
        0.5 * 
            math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            (1 - math.cos(dLon));
    return R * 2 * math.asin(math.sqrt(a));
  }
}
