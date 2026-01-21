# API Key Setup Guide - On-Device AI

## Quick Start

The Travel Filter App uses Google's Gemini Nano for on-device AI. Even though all processing happens locally on your device, the SDK requires a valid API key for authentication.

### Get Your API Key (Free)

1. **Visit Google AI Studio**
   - Go to https://ai.google.dev
   - Click "Get API Key"
   - Create a new API key

2. **Copy Your Key**
   - You should get a key that looks like: `AIzaSy...`
   - Keep this key safe!

### 3 Ways to Use Your API Key

#### Method 1: Environment Variable (Recommended for Development)

```bash
export GOOGLE_API_KEY="your-api-key-here"
flutter run -d <device-id>
```

#### Method 2: Command Line Parameter

```bash
flutter run -d <device-id> -P GOOGLE_API_KEY="your-api-key-here"
```

#### Method 3: Hardcoded in Code (Development Only!)

Edit `lib/config.dart`:
```dart
static const String googleApiKey = String.fromEnvironment(
  'GOOGLE_API_KEY',
  defaultValue: 'your-api-key-here', // ← Add your key here
);
```

**⚠️ Never commit this key to version control!**

## Important: What Your API Key Does

### ✅ What It's Used For
- Authentication with Google's AI services
- Authorizing your app to use Gemini models

### ❌ What It's NOT Used For (With On-Device Models)
- Sending your data to Google's servers
- Creating cloud endpoints for your data
- Storing your data in the cloud

### Privacy Guarantee
When using **gemini-nano** (on-device model):
- ✅ All text filtering happens on your device
- ✅ Your attraction data never leaves your device
- ✅ The model runs locally on your phone/simulator
- ✅ Only the API key is sent for authorization

## Verification

After setting your API key, run the app:

```bash
flutter run -d <device-id> -P GOOGLE_API_KEY="your-key"
```

**You should see in the logs:**
```
INFO: AiService: Starting local on-device model download/initialization...
INFO: AiService: On-device model (gemini-nano) initialized successfully
INFO: AiService: Model download/initialization complete.
```

**If you see this error:**
```
API Key not configured!
```

→ Make sure your API key is properly set using one of the methods above.

## Troubleshooting

### Error: "Method doesn't allow unregistered callers"
- Your API key is missing or invalid
- Get a new key from https://ai.google.dev
- Ensure it's properly set as environment variable or command line parameter

### Error: "Invalid API Key"
- Double-check the key matches what's in Google AI Studio
- Make sure you copied the entire key
- Try generating a new key

### Works Locally But Not on Device
- Ensure you pass the API key when running on physical device
- Method 3 (hardcoded) won't persist in release builds
- Use Method 1 (environment) or Method 2 (command line) for production

## For Production Deployment

For apps published to app stores:

1. **Use Cloud Build Process**
   - Set API key as build environment variable
   - Don't hardcode in source

2. **Use Secure Storage**
   - Store API key in secure encrypted storage
   - Retrieve at runtime
   - Recommended: flutter_secure_storage package

3. **Backend Proxy (Optional)**
   - Create a backend endpoint that handles API key
   - App communicates only with your backend
   - Backend communicates with Google AI API

## Example: With Environment Variable

```bash
# Set environment variable
export GOOGLE_API_KEY="AIzaSyDQsrOO7HxX0_0xOzqN7RN7SN_YOUR_KEY_HERE"

# Run on simulator
flutter run -d 52DB4BEB-113B-4148-9C05-C31AB6A1B8C6

# Or use command line parameter
flutter run -d 52DB4BEB-113B-4148-9C05-C31AB6A1B8C6 \
  -P GOOGLE_API_KEY="AIzaSyDQsrOO7HxX0_0xOzqN7RN7SN_YOUR_KEY_HERE"
```

## Questions?

- **API Key issues**: Visit https://ai.google.dev/support
- **Flutter issues**: Visit https://flutter.dev/docs
- **App issues**: Check the logs with `flutter logs`

---

**Remember:**
- ✅ Get free API key from https://ai.google.dev
- ✅ Use one of the three methods above to configure it
- ✅ Your data stays on your device
- ✅ Only the API key is sent to Google for authorization
