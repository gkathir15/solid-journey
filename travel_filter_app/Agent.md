# Travel Filter App

This is a cross-platform Flutter application for iOS and Android that performs **on-device AI filtering** of local travel data using **Google Gemini Nano**.

## Features

*   **On-Device AI Filtering**: Uses the `google_generative_ai` package with **gemini-nano** model for on-device inference
*   **Privacy-First**: All data is processed locally on the device - nothing is sent to Google servers
*   **Local Data**: The list of attractions is loaded from a local JSON file
*   **UI**: A clean and modern UI with filter buttons, a list view, and a status chip to indicate the model's download status
*   **Error Handling**: Gracefully handles errors during model initialization and inference

## On-Device AI Model Setup

### What is Gemini Nano?

**Gemini Nano** is Google's smallest generative model designed for on-device inference. It:
- Runs entirely on the device (iOS/Android)
- Requires no internet connection for inference
- Protects user privacy by keeping data local
- Uses minimal resources (battery, storage, memory)

### How It Works

1. **Model Initialization**: When you tap "Download AI Model", the app initializes `gemini-nano`
2. **Local Inference**: All text filtering happens on-device
3. **No API Key Required**: Since it's on-device, no API key is needed for inference

### Configuration

The model is configured in `lib/ai_service.dart`:
```dart
_model = GenerativeModel(
  model: 'gemini-nano',
  apiKey: '', // Empty - on-device model doesn't need API key
);
```

## Requirements

- **iOS**: 13.0 or higher
- **Android**: API level 21 or higher
- **Flutter**: 3.10.7 or higher
- **Dart**: 3.10.7 or higher

## How to Run

1. Clone the repository
2. Run `flutter pub get`
3. Run the application on a physical iOS or Android device:
   ```bash
   flutter run
   ```
   
   Or on simulator:
   ```bash
   flutter run -d <device-id>
   ```

## Dependencies

- `google_generative_ai: ^0.4.7` - Google's Generative AI SDK with on-device model support
- `logging: ^1.2.0` - For logging inference results
- `path_provider: ^2.0.0` - For file system access

## Usage Flow

1. **Launch App**: The app loads Paris attractions from `assets/data/paris_attractions.json`
2. **Download Model**: Tap "Download AI Model" to initialize gemini-nano
3. **Filter Attractions**: Select a category (Museum, Cafe, Church, Park, Landmark) to filter attractions using on-device AI
4. **View Results**: The filtered list updates with matching attractions

## Privacy & Data

✅ **Private**: All processing happens on-device  
✅ **Secure**: No data is sent to external servers  
✅ **Offline**: Works without internet connection  
✅ **Fast**: On-device inference is typically faster than cloud APIs

## Technical Notes

- The model is initialized lazily when the user taps "Download AI Model"
- A simulated progress indicator shows initialization progress
- Error handling ensures graceful degradation if model initialization fails
- The app uses structured logging for debugging

