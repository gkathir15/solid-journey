# Phase 5: Complete Implementation Guide

## 📖 Table of Contents
1. Architecture Overview
2. Component Descriptions
3. Data Flow Examples
4. Logging Output Examples
5. Testing Instructions
6. Troubleshooting

---

## 1️⃣ Architecture Overview

### Three-Tier System

```
┌──────────────────────────────────────────────────────────┐
│                     UI Layer (GenUI)                     │
│                                                          │
│  Phase5Home ─────────────► GenUiSurface ─────────────┐  │
│  (Selection)               (Planning)                 │  │
│  ├─ Country                ├─ Calls orchestrate()     │  │
│  ├─ City                   ├─ Shows RouteItinerary    │  │
│  ├─ Duration               ├─ Renders via GenUI       │  │
│  └─ Vibes                  └─ Handles interactions    │  │
│                                                 │      │  │
└─────────────────────────────────────────────────┼──────┘  │
                                                  │          │
                  Discovery Orchestrator          │          │
                         │◄──────────────────────┘          │
                         │                                   │
                    ┌────▼─────┐                            │
                    │ PIPELINE  │                            │
                    │ ──────────│                            │
┌────────────────────────────────────────────────────────────┤│
│ Intelligence Layer                                         ││
│                                                            ││
│  HARVEST ─►  PROCESS  ─►  REASON  ─►  DELIVER            ││
│     │            │            │           │               ││
│  OSM Data   Vibe Sigs     LLM Logic   Day Clusters        ││
│  (342 items)  (342)       (45 matches)  (3 days)          ││
└────────────────────────────────────────────────────────────┤│
                                                             ││
┌──────────────────────────────────────────────────────────┐ │
│ Data Layer                                               │ │
│  ├─ OpenStreetMap (Overpass API)                        │ │
│  ├─ Haversine Distance Calculations                     │ │
│  ├─ Local LLM (Gemma/MediaPipe)                         │ │
│  └─ Logging & Telemetry                                 │ │
└──────────────────────────────────────────────────────────┘ │
```

### Key Classes

| Class | Purpose | File |
|-------|---------|------|
| **Phase5Home** | Selection UI (country, city, duration, vibes) | `lib/phase5_home.dart` |
| **GenUiSurface** | Main canvas for AI-driven UI | `lib/genui/genui_orchestrator.dart` |
| **GenUiOrchestrator** | A2UI message routing & rendering | `lib/genui/genui_orchestrator.dart` |
| **ComponentCatalog** | Widget schemas & definitions | `lib/genui/component_catalog.dart` |
| **DiscoveryOrchestrator** | Main pipeline orchestration | `lib/services/discovery_orchestrator.dart` |
| **UniversalTagHarvester** | Fetch OSM data | `lib/services/universal_tag_harvester.dart` |
| **SemanticDiscoveryEngine** | Create vibe signatures | `lib/services/semantic_discovery_engine.dart` |
| **LLMDiscoveryReasoner** | LLM pattern analysis | `lib/services/llm_discovery_reasoner.dart` |
| **SpatialClusteringService** | Group attractions by day | `lib/services/spatial_clustering_service.dart` |

---

## 2️⃣ Component Descriptions

### Phase5Home Widget

**Purpose**: User selection interface

**Flow**:
```dart
Phase5Home
  ├─ Build UI with selectors
  ├─ Update state on user input
  └─ Navigate to GenUiSurface on "Plan" click
```

**State Variables**:
```dart
String _selectedCountry = 'France';           // Country
String _selectedCity = 'Paris';               // City
List<String> _selectedVibes = [...]           // User preferences
int _selectedDuration = 3;                    // Trip days
```

**User Actions**:
1. Choose country from chips
2. Enter city name
3. Adjust duration slider
4. Select vibes (multi-select)
5. Tap "Generate Itinerary"

### GenUiSurface Widget

**Purpose**: AI-driven planning interface

**Lifecycle**:
```
initState()
  ↓
_generatePlan() called
  ↓
Calls: DiscoveryOrchestrator.orchestrate()
  ├─ Receives itinerary JSON
  ├─ Creates RouteItinerary widget
  └─ setState() to render
  ↓
build() renders RouteItinerary
```

**Key Methods**:
- `_generatePlan()`: Triggers discovery pipeline
- `_buildBody()`: Handles loading, error, and display states

### Component Catalog

**Available Components**:
1. **PlaceDiscoveryCard**: Individual attraction with vibe tags
2. **RouteItinerary**: Day-by-day itinerary breakdown
3. **SmartMapSurface**: Map visualization (placeholder for now)
4. **VibeSelector**: Interactive vibe chooser

**JSON Schema Example** (PlaceDiscoveryCard):
```json
{
  "type": "object",
  "properties": {
    "name": {"type": "string"},
    "vibe": {"type": "array", "items": {"type": "string"}},
    "distance": {"type": "number"},
    "rating": {"type": "number"},
    "osmId": {"type": "string"}
  },
  "required": ["name", "vibe", "osmId"]
}
```

### GenUiOrchestrator

**Purpose**: Bridge between AI and UI

**Methods**:
- `renderComponent(Map a2uiMessage)`: Parse AI message → render widget
- `onComponentInteraction(String type, dynamic data)`: Handle user interactions

**Flow**:
```
AI generates JSON
  ↓
GenUiOrchestrator.renderComponent(json)
  ├─ Identifies component type
  ├─ Extracts data
  └─ Routes to appropriate builder
  ↓
Flutter widget renders
  ↓
User interaction
  ↓
onComponentInteraction()
  └─ (Future: Send back to LLM for re-planning)
```

---

## 3️⃣ Data Flow Examples

### Complete User Journey

```
USER INPUT:
  Country: France
  City: Paris
  Duration: 3
  Vibes: [historic, local, cultural]

PHASE 1: HARVEST
  UniversalTagHarvester.harvestAllTags()
    ↓
  Query Overpass API:
    [out:json][timeout:30];
    {{geocodeArea:Paris}}->.searchArea;
    (
      nwr["tourism"~"museum|..."] (area.searchArea);
      nwr["amenity"~"cafe|..."] (area.searchArea);
      ...
    );
    out center;
    ↓
  Raw Elements (342 items):
    [
      {
        "id": "node:123",
        "name": "Louvre",
        "lat": 48.861,
        "lon": 2.336,
        "tags": {"tourism": "museum", "name": "Louvre", ...}
      },
      ...
    ]

PHASE 2: PROCESS
  SemanticDiscoveryEngine.processElement() for each item
    ↓
  Raw element tags → Vibe signature
    {
      "id": "node:123",
      "name": "Louvre",
      "lat": 48.861,
      "lon": 2.336,
      "compactSignature": "v:museum,historic,cultural,family,free",
      "metadata": {
        "category": "museum",
        "localness": "global_brand",
        "heritage": null,
        "rating": 4.8
      }
    }
    ↓
  Vibe Signatures (342 total)

PHASE 3: REASON
  LLMDiscoveryReasoner.discoverAttractionsForVibe()
    Input:
      - userVibe: "historic, local, cultural"
      - userContext: "Trip planning for France"
      - attractions: [342 signatures]
    ↓
  LLM analyzes:
    "User likes historic (18thC-20thC), local (not international brands),
     cultural (museums, galleries, heritage sites).
     Find matching signatures and hidden gems."
    ↓
  LLM Output:
    {
      "primaryRecommendations": [
        {
          "name": "Louvre",
          "lat": 48.861,
          "lon": 2.336,
          "vibe": ["museum", "historic", "cultural"],
          "rating": 4.8,
          "reason": "Iconic 18th-century palace-turned-museum"
        },
        ... (44 more)
      ],
      "hiddenGems": [
        {
          "name": "Musée Rodin",
          "vibe": ["historic", "local", "artistic"],
          "reason": "1730s mansion with sculptures garden"
        },
        ... (11 more)
      ]
    }

PHASE 4: CLUSTER
  SpatialClusteringService.createDayClustersByCount()
    Input: 45 primary recommendations + 12 gems, duration=3 days
    ↓
  Group into 3 clusters:
    - Day 1: 19 attractions (~6.3 per day)
    - Day 2: 19 attractions
    - Day 3: 19 attractions
    ↓
  Calculate distances (haversine):
    Day 1 Total: 5.2 km
    Day 2 Total: 4.8 km
    Day 3 Total: 5.1 km
    ↓
  Generate themes:
    Day 1: "Historic Journey"
    Day 2: "Cultural Deep Dive"
    Day 3: "Local Hidden Gems"

PHASE 5: DELIVER
  Format as RouteItinerary JSON:
    {
      "days": [
        {
          "dayNumber": 1,
          "theme": "Historic Journey",
          "places": [
            {
              "name": "Notre-Dame",
              "order": 1,
              "vibe": ["historic", "religious", "architecture"],
              "reason": "Perfect 12th-century Gothic architecture"
            },
            {
              "name": "Sainte-Chapelle",
              "order": 2,
              "vibe": ["historic", "local", "cultural"],
              "reason": "13th-century local gem with stained glass"
            },
            ... (more)
          ],
          "totalDistance": 5.2
        },
        ... (Day 2 & 3)
      ],
      "tripSummary": "Your 3-day journey through Paris..."
    }
    ↓
  GenUiSurface receives itinerary
    ↓
  RouteItinerary widget renders
    ↓
  User sees day-by-day plan with reasons
```

### Vibe Signature Example

**Raw OSM Data**:
```xml
<way id="123456">
  <nd ref="1"/>
  <nd ref="2"/>
  <tag k="name" v="Musée Rodin"/>
  <tag k="tourism" v="museum"/>
  <tag k="building" v="museum"/>
  <tag k="heritage" v="site"/>
  <tag k="heritage_type" v="historic"/>
  <tag k="start_date" v="1730"/>
  <tag k="operator" v="Centre des monuments nationaux"/>
  <tag k="wheelchair" v="yes"/>
  <tag k="architecture" v="neoclassical"/>
</way>
```

**Processing**:
```
SemanticDiscoveryEngine.processElement()
  ├─ Extract tourism tag → category: "museum"
  ├─ Detect heritage tag + date → heritage: "1730s"
  ├─ Check operator (not global brand) → localness: "independent"
  ├─ Check wheelchair access → accessibility: "yes"
  └─ Build signature
    
Result:
  {
    "name": "Musée Rodin",
    "compactSignature": "v:museum,historic,cultural,1730s,accessible,neoclassical",
    "metadata": {
      "category": "museum",
      "heritage": "1730",
      "architecture": "neoclassical",
      "localness": "independent",
      "accessibility": "yes"
    }
  }
```

---

## 4️⃣ Logging Output Examples

### Full Pipeline Log

```
[INFO] Phase5Home: 🎯 Starting trip planning: Paris, France - Duration: 3 days - Vibes: [historic, local, cultural]

[INFO] GenUiSurface: [GenUiSurface] Generating plan for Paris, France with vibes: [historic, local, cultural]

[INFO] DiscoveryOrchestrator: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[INFO] DiscoveryOrchestrator: 🔍 DISCOVERY ORCHESTRATOR STARTING
[INFO] DiscoveryOrchestrator: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[INFO] DiscoveryOrchestrator: City: Paris
[INFO] DiscoveryOrchestrator: Categories: [tourism, amenity, leisure]
[INFO] DiscoveryOrchestrator: User Vibe: historic, local, cultural
[INFO] DiscoveryOrchestrator: Context: Trip planning for France
[INFO] DiscoveryOrchestrator: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] DiscoveryOrchestrator: 
[INFO] DiscoveryOrchestrator: PHASE 1: HARVESTING OSM METADATA
[INFO] DiscoveryOrchestrator: ─────────────────────────────────────────────
[INFO] UniversalTagHarvester: Fetching attractions for Paris...
[INFO] UniversalTagHarvester: ✅ Fetched 342 attractions
[INFO] DiscoveryOrchestrator: ✅ Harvested 342 elements

[INFO] DiscoveryOrchestrator: 
[INFO] DiscoveryOrchestrator: PHASE 2: PROCESSING INTO VIBE SIGNATURES
[INFO] DiscoveryOrchestrator: ─────────────────────────────────────────────
[INFO] SemanticDiscoveryEngine: Processing 342 elements...
[INFO] SemanticDiscoveryEngine: ✅ Created 342 signatures
[INFO] DiscoveryOrchestrator: ✅ Created 342 vibe signatures
[INFO] DiscoveryOrchestrator: 
[INFO] DiscoveryOrchestrator: SAMPLE SIGNATURES:
[INFO] DiscoveryOrchestrator:   Louvre: v:museum,historic,cultural,family,free
[INFO] DiscoveryOrchestrator:   Notre-Dame: v:historic,religious,cultural,architecture
[INFO] DiscoveryOrchestrator:   Musée d'Orsay: v:museum,impressionism,cultural,19thC
[INFO] DiscoveryOrchestrator:   Sainte-Chapelle: v:historic,religious,local,13thC
[INFO] DiscoveryOrchestrator:   Arc de Triomphe: v:monument,historic,iconic,19thC

[INFO] DiscoveryOrchestrator: 
[INFO] DiscoveryOrchestrator: PHASE 3: LLM DISCOVERY REASONING
[INFO] DiscoveryOrchestrator: ─────────────────────────────────────────────
[INFO] LLMDiscoveryReasoner: [LLM INPUT]
[INFO] LLMDiscoveryReasoner: User Vibe: historic, local, cultural
[INFO] LLMDiscoveryReasoner: Context: Trip planning for France
[INFO] LLMDiscoveryReasoner: Attractions: 342 signatures
[INFO] LLMDiscoveryReasoner: 
[INFO] LLMDiscoveryReasoner: Analyzing patterns...
[INFO] LLMDiscoveryReasoner: [LLM OUTPUT]
[INFO] LLMDiscoveryReasoner: Matched 45 primary recommendations
[INFO] LLMDiscoveryReasoner: Found 12 hidden gems
[INFO] DiscoveryOrchestrator: ✅ Found 45 primary + 12 hidden gems

[INFO] DiscoveryOrchestrator: 
[INFO] DiscoveryOrchestrator: PHASE 4: FINAL DISCOVERY OUTPUT
[INFO] DiscoveryOrchestrator: ─────────────────────────────────────────────

[INFO] SpatialClusteringService: 📍 Creating 3 day clusters from 45 attractions
[INFO] SpatialClusteringService: ✅ Created 3 day clusters

[INFO] DiscoveryOrchestrator: ✅ DISCOVERY COMPLETE
[INFO] DiscoveryOrchestrator: 
[INFO] DiscoveryOrchestrator: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[INFO] DiscoveryOrchestrator: FINAL RESULTS:
[INFO] DiscoveryOrchestrator:   Total Analyzed: 342
[INFO] DiscoveryOrchestrator:   Primary Recommendations: 45
[INFO] DiscoveryOrchestrator:   Hidden Gems: 12
[INFO] DiscoveryOrchestrator: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] DiscoveryOrchestrator: 🎯 ORCHESTRATE: Planning France/Paris - Vibes: [historic, local, cultural]
[INFO] DiscoveryOrchestrator: Creating 3-day itinerary...
[INFO] DiscoveryOrchestrator: ✅ Itinerary generated: 3 days

[INFO] GenUiSurface: [GenUiSurface] Itinerary generated: 3 days
```

### Component Rendering Log

```
[INFO] GenUI: [GenUI] Rendering component: RouteItinerary with data: {"days": [...], ...}

[INFO] GenUI: [GenUI] Component interaction: VibeSelector with data: ["historic", "local", "cultural"]
```

---

## 5️⃣ Testing Instructions

### Test 1: Selection UI

**Steps**:
1. Run app: `flutter run -d macos`
2. Verify Phase5Home loads
3. Test country selector
4. Test city input
5. Test duration slider
6. Test vibe selector

**Expected**:
- All widgets render
- State updates on user interaction
- Button enabled only with vibes selected

### Test 2: Discovery Pipeline

**Steps**:
1. Select Paris, 3 days, [historic, local]
2. Tap "Generate Itinerary"
3. Check console logs

**Expected**:
- HARVEST logs show ~300+ elements
- PROCESS logs show signature samples
- REASON logs show 40+ matches
- DELIVER logs show final itinerary

### Test 3: GenUI Rendering

**Steps**:
1. Observe RouteItinerary widget on screen
2. Verify day clusters appear
3. Check theme names
4. Verify place reasons

**Expected**:
- 3 day cards visible
- Attractions listed with reasons
- Distances shown per day

### Test 4: Logging Transparency

**Steps**:
1. Enable verbose logging
2. Run full journey
3. Grep logs for "[LLM INPUT]" and "[LLM OUTPUT]"

**Expected**:
- Clear LLM input visible
- Clear LLM output visible
- Fully transparent discovery process

---

## 6️⃣ Troubleshooting

### Issue: App crashes on startup

**Solution**:
```bash
flutter clean
flutter pub get
flutter run -d macos
```

### Issue: Discovery takes > 30 seconds

**Solution**:
- Overpass API timeout: Check internet connection
- LLM inference timeout: Increase timeout in LLMDiscoveryReasoner

### Issue: No attractions returned

**Solutions**:
1. Check city name is correct (Paris, Rome, Barcelona, etc)
2. Verify Overpass API is accessible
3. Check ` _log.info()` output for Harvester errors

### Issue: Incorrect day grouping

**Solution**:
- Check `SpatialClusteringService.createDayClustersByCount()` logic
- Verify haversine distance calculation
- Test with known coordinates

### Issue: LLM not reasoning correctly

**Solution**:
- Check `LLMDiscoveryReasoner` prompt
- Verify vibe signatures are correct
- Look at LLM INPUT/OUTPUT logs

---

## 📋 Checklist for Phase 5 Completion

- [x] Phase5Home UI fully functional
- [x] GenUI Orchestrator routing all components
- [x] Discovery pipeline HARVEST → PROCESS → REASON → DELIVER
- [x] Spatial clustering creates day-based groups
- [x] Full logging with phase-based output
- [x] JSON schema for all components
- [x] A2UI protocol support
- [x] Vibe signature system working
- [x] Error handling in all critical paths
- [x] Type-safe Dart code (no warnings)
- [x] Git commits with clear messages

---

**Next**: Phase 6 (Map Integration with flutter_map + OSM tiles)

