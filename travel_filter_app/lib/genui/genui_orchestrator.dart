import 'dart:convert';
import 'package:flutter/material.dart';
import 'component_catalog.dart';
import '../config.dart';
import '../services/discovery_orchestrator.dart';

/// Handles A2UI message parsing and widget rendering
class GenUiOrchestrator {
  final DiscoveryOrchestrator discoveryOrchestrator;

  GenUiOrchestrator({required this.discoveryOrchestrator});

  /// Parse AI-generated A2UI message and render appropriate widget
  Widget renderComponent(Map<String, dynamic> a2uiMessage) {
    final componentType = a2uiMessage['component'] as String?;
    final data = a2uiMessage['data'] as Map<String, dynamic>? ?? {};

    debugPrint(
        '[GenUI] Rendering component: $componentType with data: ${jsonEncode(data)}');

    switch (componentType) {
      case 'PlaceDiscoveryCard':
        return _buildPlaceDiscoveryCard(data);
      case 'RouteItinerary':
        return _buildRouteItinerary(data);
      case 'SmartMapSurface':
        return _buildSmartMapSurface(data);
      case 'VibeSelector':
        return _buildVibeSelector(data);
      default:
        return Scaffold(
          appBar: AppBar(title: Text('Unknown Component')),
          body: Center(
            child: Text('Unknown component: $componentType'),
          ),
        );
    }
  }

  Widget _buildPlaceDiscoveryCard(Map<String, dynamic> data) {
    try {
      return PlaceDiscoveryCard(
        name: data['name'] ?? 'Unknown Place',
        vibes: List<String>.from(data['vibe'] ?? []),
        osmId: data['osmId'] ?? '',
        distance: (data['distance'] as num?)?.toDouble(),
        imageUrl: data['imageUrl'],
        description: data['description'],
        rating: (data['rating'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('[GenUI] Error building PlaceDiscoveryCard: $e');
      return SizedBox.shrink();
    }
  }

  Widget _buildRouteItinerary(Map<String, dynamic> data) {
    try {
      final days = (data['days'] as List<dynamic>? ?? [])
          .map((d) => DayCluster.fromJson(d as Map<String, dynamic>))
          .toList();

      return RouteItinerary(
        days: days,
        tripSummary: data['tripSummary'],
      );
    } catch (e) {
      debugPrint('[GenUI] Error building RouteItinerary: $e');
      return SizedBox.shrink();
    }
  }

  Widget _buildSmartMapSurface(Map<String, dynamic> data) {
    try {
      return Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Map Surface',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Places on map:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (data['places'] as List<dynamic>? ?? [])
                    .map((p) {
                      final place = p as Map<String, dynamic>;
                      return Chip(label: Text(place['name'] ?? 'Unknown'));
                    })
                    .toList(),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('[GenUI] Error building SmartMapSurface: $e');
      return SizedBox.shrink();
    }
  }

  Widget _buildVibeSelector(Map<String, dynamic> data) {
    try {
      return VibeSelector(
        selectedVibes: List<String>.from(data['selectedVibes'] ?? []),
        availableVibes: List<String>.from(
          data['availableVibes'] ?? ComponentCatalog.commonVibes,
        ),
        onVibesChanged: (vibes) {
          debugPrint('[GenUI] Vibes changed: $vibes');
        },
      );
    } catch (e) {
      debugPrint('[GenUI] Error building VibeSelector: $e');
      return SizedBox.shrink();
    }
  }

  /// Process user interaction with generated widget
  void onComponentInteraction(String componentType, dynamic eventData) {
    debugPrint(
        '[GenUI] Component interaction: $componentType with data: $eventData');
    // This would send the interaction back to the LLM for re-evaluation
  }
}

/// Main GenUI Surface widget - the canvas where AI-generated UI appears
class GenUiSurface extends StatefulWidget {
  final GenUiOrchestrator orchestrator;
  final String city;
  final String country;
  final List<String> selectedVibes;

  const GenUiSurface({
    required this.orchestrator,
    required this.city,
    required this.country,
    required this.selectedVibes,
  });

  @override
  State<GenUiSurface> createState() => _GenUiSurfaceState();
}

class _GenUiSurfaceState extends State<GenUiSurface> {
  List<Widget> _generatedComponents = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePlan();
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint(
          '[GenUiSurface] Generating plan for ${widget.city}, ${widget.country} with vibes: ${widget.selectedVibes}');

      // Call discovery orchestrator to fetch data
      final result =
          await widget.orchestrator.discoveryOrchestrator.orchestrate(
        city: widget.city,
        country: widget.country,
        selectedVibes: widget.selectedVibes,
      );

      if (result != null && result['success'] == true) {
        final itinerary = result['itinerary'] as Map<String, dynamic>? ?? {};
        final days = itinerary['days'] as List<dynamic>? ?? [];

        // Build RouteItinerary widget from LLM response
        setState(() {
          _generatedComponents = [
            RouteItinerary(
              days: days
                  .map((d) => DayCluster.fromJson(d as Map<String, dynamic>))
                  .toList(),
              tripSummary: itinerary['tripSummary'],
            ),
          ];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to generate itinerary';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[GenUiSurface] Error: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.city}, ${widget.country}'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Planning your trip...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generatePlan,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_generatedComponents.isEmpty) {
      return Center(
        child: Text('No components generated'),
      );
    }

    return ListView(
      children: _generatedComponents,
    );
  }
}
