import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/discovery_orchestrator.dart';
import 'component_catalog.dart';

/// A2UI Protocol: AI-to-UI message processing
/// Handles structured messages from the LLM to generate UI components dynamically

class A2uiMessage {
  final String type; // 'surface_update', 'component_render', 'data_model_update'
  final String? componentType; // PlaceDiscoveryCard, RouteItinerary, etc.
  final Map<String, dynamic> data;
  final Map<String, dynamic>? metadata;

  A2uiMessage({
    required this.type,
    this.componentType,
    required this.data,
    this.metadata,
  });

  factory A2uiMessage.fromJson(Map<String, dynamic> json) {
    return A2uiMessage(
      type: json['type'] ?? 'component_render',
      componentType: json['componentType'],
      data: json['data'] ?? {},
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'componentType': componentType,
        'data': data,
        'metadata': metadata,
      };
}

/// Processes A2UI messages and manages the dynamic UI flow
class A2uiMessageProcessor extends ChangeNotifier {
  final DiscoveryOrchestrator discoveryOrchestrator;
  
  List<A2uiMessage> messageQueue = [];
  A2uiMessage? currentMessage;
  Map<String, dynamic> currentUIState = {};
  
  bool isProcessing = false;
  String? lastError;

  A2uiMessageProcessor({required this.discoveryOrchestrator}) {
    debugPrint('[A2UI] MessageProcessor initialized');
  }

  /// Process incoming LLM messages and update UI state
  Future<void> processLLMMessage(String llmOutput) async {
    try {
      isProcessing = true;
      lastError = null;
      debugPrint('[A2UI] Processing LLM output...');
      debugPrint('[A2UI] Raw output: $llmOutput');

      // Parse JSON from LLM output
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(llmOutput);
      if (jsonMatch == null) {
        throw Exception('No valid JSON found in LLM output');
      }

      final jsonStr = jsonMatch.group(0)!;
      final parsedJson = jsonDecode(jsonStr) as Map<String, dynamic>;

      debugPrint('[A2UI] Parsed JSON: ${jsonEncode(parsedJson)}');

      // Handle different message types
      if (parsedJson['messages'] is List) {
        final messages = (parsedJson['messages'] as List)
            .map((m) => A2uiMessage.fromJson(m as Map<String, dynamic>))
            .toList();

        for (final msg in messages) {
          await _processMessage(msg);
        }
      } else {
        final message = A2uiMessage.fromJson(parsedJson);
        await _processMessage(message);
      }

      isProcessing = false;
      notifyListeners();
    } catch (e) {
      lastError = e.toString();
      isProcessing = false;
      debugPrint('[A2UI] ❌ Error processing LLM message: $e');
      notifyListeners();
    }
  }

  Future<void> _processMessage(A2uiMessage message) async {
    debugPrint('[A2UI] Processing message type: ${message.type}');

    switch (message.type) {
      case 'surface_update':
        _handleSurfaceUpdate(message);
        break;
      case 'component_render':
        _handleComponentRender(message);
        break;
      case 'data_model_update':
        _handleDataModelUpdate(message);
        break;
      case 'sequence':
        _handleSequence(message);
        break;
      default:
        debugPrint('[A2UI] ⚠️ Unknown message type: ${message.type}');
    }
  }

  void _handleSurfaceUpdate(A2uiMessage message) {
    debugPrint('[A2UI] 📄 Surface Update');
    currentMessage = message;
    currentUIState = message.data;
    debugPrint('[A2UI] Surface state updated: ${jsonEncode(currentUIState)}');
  }

  void _handleComponentRender(A2uiMessage message) {
    debugPrint(
        '[A2UI] 🎨 Render component: ${message.componentType} with data: ${jsonEncode(message.data)}');
    currentMessage = message;
  }

  void _handleDataModelUpdate(A2uiMessage message) {
    debugPrint('[A2UI] 🔄 Data Model Update');
    currentUIState.addAll(message.data);
    debugPrint('[A2UI] State merged: ${jsonEncode(currentUIState)}');
  }

  void _handleSequence(A2uiMessage message) {
    debugPrint('[A2UI] 📋 Rendering sequence');
    currentMessage = message;
  }

  /// Generate a component from the current message
  Widget buildCurrentComponent() {
    if (currentMessage == null) {
      return Center(child: Text('No component to render'));
    }

    final componentType = currentMessage!.componentType;
    final data = currentMessage!.data;

    debugPrint('[A2UI] Building component: $componentType');

    return _renderComponent(componentType, data);
  }

  Widget _renderComponent(String? componentType, Map<String, dynamic> data) {
    switch (componentType) {
      case 'PlaceDiscoveryCard':
        return _buildPlaceDiscoveryCard(data);

      case 'RouteItinerary':
        return _buildRouteItinerary(data);

      case 'SmartMapSurface':
        return _buildSmartMapSurface(data);

      case 'VibeSelector':
        return _buildVibeSelector(data);

      case 'SequenceView':
        return _buildSequenceView(data);

      default:
        return Center(
          child: Text('Unknown component: $componentType'),
        );
    }
  }

  Widget _buildPlaceDiscoveryCard(Map<String, dynamic> data) {
    try {
      return PlaceDiscoveryCard(
        name: data['name'] ?? 'Unknown Place',
        vibes: List<String>.from(data['vibe'] ?? data['vibes'] ?? []),
        osmId: data['osmId'] ?? '',
        distance: (data['distance'] as num?)?.toDouble(),
        imageUrl: data['imageUrl'],
        description: data['description'],
        rating: (data['rating'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('[A2UI] ❌ Error building PlaceDiscoveryCard: $e');
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
      debugPrint('[A2UI] ❌ Error building RouteItinerary: $e');
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
                'Trip Map',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Places to explore:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
      debugPrint('[A2UI] ❌ Error building SmartMapSurface: $e');
      return SizedBox.shrink();
    }
  }

  Widget _buildVibeSelector(Map<String, dynamic> data) {
    try {
      return VibeSelector(
        selectedVibes: List<String>.from(data['selectedVibes'] ?? []),
        availableVibes:
            List<String>.from(data['availableVibes'] ?? ComponentCatalog.commonVibes),
        onVibesChanged: (vibes) {
          debugPrint('[A2UI] Vibes changed: $vibes');
          currentUIState['selectedVibes'] = vibes;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[A2UI] ❌ Error building VibeSelector: $e');
      return SizedBox.shrink();
    }
  }

  Widget _buildSequenceView(Map<String, dynamic> data) {
    try {
      final components = (data['components'] as List<dynamic>? ?? [])
          .map((c) => c as Map<String, dynamic>)
          .toList();

      return SingleChildScrollView(
        child: Column(
          children: components
              .map((c) =>
                  _renderComponent(c['componentType'], c['data'] ?? {}))
              .toList(),
        ),
      );
    } catch (e) {
      debugPrint('[A2UI] ❌ Error building SequenceView: $e');
      return SizedBox.shrink();
    }
  }

  /// Capture user interaction and send back to LLM for re-reasoning
  Future<void> handleUserInteraction(
    String eventType,
    Map<String, dynamic> eventData,
  ) async {
    debugPrint('[A2UI] 👆 User interaction: $eventType');
    debugPrint('[A2UI] Event data: ${jsonEncode(eventData)}');

    // This will be sent back to LLM as a DataModelUpdate
    final update = A2uiMessage(
      type: 'data_model_update',
      data: {
        'event': eventType,
        'data': eventData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    debugPrint('[A2UI] Sending interaction to LLM: ${jsonEncode(update.toJson())}');
    notifyListeners();
  }

  void clearState() {
    currentMessage = null;
    currentUIState = {};
    messageQueue = [];
    notifyListeners();
  }
}
