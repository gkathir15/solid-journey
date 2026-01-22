# PHASE 6 QUICK START FOR NEXT DEVELOPER

## What You Need to Know

### The Architecture
```
User selects City + Vibes + Days
         ↓
GenUiSurface widget
         ↓
LLMReasoningEngine.planTrip()
         ↓
DiscoveryOrchestrator.orchestrate() ← Gets OSM data + vibe signatures
         ↓
A2uiMessageProcessor.processLLMMessage() ← Renders UI dynamically
         ↓
User sees: PlaceDiscoveryCard + SmartMapSurface + RouteItinerary
```

### Key Classes

**A2uiMessageProcessor** (`lib/genui/a2ui_message_processor.dart`)
- Listens to LLM output
- Parses JSON messages
- Manages UI state
- Renders components

```dart
// Usage
messageProcessor.processLLMMessage(llmJsonOutput);
messageProcessor.handleUserInteraction('add_to_trip', {});
```

**GenUiSurface** (`lib/genui/genui_surface.dart`)
- Main UI canvas
- Initializes orchestrators
- Shows loading/error states

```dart
// Usage
GenUiSurface(
  city: 'Paris',
  country: 'France',
  userVibes: ['historic', 'cafe_culture'],
  tripDays: 3,
)
```

**LLMReasoningEngine** (`lib/genui/llm_reasoning_engine.dart`)
- 4-step planning process
- Calls discovery
- Calls LLM (mock for now)
- Generates UI messages

```dart
// Usage
final engine = LLMReasoningEngine(
  discoveryOrchestrator: discovery,
  messageProcessor: processor,
);
final result = await engine.planTrip(
  city: 'Paris',
  country: 'France',
  userVibes: ['historic'],
  tripDays: 3,
);
```

### Component Catalog
Defined in `lib/genui/component_catalog.dart`

```dart
// Each has JSON schema + Flutter widget
- PlaceDiscoveryCard
- SmartMapSurface
- RouteItinerary
- VibeSelector
```

## How to Test

```bash
# First build (slow - ~5 min)
flutter run -d <device-id>

# Subsequent builds (faster - ~2 min)
flutter run -d <device-id>

# Clean rebuild if needed
flutter clean && flutter run -d <device-id>
```

## Common Tasks

### Add a new component
1. Add schema to `ComponentCatalog.schema` 
2. Add widget class to `component_catalog.dart`
3. Add rendering logic to `A2uiMessageProcessor._renderComponent()`
4. Test with mock LLM output

### Integrate real LLM
1. Replace mock in `LLMReasoningEngine._reasonAboutClusters()`
2. Call actual Gemini Nano
3. Parse reasoning output
4. Generate A2UI messages

### Add tool calling
1. Define tool in `LLMReasoningEngine`
2. LLM responds with tool call
3. Execute tool (query OSM, etc)
4. Return results to LLM

### Debug issues
Look for logs starting with:
- `[GenUiSurface]` - UI canvas messages
- `[A2UI]` - Message processor logs
- `[LLM Engine]` - Reasoning engine logs

## File Structure

```
lib/genui/
├── a2ui_message_processor.dart    ← Message handling & rendering
├── genui_surface.dart             ← Main UI canvas
├── genui_orchestrator.dart        ← (Old, being replaced)
├── component_catalog.dart         ← Components + schemas
└── llm_reasoning_engine.dart      ← Trip planning orchestrator

lib/services/
└── discovery_orchestrator.dart    ← OSM data fetching & slimming

lib/
├── phase5_home.dart               ← Entry point
├── config.dart                    ← Configuration + commonVibes
└── main.dart                      ← App root
```

## Current Limitations

1. **LLM is mocked** - Replace with real Gemini Nano
2. **Map is placeholder** - Need to integrate flutter_map
3. **No tool calling** - Can't execute tools yet
4. **Build is slow** - Incremental builds help

## Next Priority

**Phase 7: Real LLM Integration**
- Connect to Gemini Nano
- Implement tool calling
- Parse reasoning output
- Integrate flutter_map

## Useful Commands

```bash
# Format code
dart format lib/genui/*.dart

# Analyze
flutter analyze

# Run with logging
flutter run -d <device> -v 2>&1 | grep -E "\[|ERROR|WARN"

# Watch for changes
flutter run -d <device> --verbose

# Get device ID
flutter devices

# Clean everything
flutter clean
rm -rf build/
flutter pub get
```

## Debugging Tips

1. Check logs for `[GenUiSurface]`, `[A2UI]`, `[LLM Engine]`
2. Verify DiscoveryOrchestrator returns places
3. Check A2uiMessageProcessor message parsing
4. Ensure component schemas match LLM output
5. Test with simple examples first (1-2 places)

## Integration Checklist

- [ ] GenUiSurface navigates correctly
- [ ] DiscoveryOrchestrator fetches places
- [ ] A2uiMessageProcessor processes messages
- [ ] Components render without errors
- [ ] User can interact with UI
- [ ] No crashes or memory leaks
- [ ] Logging shows expected flow

## Documentation Files

- `PHASE_6_GENUI_IMPLEMENTATION.md` - Detailed architecture
- `PHASE_6_STATUS.md` - Current status & next steps
- This file - Quick reference

## Questions?

Check the detailed docs in the root directory. Every file has thorough comments and logging.
