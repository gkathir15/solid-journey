import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'genui/genui_surface.dart';
import 'genui/component_catalog.dart';
import 'services/discovery_orchestrator.dart';

/// Phase 5: AI-First GenUI Home Screen
/// 
/// This is the entry point for the GenUI-driven travel planning interface.
/// The LLM (via DiscoveryOrchestrator) controls the entire flow via A2UI protocol.
class Phase5Home extends StatefulWidget {
  const Phase5Home({Key? key}) : super(key: key);

  @override
  State<Phase5Home> createState() => _Phase5HomeState();
}

class _Phase5HomeState extends State<Phase5Home> {
  final _log = Logger('Phase5Home');

  // State for the planning flow
  String _selectedCountry = 'France';
  String _selectedCity = 'Paris';
  List<String> _selectedVibes = ['historic', 'local', 'cultural'];
  int _selectedDuration = 3;
  bool _isPlanning = false;
  String? _planningError;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startPlanning() async {
    setState(() {
      _isPlanning = true;
      _planningError = null;
    });

    try {
      _log.info(
        '🎯 Starting trip planning: $_selectedCity, $_selectedCountry - '
        'Duration: $_selectedDuration days - Vibes: $_selectedVibes',
      );

      // Navigate to GenUI Surface for planning
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GenUiSurface(
            city: _selectedCity,
            country: _selectedCountry,
            userVibes: _selectedVibes,
            tripDays: _selectedDuration,
          ),
        ),
      );
      
      setState(() {
        _isPlanning = false;
      });
    } catch (e) {
      _log.severe('Planning failed: $e');
      if (!mounted) return;
      setState(() {
        _planningError = 'Error starting planning: $e';
        _isPlanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Planner - GenUI Phase 5'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Plan Your Perfect Trip',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'AI-powered itineraries based on your vibe',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Country Selector
              _buildSectionTitle('Destination Country', context),
              _buildCountrySelector(),
              const SizedBox(height: 20),

              // City Selector
              _buildSectionTitle('City', context),
              _buildCityInput(),
              const SizedBox(height: 20),

              // Duration Selector
              _buildSectionTitle('Trip Duration', context),
              _buildDurationSlider(),
              const SizedBox(height: 20),

              // Vibe Selector
              _buildSectionTitle('Your Vibe', context),
              _buildVibeSelector(),
              const SizedBox(height: 24),

              // Error message
              if (_planningError != null) ...[
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _planningError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Plan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPlanning ? null : _startPlanning,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: _isPlanning
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Generate Itinerary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    final countries = ['France', 'Italy', 'Spain', 'Japan', 'USA', 'India'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: countries.map((country) {
        final isSelected = _selectedCountry == country;
        return ChoiceChip(
          label: Text(country),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => _selectedCountry = country);
          },
          selectedColor: Colors.deepPurple,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCityInput() {
    return TextField(
      onChanged: (value) => setState(() => _selectedCity = value),
      decoration: InputDecoration(
        hintText: 'Enter city name (e.g., Paris, Rome, Barcelona)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.location_on),
      ),
      controller: TextEditingController(text: _selectedCity),
    );
  }

  Widget _buildDurationSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: _selectedDuration.toDouble(),
          min: 1,
          max: 14,
          divisions: 13,
          label: '$_selectedDuration days',
          onChanged: (value) {
            setState(() => _selectedDuration = value.toInt());
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Selected: $_selectedDuration days',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildVibeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ComponentCatalog.commonVibes.map((vibe) {
            final isSelected = _selectedVibes.contains(vibe);
            return FilterChip(
              label: Text(vibe),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedVibes.add(vibe);
                  } else {
                    _selectedVibes.remove(vibe);
                  }
                });
              },
              selectedColor: Colors.deepPurple.withOpacity(0.7),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
        if (_selectedVibes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Select at least one vibe',
              style: TextStyle(color: Colors.red[400], fontSize: 12),
            ),
          ),
      ],
    );
  }
}
