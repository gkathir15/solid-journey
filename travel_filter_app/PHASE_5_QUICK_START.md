# Phase 5: GenUI Travel Agent - Quick Start
**Reference Date:** 2026-01-21T18:16:14.666Z

---

## 🚀 60-Second Overview

Build a Flutter app where:
1. **User** says "quiet history Prague 3 days"
2. **OSMService** fetches museums, cafes, historic sites
3. **DiscoveryProcessor** creates minified "vibe signatures" (e.g., `v:history,quiet;h:14thC;l:local`)
4. **LocalLLMService** (Gemini Nano) reasons: "These match your vibe"
5. **GenUI** renders: Interactive map + Day-by-day itinerary
6. **User** clicks "Add to Trip" → LLM re-plans → UI updates live

---

## 📊 Architecture in One Diagram

```
┌─────────────┐
│  User Input │ "Quiet history, 3 days, Prague"
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│   OSMService     │ Fetch attractions with tags
└──────┬───────────┘
       │ Raw OSM places
       ▼
┌──────────────────────────┐
│ DiscoveryProcessor       │ "v:history,quiet;h:14thC;l:local;f:yes"
└──────┬───────────────────┘
       │ Vibe signatures
       ▼
┌──────────────────────────┐
│  LocalLLMService         │ "These match your vibe because..."
│  (Gemini Nano)           │ Calls tools: OSMSlimmer, VibeAnalyzer, ClusterBuilder
└──────┬───────────────────┘
       │ A2UI JSON
       ▼
┌──────────────────────────┐
│  A2uiMessageProcessor    │ Parse A2UI blocks
└──────┬───────────────────┘
       │ Widget instructions
       ▼
┌──────────────────────────┐
│  GenUiSurface            │ Render: SmartMapSurface, RouteItinerary
│  (flutter_genui)         │
└──────────────────────────┘
```

---

## 🔑 Key Concepts

### Vibe Signature (Token-Efficient Representation)
```
Format: "v:vibe1,vibe2;attribute:value;..."

Examples:
✅ "v:history,quiet;h:14thC;l:local;f:yes;w:limited"
✅ "v:social,artsy;l:local;c:specialty_coffee;f:paid;w:yes"
✅ "v:nature,serene;natural:peak;f:no"

vs OLD (60 tokens):
❌ "historic=monastery, tourism=attraction, fee=yes, wheelchair=yes, operator=church, check_date=2023, ... 50 more tags"

NEW (6 tokens):
✅ "v:history,quiet;h:14thC;l:local;f:yes;w:limited"
```

### A2UI Protocol (AI-Generated UI)
LLM outputs JSON-formatted UI instructions:

```json
{
  "type": "SmartMapSurface",  // Widget type
  "payload": {                 // Data for widget
    "places": [...],
    "zoom": 14
  }
}
```

Only 3 widgets allowed (catalog):
1. **PlaceDiscoveryCard** - Individual place + vibe
2. **SmartMapSurface** - OSM map with pins
3. **RouteItinerary** - Day-by-day plan

---

## 🛠️ Implementation Checklist (Per Phase)

### Phase 5a: Data Services (Week 1)
```
□ OSMService.fetchAttractions()
  ├─ Query Overpass API
  ├─ Parse JSON response
  └─ Return PlaceData list

□ DiscoveryProcessor.processPlace()
  ├─ Extract heritage links
  ├─ Check localness
  ├─ Map activity vibes
  └─ Minify to signature: "v:...;l:...;h:...;f:...;w:..."

□ SpatialClusterer.clusterForItinerary()
  ├─ Find anchor points
  ├─ Group within 1km radius
  ├─ Create day clusters
  └─ Calculate distances

□ Logging at each step
  └─ [OSM], [DISCOVERY], [CLUSTER] prefixes
```

### Phase 5b: LLM Engine (Week 2)
```
□ LocalLLMService initialization
  ├─ Load Gemini Nano model
  ├─ Set system prompt
  └─ No API key needed (local inference)

□ Tool calling integration
  ├─ OSMSlimmer tool
  ├─ DistanceMatrix tool
  ├─ VibeAnalyzer tool
  └─ ClusterBuilder tool

□ A2UI output parsing
  └─ Extract ```a2ui ... ``` blocks from response

□ Logging all LLM interactions
  └─ [LLM_INPUT], [LLM_OUTPUT], [LLM_ERROR]
```

### Phase 5c: UI & GenUI (Week 3)
```
□ GenUI Widget Catalog
  ├─ PlaceDiscoveryCard builder
  ├─ SmartMapSurface builder
  └─ RouteItinerary builder

□ A2uiMessageProcessor
  ├─ Parse JSON messages
  ├─ Match to widget catalog
  └─ Build widget tree

□ DiscoverySurface
  ├─ Listen to user input
  ├─ Call OSM + LLM pipeline
  ├─ Capture widget interactions
  └─ Re-plan on interaction

□ Event handling
  └─ "Add to Trip", "Remove", "Swap", etc.
```

### Phase 5d: Integration & Testing (Week 4)
```
□ iOS simulator testing
□ Android device testing
□ Performance profiling
□ Token usage analysis
□ Offline map caching
□ Error handling & recovery
□ User interaction flows
```

---

## 💡 Code Entry Points

### 1. Start with OSMService
**File:** `lib/services/osm/osm_service.dart`

```dart
final osm = OSMService();
final places = await osm.fetchAttractions(
  city: 'Prague',
  categories: ['museum', 'cafe', 'historic'],
);
// Returns: [PlaceData(name, latitude, longitude, tags)]
```

### 2. Then DiscoveryProcessor
**File:** `lib/services/discovery/discovery_processor.dart`

```dart
final processor = DiscoveryProcessor();
final signatures = places.map((p) => processor.processPlace(p));
// Returns: VibeSignature(name, vibeSignature, latitude, longitude)
// Example signature: "v:history,quiet;h:14thC;l:local;f:yes"
```

### 3. Then SpatialClusterer
**File:** `lib/services/spatial/spatial_clusterer.dart`

```dart
final clusterer = SpatialClusterer();
final distMatrix = await osm.calculateDistanceMatrix(places);
final clusters = clusterer.clusterForItinerary(
  places: signatures,
  distanceMatrix: distMatrix,
  tripDuration: 3,
);
// Returns: [DayCluster(dayNumber, places, theme, totalDistance)]
```

### 4. Then LocalLLMService
**File:** `lib/services/ai/local_llm_service.dart`

```dart
final llm = LocalLLMService();
final response = await llm.planTrip(
  userInput: 'Quiet history Prague 3 days',
  discoveredPlaces: signatures,
  clusters: clusters,
);
// Returns: A2UI JSON for rendering
```

### 5. Finally A2uiMessageProcessor + GenUI
**File:** `lib/genui/a2ui_processor.dart` + `lib/screens/discovery_surface.dart`

```dart
final processor = A2uiMessageProcessor();
final widgets = await processor.parseMessages(llmResponse);
// Render widgets in GenUiSurface
```

---

## 🎯 Vibe Vocabulary

**Vibes** (the main categories user cares about):
- `history` - Ancient, medieval, heritage sites
- `nature` - Parks, viewpoints, natural beauty
- `social` - Cafes, bars, community spaces
- `culture` - Art, museums, galleries
- `quiet` - Peaceful, less crowded
- `artsy` - Street art, crafts, creative
- `adventurous` - Active, off-beaten-path
- `romantic` - Intimate, scenic, couples' spots

**Heritage** (historical periods):
- `14thC`, `17thC`, `18thC`, `medieval`, `roman`, `baroque`, `gothic`, etc.

**Localness**:
- `local` - Independent-owned, no global brand
- `chain` - Global brand (McDonald's, Starbucks, etc.)

**Fee**:
- `free`, `paid`, `donation`

**Accessibility**:
- `yes`, `limited`, `no`

---

## 📝 Logging Template

Copy-paste these logging statements at each layer:

```dart
// OSM Layer
print('[OSM] Fetching attractions for $city with categories: $categories');
print('[OSM] Fetched ${places.length} places');
for (var p in places.take(3)) {
  print('[OSM]   - ${p.name}: ${p.tags}');
}

// Discovery Layer
print('[DISCOVERY] Processing: ${place.name}');
print('[DISCOVERY] Signature: $signature');

// Clustering Layer
print('[CLUSTER] Creating $tripDuration-day clusters for ${places.length} places');
for (var dc in dayClusters) {
  print('[CLUSTER] $dc');
}

// LLM Layer
print('[LLM_INPUT] User: $userInput');
print('[LLM_INPUT] Places: ${places.length}, Clusters: ${clusters.length}');
print('[LLM_OUTPUT] Response length: ${response.length} chars');

// A2UI Layer
print('[A2UI] Parsing response of ${response.length} chars');
print('[A2UI] Parsed ${messages.length} messages');

// Widget Interaction Layer
print('[WIDGET_INTERACTION] Widget: $widgetId, Data: $data');
```

---

## 🧪 Quick Test Data

**Test City:** Prague
**Test Categories:** `['museum', 'cafe', 'historic', 'viewpoint']`
**Test User Vibe:** "Quiet history with local cafes"
**Test Duration:** 3 days

Expected output:
```
Day 1: Medieval monasteries + viewpoints
Day 2: Hidden museums + local cafes
Day 3: Street art + artisan shops
```

---

## 📚 Documentation Map

1. **PHASE_5_GENUI_ARCHITECTURE.md** ← Read this first for big picture
2. **PHASE_5_IMPLEMENTATION_REFERENCE.md** ← Copy code from here
3. **PHASE_5_LLM_TOOLS_AND_PROMPTS.md** ← Tool definitions & system prompts
4. **PHASE_5_QUICK_START.md** ← You are here!
5. **CONTEXT.md** ← Project context & current status

---

## 🚨 Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| A2UI JSON parse fails | Ensure ```a2ui ... ``` blocks contain valid JSON |
| LLM output has no A2UI blocks | Check system prompt is set correctly |
| Distances show 0km | Implement Haversine formula properly |
| Widget not rendering | Check WidgetCatalog has matching widget type |
| Token limits exceeded | Filter top-N places before sending to LLM |
| Vibe signature too long | Use abbreviations: "v:", "l:", "h:", etc. |

---

## ✅ Success Criteria

Phase 5 is complete when:
- [ ] User enters "3 days, quiet history Prague"
- [ ] OSM fetches 15+ relevant places
- [ ] Each place has vibe signature like "v:history,quiet;h:14thC;..."
- [ ] Clusterer groups into 3 day clusters
- [ ] LLM analyzes and outputs A2UI JSON
- [ ] App renders SmartMapSurface + RouteItinerary
- [ ] All interactions logged with [PREFIX] tags
- [ ] User can click "Add to Trip" and see live re-planning

---

## 🔗 Quick Links

- **Google Generative AI Docs**: https://ai.google.dev/
- **flutter_genui Package**: https://pub.dev/packages/flutter_genui
- **OpenStreetMap Overpass API**: https://overpass-turbo.eu/
- **MediaPipe LLM Inference**: https://developers.google.com/mediapipe/solutions/genai/llm_inference

---

**Print this page for your desk! Phase 5 starts now. 🚀**
