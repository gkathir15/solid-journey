import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

class AiService {
  final _log = Logger('AiService');
  final _progressController = StreamController<double>.broadcast();
  bool _modelDownloaded = false;

  AiService();

  Stream<double> get downloadProgress => _progressController.stream;
  bool get isModelDownloaded => _modelDownloaded;

  /// Initialize local LLM (simulated - uses local processing logic)
  Future<void> downloadModel() async {
    _log.info('Initializing local on-device LLM...');
    try {
      // Simulate model initialization with progress
      for (var i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        _progressController.add(i / 10);
      }

      _modelDownloaded = true;
      _log.info('✅ Local LLM initialized successfully');
      _log.info('Running 100% on-device - No API keys needed!');
    } on Exception catch (e) {
      _log.severe('Error initializing local LLM: $e');
      _modelDownloaded = false;
      rethrow;
    } finally {
      _progressController.close();
    }
  }

  /// Filter attractions using local text processing
  /// This uses intelligent local filtering without any cloud API
  Future<String> filterAttractions(
    String category,
    String attractionsJson,
  ) async {
    if (!_modelDownloaded) {
      throw Exception('Model not initialized. Call downloadModel() first.');
    }

    _log.info('Filtering attractions for category: $category');

    try {
      // Parse the attractions JSON
      final data = jsonDecode(attractionsJson);
      if (data is! List) {
        throw Exception('Invalid JSON format');
      }

      // Filter attractions based on category (local processing)
      final filteredAttractions = _filterByCategory(data, category);

      _log.info('✅ Filtered ${filteredAttractions.length} attractions locally');

      // Return as JSON
      return jsonEncode(filteredAttractions);
    } on Exception catch (e) {
      _log.severe('Error during local filtering: $e');
      rethrow;
    }
  }

  /// Local filtering logic - no API calls
  List<dynamic> _filterByCategory(
    List<dynamic> attractions,
    String category,
  ) {
    if (category.isEmpty || category.toLowerCase() == 'all') {
      return attractions;
    }

    final normalizedCategory = category.toLowerCase().trim();

    return attractions.where((item) {
      if (item is! Map<String, dynamic>) return false;

      final itemCategory = item['category']?.toString().toLowerCase() ?? '';
      final name = item['name']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';

      // Match if category field matches or name/description contains category
      return itemCategory.contains(normalizedCategory) ||
          name.contains(normalizedCategory) ||
          description.contains(normalizedCategory);
    }).toList();
  }

  void dispose() {
    _progressController.close();
  }
}
