import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:travel_filter_app/gemma_llm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.gemmaService});

  final GemmaLLMService gemmaService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GemmaLLMService _gemmaService;
  StreamSubscription<double>? _downloadSubscription;
  bool _isModelLoaded = false;
  bool _isLoading = false;
  double _downloadProgress = 0;
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _attractions = [];
  List<Map<String, dynamic>> _filteredAttractions = [];

  @override
  void initState() {
    super.initState();
    _gemmaService = widget.gemmaService;
    _loadAttractions();
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAttractions() async {
    final String response =
        await rootBundle.loadString('assets/data/paris_attractions.json');
    final data = await json.decode(response);
    setState(() {
      _attractions = List<Map<String, dynamic>>.from(data);
      _filteredAttractions = _attractions;
    });
  }

  Future<void> _downloadModel() async {
    setState(() {
      _isLoading = true;
      _downloadProgress = 0;
    });

    _downloadSubscription = _gemmaService.downloadProgress.listen((progress) {
      if (!mounted) return;
      setState(() {
        _downloadProgress = progress;
      });
    }, onError: (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading Gemma model: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    }, onDone: () {
      if (!mounted) return;
      setState(() {
        _isModelLoaded = true;
        _isLoading = false;
      });
    });

    try {
      await _gemmaService.loadModel();
    } catch (e) {
      // Error handled by stream
    }
  }

  Future<void> _filterAttractions(String category) async {
    setState(() {
      _selectedCategory = category;
    });

    if (category == 'All') {
      setState(() {
        _filteredAttractions = _attractions;
      });
      return;
    }

    if (!_isModelLoaded) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please load Gemma model first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final attractionsJson = json.encode(_attractions);
      final result =
          await _gemmaService.inferenceFilterAttractions(category, attractionsJson);

      final regex = RegExp(r'\[.*\]', dotAll: true);
      final match = regex.firstMatch(result);
      if (match != null) {
        final cleanedJson = match.group(0)!;
        final data = json.decode(cleanedJson);
        setState(() {
          _filteredAttractions = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Invalid JSON from Gemma');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gemma error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Filter - Gemma LLM'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(
                  _isModelLoaded ? '🤖 Gemma Ready' : '⏳ Load Model'),
              backgroundColor: _isModelLoaded ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isModelLoaded || _isLoading ? null : _downloadModel,
              child: const Text('Load Gemma Model (On-Device LLM)'),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: _downloadProgress),
                  const SizedBox(height: 8),
                  Text('Loading model: ${(_downloadProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterButton(
                  category: 'All',
                  isSelected: _selectedCategory == 'All',
                  onPressed: _isLoading ? null : _filterAttractions,
                ),
                FilterButton(
                  category: 'Museum',
                  isSelected: _selectedCategory == 'Museum',
                  onPressed: _isLoading ? null : _filterAttractions,
                ),
                FilterButton(
                  category: 'Cafe',
                  isSelected: _selectedCategory == 'Cafe',
                  onPressed: _isLoading ? null : _filterAttractions,
                ),
                FilterButton(
                  category: 'Church',
                  isSelected: _selectedCategory == 'Church',
                  onPressed: _isLoading ? null : _filterAttractions,
                ),
                FilterButton(
                  category: 'Park',
                  isSelected: _selectedCategory == 'Park',
                  onPressed: _isLoading ? null : _filterAttractions,
                ),
                FilterButton(
                  category: 'Landmark',
                  isSelected: _selectedCategory == 'Landmark',
                  onPressed: _isLoading ? null : _filterAttractions,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredAttractions.length,
              itemBuilder: (context, index) {
                final attraction = _filteredAttractions[index];
                return ListTile(
                  title: Text(attraction['name']),
                  subtitle: Text(attraction['description']),
                  trailing: Chip(label: Text(attraction['category'])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onPressed,
  });

  final String category;
  final bool isSelected;
  final ValueChanged<String>? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: onPressed != null ? () => onPressed!(category) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.deepPurple : Colors.grey,
        ),
        child: Text(category),
      ),
    );
  }
}
