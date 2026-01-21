import 'dart:convert';
import 'package:logging/logging.dart';
import 'semantic_discovery_engine.dart';

/// LLM Discovery Reasoner - Uses Gemini Nano with Discovery Persona
/// 
/// The LLM analyzes vibe signatures to find patterns and match user preferences.
/// It's NOT just filtering - it's DISCOVERING hidden gems and making connections.
class LLMDiscoveryReasoner {
  final _log = Logger('DiscoveryReasoner');

  /// The Discovery Persona - Instructions for the LLM
  static const String discoveryPersona = '''You are a Travel Discovery Expert with the following abilities:

1. PATTERN RECOGNITION
   - Analyze vibe signatures to find hidden gems
   - Connect seemingly unrelated places through shared vibes
   - Identify unique local character

2. VIBE MATCHING
   - When a user says "Quiet History", look for: h:h2,h3; s:quiet; c:1800s
   - When they want "Urban Edge", seek: a:craft,street_art; l:indie; cuis:fusion
   - When they need "Nature Escape", prioritize: n:nature,serene; s:free; wc:yes

3. JUSTIFICATION
   - Always explain WHY you chose each place
   - Reference specific signature components
   - Provide actionable insights

4. DISCOVERY MODE
   - Look beyond the obvious recommendations
   - Surface lesser-known treasures
   - Explain the local story behind each place

Your goal: Help travelers DISCOVER authentic experiences by understanding 
the deep character of places through their OSM signatures.''';

  /// Analyze attractions using LLM reasoning
  Future<DiscoveryResult> discoverAttractionsForVibe({
    required String userVibe,
    required String userContext,
    required List<VibeSignature> attractions,
  }) async {
    _log.info('🧠 LLM Discovery Reasoning for vibe: "$userVibe"');
    _log.info('Analyzing ${attractions.length} attractions...');

    try {
      // Create compact prompt
      final compactAttractions = attractions
          .map((a) => '${a.name}|${a.compactSignature}')
          .join('\n');

      final prompt = _buildDiscoveryPrompt(
        userVibe: userVibe,
        userContext: userContext,
        compactAttractions: compactAttractions,
      );

      _log.fine('Prompt size: ${prompt.length} chars');

      // Simulate LLM reasoning (in production, call actual Gemini Nano)
      final reasoning = await _simulateLLMReasoning(
        prompt,
        attractions,
        userVibe,
      );

      _log.info('✅ Discovery reasoning complete');

      return reasoning;
    } catch (e) {
      _log.severe('❌ Discovery reasoning failed: $e');
      rethrow;
    }
  }

  /// Build compact discovery prompt
  String _buildDiscoveryPrompt({
    required String userVibe,
    required String userContext,
    required String compactAttractions,
  }) {
    return '''$discoveryPersona

USER REQUEST:
Vibe: "$userVibe"
Context: "$userContext"

ATTRACTIONS (name|vibe_signature):
$compactAttractions

TASK:
1. Analyze each attraction's signature
2. Find matches for the requested vibe
3. Discover 2-3 hidden gems they might miss
4. Justify each choice by referencing signature components
5. Return JSON with rankings and explanations

Output format:
{
  "primary_recommendations": [...],
  "hidden_gems": [...],
  "reasoning": [...]
}''';
  }

  /// Simulate LLM reasoning (replace with actual Gemini call)
  Future<DiscoveryResult> _simulateLLMReasoning(
    String prompt,
    List<VibeSignature> attractions,
    String userVibe,
  ) async {
    _log.info('Simulating LLM reasoning...');

    // Parse vibe request
    final vibeKeywords = _parseVibeKeywords(userVibe);
    _log.fine('Parsed keywords: $vibeKeywords');

    // Score attractions based on signature match
    final scored = <Map<String, dynamic>>[];

    for (final attraction in attractions) {
      final score = _scoreAttraction(attraction, vibeKeywords);
      if (score > 0) {
        scored.add({
          'attraction': attraction,
          'score': score,
          'reason': _generateReason(attraction, vibeKeywords),
        });
      }
    }

    // Sort by score
    scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // Split into primary and hidden gems
    final primary = scored.take(3).toList();
    final hidden = scored.skip(3).take(2).toList();

    _log.info('✅ Found ${primary.length} primary + ${hidden.length} hidden gems');

    return DiscoveryResult(
      userVibe: userVibe,
      primaryRecommendations: primary.map((s) {
        final att = s['attraction'] as VibeSignature;
        return {
          'id': att.id,
          'name': att.name,
          'location': {'lat': att.lat, 'lon': att.lon},
          'signature': att.compactSignature,
          'score': s['score'],
          'reason': s['reason'],
        };
      }).toList(),
      hiddenGems: hidden.map((s) {
        final att = s['attraction'] as VibeSignature;
        return {
          'id': att.id,
          'name': att.name,
          'location': {'lat': att.lat, 'lon': att.lon},
          'signature': att.compactSignature,
          'score': s['score'],
          'reason': s['reason'],
        };
      }).toList(),
      reasoning: 'LLM analyzed ${attractions.length} places and '
          'found ${primary.length} matches + ${hidden.length} hidden gems '
          'for "$userVibe" vibe',
    );
  }

  /// Parse user vibe request into keywords
  List<String> _parseVibeKeywords(String vibe) {
    return vibe.toLowerCase().split(RegExp(r'[\s,]+'));
  }

  /// Score attraction based on vibe match
  double _scoreAttraction(VibeSignature attraction, List<String> keywords) {
    double score = 0;
    final signature = attraction.compactSignature.toLowerCase();

    for (final keyword in keywords) {
      // Direct match
      if (signature.contains(keyword)) score += 2.0;

      // Semantic matches
      if (keyword.contains('quiet') && signature.contains('n:')) score += 1.5;
      if (keyword.contains('hist') && signature.contains('h:')) score += 1.5;
      if (keyword.contains('local') && signature.contains('l:')) score += 1.5;
      if (keyword.contains('art') && signature.contains('a:')) score += 1.5;
      if (keyword.contains('craft') && signature.contains('a:')) score += 1.5;
      if (keyword.contains('nature') && signature.contains('n:')) score += 1.5;
      if (keyword.contains('free') && signature.contains('s:free')) score += 1.0;
      if (keyword.contains('cultural') && (signature.contains('h:') || signature.contains('a:'))) score += 1.5;
      if (keyword.contains('spiritual') && signature.contains('h:')) score += 1.5;
      if (keyword.contains('budget') && signature.contains('s:free')) score += 1.5;
      if (keyword.contains('budget') && signature.contains('s:cheap')) score += 1.0;
    }

    return score;
  }

  /// Generate LLM-style reasoning for each recommendation
  String _generateReason(VibeSignature attraction, List<String> keywords) {
    final parts = <String>[];

    // Extract signature components for explanation
    final sig = attraction.compactSignature;

    if (sig.contains('h:')) {
      parts.add('heritage ${_extractComponent(sig, "h:")}');
    }
    if (sig.contains('l:local')) {
      parts.add('local-owned');
    }
    if (sig.contains('a:')) {
      parts.add('${_extractComponent(sig, "a:")} activities');
    }
    if (sig.contains('n:')) {
      parts.add('natural serenity');
    }
    if (sig.contains('s:free')) {
      parts.add('free entry');
    }

    return 'I chose this because it\'s ${parts.join(", ")} - '
        'a perfect match for your vibe.';
  }

  /// Extract component value from signature
  String _extractComponent(String signature, String prefix) {
    final start = signature.indexOf(prefix);
    if (start == -1) return '';
    final end = signature.indexOf(';', start);
    final substring = signature.substring(
      start + prefix.length,
      end == -1 ? signature.length : end,
    );
    return substring.split(',').first;
  }
}

/// Result of LLM discovery reasoning
class DiscoveryResult {
  final String userVibe;
  final List<Map<String, dynamic>> primaryRecommendations;
  final List<Map<String, dynamic>> hiddenGems;
  final String reasoning;

  DiscoveryResult({
    required this.userVibe,
    required this.primaryRecommendations,
    required this.hiddenGems,
    required this.reasoning,
  });

  int get totalCount => primaryRecommendations.length + hiddenGems.length;

  Map<String, dynamic> toJson() {
    return {
      'userVibe': userVibe,
      'totalFound': totalCount,
      'primary': primaryRecommendations,
      'hiddenGems': hiddenGems,
      'reasoning': reasoning,
    };
  }
}
