# PHASE 6: GenUI Integration & LLM Reasoning Engine

## Overview
Phase 6 implements the complete **AI-First GenUI System** with:
1. **A2UI Protocol** - AI-to-UI message passing with dynamic component rendering
2. **LLM Reasoning Engine** - Local Gemini Nano coordinating spatial reasoning
3. **GenUI Surface** - Main canvas for dynamic UI generation
4. **Component Catalog** - Predefined widget schemas for AI to use

## Architecture

### 1. Component Catalog (`component_catalog.dart`)
Defines all widgets the LLM can generate:
- **PlaceDiscoveryCard**: Single place with vibes, rating, description
- **SmartMapSurface**: OSM map with place pins and vibe filters
- **RouteItinerary**: Day clusters with sequential places and reasons
- **VibeSelector**: User preference selection UI

Each component has:
- JSON Schema for AI to understand required fields
- Flutter Widget implementation for rendering
- Type safety with factory constructors

### 2. A2UI Message Processor (`a2ui_message_processor.dart`)
Handles AI-to-UI message protocol:

```
Message Types:
├─ surface_update: Update overall UI state
├─ component_render: Render a single component
├─ data_model_update: Update internal state
└─ sequence: Render multiple components in order
```

Flow:
1. LLM generates structured JSON message
2. Message processor parses and validates
3. Component is rendered based on type
4. User interaction is captured and sent back to LLM

Key Methods:
- `processLLMMessage(String llmOutput)` - Parse AI output and render
- `handleUserInteraction(String eventType, Map eventData)` - Capture user actions
- `buildCurrentComponent()` - Render the current component

### 3. GenUI Surface (`genui_surface.dart`)
Main widget container for the UI:

Flow:
```
GenUiSurface
  ├─ Initialize DiscoveryOrchestrator
  ├─ Call Orchestrate (fetch + slim OSM data)
  ├─ Generate initial UI messages
  ├─ Consumer<A2uiMessageProcessor>
  └─ Render current component
```

Features:
- Loading state with progress
- Error handling with retry
- Regenerate button for LLM re-reasoning
- Real-time message processing

### 4. LLM Reasoning Engine (`llm_reasoning_engine.dart`)
Coordinates end-to-end trip planning:

```
planTrip()
  ├─ STEP 1: Discover places
  │   └─ Call DiscoveryOrchestrator.orchestrate()
  ├─ STEP 2: LLM reasoning
  │   └─ Reason about spatial clustering
  ├─ STEP 3: Generate UI messages
  │   └─ Create A2UI messages
  └─ STEP 4: Render
      └─ Process messages
```

The engine:
- Uses DiscoveryOrchestrator for rich OSM data + vibe signatures
- Calls LLM to reason about patterns (mock for now, real when integrated)
- Generates A2UI messages for dynamic UI
- Handles spatial clustering into day groups

## Integration Points

### With DiscoveryOrchestrator
```dart
// The LLM engine uses discovery to get slimmed data
final result = await discoveryOrchestrator.orchestrate(
  city: city,
  country: country,
  userVibes: userVibes,
);
```

### With Local LLM (Future)
```dart
// When real LLM is available:
final reasoning = await localLLM.reason(prompt);
// Parse reasoning and generate UI messages
```

### With User Interactions
```dart
// User taps "Add to Trip"
await messageProcessor.handleUserInteraction('add_to_trip', {
  'placeId': placeId,
  'day': dayNumber,
});
// This is sent back to LLM for re-reasoning
```

## Data Flow

```
User Input (City, Vibes, Days)
         ↓
GenUiSurface initializes
         ↓
LLMReasoningEngine.planTrip()
         ↓
DiscoveryOrchestrator.orchestrate()
  ├─ TagHarvester (fetch OSM)
  ├─ DiscoveryEngine (slim + signature)
  └─ Returns rich data with vibes
         ↓
LLM Reasoning (analyze patterns)
         ↓
Generate A2UI Messages
         ↓
A2uiMessageProcessor
         ↓
GenUiSurface renders components
         ↓
User interacts
         ↓
Event sent back to LLM
         ↓
LLM re-reasons
         ↓
New UI rendered
```

## Key Features

### 1. Vibe-Based Discovery
- OSM data has rich metadata (tags)
- Slimmed into "vibe signatures" (e.g., "h:c:20th;l:indie;n:nature")
- LLM reasons about patterns based on signatures

### 2. Spatial Clustering
- Places within 1km grouped into "clusters"
- Each cluster becomes a potential "day"
- Prioritize based on user vibes and distance

### 3. Transparent Logging
Every step logs:
- Input data
- Processing steps
- Output results
- Errors with context

### 4. Dynamic UI
- LLM decides which components to show
- User can interact → LLM reasons again
- No fixed UI layout

## Usage Example

```dart
// In your screen
GenUiSurface(
  city: 'Paris',
  country: 'France',
  userVibes: ['historic', 'cafe_culture', 'street_art'],
  tripDays: 3,
)
```

This will:
1. Fetch OSM places for Paris
2. Create vibe signatures
3. Use LLM to reason about day clusters
4. Render dynamic UI with place cards, map, itinerary

## Next Steps

1. **Real LLM Integration**
   - Replace mock reasoning with actual Gemini Nano calls
   - Implement tool calling for OSM queries
   - Handle streaming responses

2. **Tool Calling**
   - LLM can call `fetchAttractions(city, categories)`
   - LLM can call `calculateDistanceMatrix(places)`
   - Results flow back to reasoning

3. **Interactive Flow**
   - User edits preferences → re-reasoning
   - User saves itinerary → persist to local storage
   - User exports → PDF or sharing

4. **Map Integration**
   - Replace placeholder SmartMapSurface with actual flutter_map
   - Show route between places
   - Cache tiles for offline

5. **Performance Optimization**
   - Pagination for large place lists
   - Caching of discovery results
   - Background LLM reasoning

## Files Created

1. `/lib/genui/a2ui_message_processor.dart` - A2UI protocol handler
2. `/lib/genui/genui_surface.dart` - Main UI canvas
3. `/lib/genui/llm_reasoning_engine.dart` - Trip planning orchestrator
4. Updated `/lib/config.dart` - Added commonVibes list

## Testing Checklist

- [ ] GenUiSurface initializes correctly
- [ ] DiscoveryOrchestrator called with correct parameters
- [ ] A2uiMessageProcessor parses LLM output
- [ ] Components render without errors
- [ ] User interactions captured
- [ ] Error handling works
- [ ] Logging shows expected flow
- [ ] No memory leaks or crashes
