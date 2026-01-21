import 'package:logging/logging.dart';

/// Spatial Clustering Service - Groups attractions into "Day Clusters"
class SpatialClusteringService {
  final _log = Logger('SpatialClustering');

  /// Group attractions into day clusters based on proximity
  Future<List<DayCluster>> createDayClusters(
    List<Map<String, dynamic>> attractions,
    Map<String, Map<String, double>> distanceMatrix,
  ) async {
    _log.info('��️ Creating day clusters from ${attractions.length} attractions');

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
}

/// Represents a single day's itinerary
class DayCluster {
  final int dayNumber;
  final List<Map<String, dynamic>> attractions = [];
  late Map<String, dynamic> anchorPoint;

  DayCluster({required this.dayNumber});

  void addAttraction(Map<String, dynamic> attraction, {bool isAnchor = false}) {
    attractions.add(attraction);
    if (isAnchor) {
      anchorPoint = attraction;
    }
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
      'totalDistance': _calculateTotalDistance(),
      'estimatedTime': '${attractions.length * 45} minutes',
    };
  }

  double _calculateTotalDistance() {
    double total = 0;
    for (int i = 0; i < attractions.length - 1; i++) {
      final dist = _haversine(
        attractions[i]['lat'],
        attractions[i]['lon'],
        attractions[i + 1]['lat'],
        attractions[i + 1]['lon'],
      );
      total += dist;
    }
    return total;
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * 3.141592653589793 / 180;
    final dLon = (lon2 - lon1) * 3.141592653589793 / 180;
    final a = 0.5 - 0.5 * ((lat2 - lat1) / 180).abs().cos() +
        0.5 *
            (lat1 * 3.141592653589793 / 180).cos() *
            (lat2 * 3.141592653589793 / 180).cos() *
            (1 - (dLon).cos());
    return R * 2 * a.asin();
  }
}
