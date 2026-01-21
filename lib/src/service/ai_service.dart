import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../model/attraction.dart';

class AIService {
  // Placeholder for the generative model. In a real app, this would be
  // initialized after the model is downloaded.
  GenerativeModel? _model;

  // Simulates downloading and initializing the AI model.
  Future<bool> downloadModel() async {
    // In a real application, this would involve using the Google AI Edge SDK
    // to download and initialize the Gemini Nano model. For this example,
    // we'll simulate a delay and then initialize a placeholder model.
    await Future.delayed(const Duration(seconds: 3));

    // For the purpose of this example, we'll assume the model is ready.
    // In a real implementation, you would initialize the model like this:
    // _model = GenerativeModel(model: 'gemini-nano', ...);

    // Let's return true to indicate success.
    return true;
  }

  Future<String> filterAttractions(List<Attraction> attractions, String category) async {
    // In a real scenario, we would check if the model is initialized.
    // if (_model == null) {
    //   throw Exception("AI model is not available.");
    // }

    // Convert the list of attractions to a JSON string.
    final jsonList = attractions.map((att) => {'n': att.name, 'c': att.category, 'd': att.description}).toList();
    final jsonString = json.encode(jsonList);

    // Construct the prompt for the AI model.
    final prompt = """
      You are a local data filter. I will provide a JSON list of Paris attractions.
      Return ONLY a JSON list of the items that match the category: [$category].
      Do not add any conversational text or greetings.

      JSON data:
      $jsonString
    """;

    // This is a placeholder for the actual AI call.
    // final response = await _model!.generateContent([Content.text(prompt)]);
    // return response.text ?? '';

    // For now, we will return a hardcoded, clean JSON response for "museum".
    if (category.toLowerCase() == 'museum') {
      return '''
        [
          {"n": "Louvre Museum", "c": "museum", "d": "World's largest art museum, home to the Mona Lisa."},
          {"n": "Musée d'Orsay", "c": "museum", "d": "Famous for Impressionist masterpieces in a former train station."},
          {"n": "Centre Pompidou", "c": "museum", "d": "High-tech architectural landmark with modern art collections."}
        ]
      ''';
    } else {
       return '[]'; // Return an empty list for other categories.
    }
  }
}
