import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'a2ui_message_processor.dart';
import '../services/discovery_orchestrator.dart';
import '../config.dart';

/// GenUiSurface: The main canvas where AI-generated UI components appear
/// This is the orchestration point for all dynamic UI rendering
class GenUiSurface extends StatefulWidget {
  final String city;
  final String country;
  final List<String> userVibes;
  final int tripDays;

  const GenUiSurface({
    required this.city,
    required this.country,
    required this.userVibes,
    required this.tripDays,
  });

  @override
  State<GenUiSurface> createState() => _GenUiSurfaceState();
}

class _GenUiSurfaceState extends State<GenUiSurface> {
  late A2uiMessageProcessor messageProcessor;
  late DiscoveryOrchestrator discoveryOrchestrator;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndPlan();
  }

  Future<void> _initializeAndPlan() async {
    try {
      debugPrint(
          '[GenUiSurface] Initializing trip planning for ${widget.city}, ${widget.country}');
      debugPrint('[GenUiSurface] User vibes: ${widget.userVibes}');
      debugPrint('[GenUiSurface] Trip duration: ${widget.tripDays} days');

      // Initialize discovery orchestrator
      discoveryOrchestrator = DiscoveryOrchestrator();
      messageProcessor = A2uiMessageProcessor(
        discoveryOrchestrator: discoveryOrchestrator,
      );

      // Orchestrate the discovery and planning
      final result = await discoveryOrchestrator.orchestrate(
        city: widget.city,
        country: widget.country,
        selectedVibes: widget.userVibes,
        durationDays: widget.tripDays,
      );

      debugPrint('[GenUiSurface] ✅ Orchestration complete');
      debugPrint('[GenUiSurface] Result: $result');

      // Generate initial UI based on discovery results
      await _generateInitialUI(result);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('[GenUiSurface] ❌ Error: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _generateInitialUI(Map<String, dynamic> planningResult) async {
    // This would normally come from LLM reasoning
    // For now, we'll create a default flow
    final initialMessages = '''
    {
      "messages": [
        {
          "type": "component_render",
          "componentType": "VibeSelector",
          "data": {
            "selectedVibes": ${widget.userVibes},
            "availableVibes": ["historic", "local", "quiet", "vibrant", "nature", "urban", "cultural", "hidden_gem", "family_friendly", "budget", "luxury", "instagram_worthy", "off_the_beaten_path", "street_art", "cafe_culture", "nightlife", "adventure", "relaxation", "educational", "spiritual"]
          }
        },
        {
          "type": "component_render",
          "componentType": "SmartMapSurface",
          "data": {
            "places": [],
            "vibeFilter": ${widget.userVibes},
            "centerLat": 0,
            "centerLon": 0,
            "zoomLevel": 13
          }
        }
      ]
    }
    ''';

    await messageProcessor.processLLMMessage(initialMessages);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<A2uiMessageProcessor>.value(
      value: messageProcessor,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.city} Trip Plan (${widget.tripDays} days)'),
        ),
        body: isLoading
            ? _buildLoadingState()
            : errorMessage != null
                ? _buildErrorState()
                : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Planning your ${widget.city} adventure...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Error: $errorMessage'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              _initializeAndPlan();
            },
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<A2uiMessageProcessor>(
      builder: (context, processor, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Render current component
              if (processor.currentMessage != null)
                Padding(
                  padding: EdgeInsets.all(8),
                  child: processor.buildCurrentComponent(),
                ),

              // Show processing status
              if (processor.isProcessing)
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('AI is analyzing...'),
                    ],
                  ),
                ),

              // Show errors
              if (processor.lastError != null)
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.red.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(processor.lastError!),
                    ],
                  ),
                ),

              // Action buttons
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        processor.handleUserInteraction('refresh', {
                          'city': widget.city,
                          'vibes': widget.userVibes,
                        });
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Regenerate'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        processor.clearState();
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back),
                      label: Text('Back'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
