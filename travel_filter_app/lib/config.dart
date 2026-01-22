// Configuration for on-device AI
//
// To use on-device Gemini Nano models:
// 1. Get your API key from https://ai.google.dev
// 2. Set it in one of the following ways:
//    - Environment variable: export GOOGLE_API_KEY="your-key"
//    - Replace the placeholder below
//    - Use flutter run -d <device> -P GOOGLE_API_KEY="your-key"

class Config {
  // Your Google AI API key
  // Get one at: https://ai.google.dev
  static const String googleApiKey = String.fromEnvironment(
    'GOOGLE_API_KEY',
    defaultValue: '', // You can set a default value here during development
  );

  static bool hasValidApiKey() => googleApiKey.isNotEmpty;

  static String getApiKeyErrorMessage() {
    return '''
API Key not configured!

To use on-device Gemini Nano models:
1. Go to https://ai.google.dev
2. Create an API key for the Generative AI API
3. Set it using one of these methods:
   a) Environment variable: export GOOGLE_API_KEY="your-key"
   b) Run with: flutter run -P GOOGLE_API_KEY="your-key"
   c) Edit lib/config.dart and set the defaultValue

Note: Even for on-device models (gemini-nano), an API key is required
for SDK authentication. The API key is used only for authorization,
not for sending your data to cloud servers.
''';
  }

  static const List<String> commonVibes = [
    'historic',
    'local',
    'quiet',
    'vibrant',
    'nature',
    'urban',
    'cultural',
    'hidden_gem',
    'family_friendly',
    'budget',
    'luxury',
    'instagram_worthy',
    'off_the_beaten_path',
    'street_art',
    'cafe_culture',
    'nightlife',
    'adventure',
    'relaxation',
    'educational',
    'spiritual',
  ];
}
