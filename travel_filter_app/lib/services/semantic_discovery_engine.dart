import 'package:logging/logging.dart';

/// Semantic Discovery Engine - Transforms raw OSM tags into Vibe Signatures
/// 
/// Creates compact, token-efficient "vibe signatures" that encode:
/// - Heritage level and century
/// - Localness (independent vs. brand)
/// - Social vibes (craft, art, nature, etc.)
/// - Accessibility and features
/// 
/// Output: Semicolon-delimited string for LLM consumption
/// Example: "v:heritage,quiet,local;c:1800s;s:museum,art;f:wheelchair,free"
class SemanticDiscoveryEngine {
  final _log = Logger('DiscoveryEngine');

  /// Transform raw OSM data into Vibe Signature
  VibeSignature processElement(Map<String, dynamic> element) {
    _log.fine('Processing element: ${element['name']}');

    final signature = VibeSignature(
      id: element['id'],
      name: element['name'],
      lat: element['lat'],
      lon: element['lon'],
    );

    // Extract all vibe components
    signature.heritageVibes = _extractHeritageVibes(element);
    signature.localnessTest = _performLocalnessTest(element);
    signature.activityProfile = _mapActivityProfile(element);
    signature.naturalAnchor = _identifyNaturalAnchor(element);
    signature.amenityVibes = _extractAmenityVibes(element);
    signature.sensorySignals = _extractSensorySignals(element);
    signature.accessibilityFlags = _extractAccessibilityFlags(element);

    // Create compact representation
    signature.compactSignature = _minify(signature);

    _log.fine('✅ Signature: ${signature.compactSignature}');

    return signature;
  }

  /// THE HERITAGE LINK: Extract century and style
  List<String> _extractHeritageVibes(Map<String, dynamic> element) {
    final vibes = <String>[];

    // Heritage level
    if (element['heritage_level'] != null) {
      vibes.add('h${element['heritage_level']}'); // h4, h3, h2, h1
    }

    // Historic type
    if (element['historic_type'] != null) {
      final historicType = element['historic_type'].toString();
      vibes.add('hist:$historicType');
    }

    // Extract century from start_date
    if (element['start_date'] != null) {
      final century = _extractCentury(element['start_date']);
      if (century.isNotEmpty) vibes.add('c:$century');
    }

    // Architecture style
    if (element['architecture'] != null) {
      vibes.add('arch:${element['architecture']}');
    }

    // Artist info
    if (element['artist'] != null) {
      vibes.add('artist');
    }

    return vibes;
  }

  /// THE LOCALNESS TEST: Brand vs. Independent
  List<String> _performLocalnessTest(Map<String, dynamic> element) {
    final vibes = <String>[];
    final operator = element['operator']?.toString().toLowerCase() ?? '';
    final name = element['name']?.toString().toLowerCase() ?? '';

    // Global brands to detect
    final globalBrands = [
      'mcdonald', 'starbucks', 'subway', 'coffee', 'burger',
      'marriott', 'hilton', 'hyatt', 'accor', 'ihg',
      'zara', 'h&m', 'uniqlo', 'amazon', 'walmart'
    ];

    final isGlobalBrand = globalBrands.any(
      (brand) => operator.contains(brand) || name.contains(brand),
    );

    if (!isGlobalBrand && element['operator'] != null) {
      vibes.add('local'); // Independent/local operator
    } else if (!isGlobalBrand && element['operator'] == null) {
      vibes.add('indie'); // Likely independent
    } else {
      vibes.add('chain'); // Global brand
    }

    return vibes;
  }

  /// THE ACTIVITY PROFILE: Map leisure/craft tags to social vibes
  List<String> _mapActivityProfile(Map<String, dynamic> element) {
    final vibes = <String>[];
    final primaryCategory = element['primary_category']?.toString() ?? '';
    final rawTags = element['raw_tags'] as Map<String, dynamic>? ?? {};

    // Social activities
    const socialMap = {
      'hackerspace': 'tech',
      'craft_brewery': 'craft',
      'escape_game': 'interactive',
      'biergarten': 'social',
      'pub': 'nightlife',
      'bar': 'nightlife',
      'library': 'quiet',
      'cinema': 'entertainment',
      'theatre': 'culture',
      'bookshop': 'literary',
      'museum': 'culture',
      'gallery': 'art',
      'cafe': 'cozy',
      'playground': 'family',
      'nature_reserve': 'nature',
      'park': 'outdoor',
    };

    socialMap.forEach((key, vibe) {
      if (primaryCategory.contains(key) || rawTags[key] != null) {
        vibes.add('a:$vibe');
      }
    });

    return vibes;
  }

  /// THE NATURAL ANCHOR: Identify serene/nature spots
  List<String> _identifyNaturalAnchor(Map<String, dynamic> element) {
    final vibes = <String>[];
    final primaryCategory = element['primary_category']?.toString() ?? '';

    if (primaryCategory.contains('natural:') ||
        primaryCategory.contains('viewpoint') ||
        primaryCategory.contains('peak') ||
        primaryCategory.contains('park') ||
        primaryCategory.contains('garden')) {
      vibes.add('nature');
      vibes.add('serene');
      vibes.add('quiet');
    }

    return vibes;
  }

  /// Extract amenity-specific vibes
  List<String> _extractAmenityVibes(Map<String, dynamic> element) {
    final vibes = <String>[];

    // Cuisine types
    if (element['cuisine'] != null) {
      final cuisines = element['cuisine'].toString().split(';');
      for (final cuisine in cuisines.take(2)) {
        vibes.add('cuis:${cuisine.trim()}');
      }
    }

    // Dietary options
    if (element['diet_vegan'] == 'yes') vibes.add('vegan');
    if (element['diet_vegetarian'] == 'yes') vibes.add('veg');
    if (element['diet_gluten_free'] == 'yes') vibes.add('gf');

    // Dining style
    if (element['outdoor_seating'] == 'yes') vibes.add('outdoor');
    if (element['delivery'] == 'yes') vibes.add('delivery');
    if (element['takeaway'] == 'yes') vibes.add('takeaway');
    if (element['dine_in'] == 'yes') vibes.add('dine_in');

    return vibes;
  }

  /// Extract sensory signals (cost, vibe, etc.)
  List<String> _extractSensorySignals(Map<String, dynamic> element) {
    final vibes = <String>[];

    // Free vs. paid
    if (element['fee'] == 'no' || element['fee'] == null) {
      vibes.add('free');
    } else if (element['fee'] == 'yes') {
      vibes.add('paid');
    }

    // Smoking policy
    if (element['smoking'] == 'no') vibes.add('no_smoke');
    if (element['smoking'] == 'yes') vibes.add('smoking_ok');

    return vibes;
  }

  /// Extract accessibility flags
  List<String> _extractAccessibilityFlags(Map<String, dynamic> element) {
    final flags = <String>[];

    if (element['wheelchair'] == 'yes') flags.add('wc:yes');
    if (element['wheelchair'] == 'limited') flags.add('wc:limited');
    if (element['wheelchair'] == 'no') flags.add('wc:no');

    return flags;
  }

  /// Extract century from ISO date
  String _extractCentury(dynamic dateStr) {
    if (dateStr == null) return '';
    final str = dateStr.toString();
    final year = int.tryParse(str.substring(0, 4));
    if (year == null) return '';
    final century = ((year - 1) ~/ 100 + 1);
    return '${century}th';
  }

  /// MINIFICATION: Pack into compact semicolon-delimited string
  String _minify(VibeSignature sig) {
    final parts = <String>[];

    if (sig.heritageVibes.isNotEmpty) {
      parts.add('h:${sig.heritageVibes.join(",")}');
    }
    if (sig.localnessTest.isNotEmpty) {
      parts.add('l:${sig.localnessTest.join(",")}');
    }
    if (sig.activityProfile.isNotEmpty) {
      parts.add('a:${sig.activityProfile.join(",")}');
    }
    if (sig.naturalAnchor.isNotEmpty) {
      parts.add('n:${sig.naturalAnchor.join(",")}');
    }
    if (sig.amenityVibes.isNotEmpty) {
      parts.add('am:${sig.amenityVibes.join(",")}');
    }
    if (sig.sensorySignals.isNotEmpty) {
      parts.add('s:${sig.sensorySignals.join(",")}');
    }
    if (sig.accessibilityFlags.isNotEmpty) {
      parts.add('acc:${sig.accessibilityFlags.join(",")}');
    }

    return parts.join(';');
  }
}

/// Vibe Signature - Compact encoding of an attraction's essential character
class VibeSignature {
  final int id;
  final String name;
  final double lat;
  final double lon;

  late List<String> heritageVibes;
  late List<String> localnessTest;
  late List<String> activityProfile;
  late List<String> naturalAnchor;
  late List<String> amenityVibes;
  late List<String> sensorySignals;
  late List<String> accessibilityFlags;

  late String compactSignature;

  VibeSignature({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  /// For LLM consumption
  Map<String, dynamic> toLLMFormat() {
    return {
      'id': id,
      'name': name,
      'location': {'lat': lat, 'lon': lon},
      'vibe_signature': compactSignature,
    };
  }

  /// Full data for detailed view
  Map<String, dynamic> toFullFormat() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lon': lon,
      'heritageVibes': heritageVibes,
      'localnessTest': localnessTest,
      'activityProfile': activityProfile,
      'naturalAnchor': naturalAnchor,
      'amenityVibes': amenityVibes,
      'sensorySignals': sensorySignals,
      'accessibilityFlags': accessibilityFlags,
      'compactSignature': compactSignature,
    };
  }
}
