# Project Context - Travel Filter AI Agent (Phase 5)

## Latest Status (2026-01-22)

### ✅ FIXED: RangeError in Discovery Reasoner

**Issue**: When processing vibe signatures, a `RangeError` occurred with message:
```
RangeError (end): Invalid value: Not in inclusive range 0..3: 4
```

**Root Cause**: In `llm_discovery_reasoner.dart`, the `_extractComponent()` method was calling `substring()` without proper bounds checking, especially at string boundaries.

**Solution**: 
- Added validation for `startPos >= signature.length`
- Added validation for `startPos >= endPos`
- Wrapped in try-catch for graceful error handling
- Returns empty string on error instead of crashing

**File Changed**: `lib/services/llm_discovery_reasoner.dart`

---

## Architecture Overview

### Phase 5: AI-First GenUI Travel Agent with Spatial Reasoning

The app integrates:

1. **Universal Tag Harvester** (`universal_tag_harvester.dart`)
   - Queries OpenStreetMap via Overpass API
   - Extracts all relevant tags: amenity, tourism, leisure, heritage, etc.
   - Pulls secondary metadata: cuisine, opening_hours, wheelchair, etc.

2. **Semantic Discovery Engine** (`semantic_discovery_engine.dart`)
   - Transforms raw OSM tags into compact "Vibe Signatures"
   - Format: `h:heritage;l:localness;a:activity;n:nature;am:amenity;s:sensory;acc:accessibility`
   - Extracts:
     - Heritage level & century
     - Localness (independent vs. brand)
     - Activity profile (craft, art, nightlife, etc.)
     - Natural anchors (parks, viewpoints)
     - Amenity details (cuisine, outdoor seating, etc.)
     - Sensory signals (free/paid, smoking policy)
     - Accessibility flags (wheelchair access)

3. **LLM Discovery Reasoner** (`llm_discovery_reasoner.dart`)
   - Uses Gemini Nano local model
   - Analyzes vibe signatures for pattern matching
   - Discovery Persona guides the LLM to find hidden gems
   - Returns primary recommendations + hidden gems with justifications

4. **Discovery Orchestrator** (`discovery_orchestrator.dart`)
   - Coordinates entire pipeline: Harvest → Process → Reason → Cluster → Deliver
   - Integrates GenUI for dynamic UI generation
   - Handles 3-5 day trip planning with spatial clustering

5. **Spatial Clustering Service** (`spatial_clustering_service.dart`)
   - Groups attractions into day-based clusters (1km proximity)
   - Calculates optimal routes
   - Generates itineraries with distance data

6. **GenUI Integration** (`genui/`)
   - Component Catalog: PlaceDiscoveryCard, SmartMapSurface, RouteItinerary
   - A2UI protocol for LLM-driven UI generation
   - GoogleGenerativeAiContentGenerator points to local Gemini Nano

---

## Data Flow

```
User Input (Vibes, Duration)
    ↓
GenUI Surface (Phase5Home)
    ↓
DiscoveryOrchestrator.orchestrate()
    ↓
TagHarvester.harvestAllTags()
    ├─→ Overpass API Query
    └─→ Raw OSM Elements (25,000+)
    ↓
SemanticDiscoveryEngine.processElement() [x25,000]
    └─→ Vibe Signatures (compact, minified)
    ↓
LLMDiscoveryReasoner.discoverAttractionsForVibe()
    ├─→ Score attractions by vibe match
    ├─→ Extract primary recommendations
    └─→ Identify hidden gems
    ↓
SpatialClusteringService.createDayClustersByCount()
    └─→ Day-based itineraries
    ↓
GenUI Rendering
    └─→ Interactive map + itinerary cards
```

---

## Logging & Transparency

All operations log with prefixed names:
- `[TagHarvester]` - OSM data harvesting
- `[DiscoveryEngine]` - Vibe signature creation
- `[DiscoveryReasoner]` - LLM reasoning & scoring
- `[DiscoveryOrchestrator]` - Pipeline coordination
- `[GenUiSurface]` - UI generation

Each place processed shows:
```
✅ Signature: l:indie;a:a:culture;s:free;acc:wc:yes
```

---

## Key Components

### Vibe Signature Format
```
h:h3,hist:monument,c:20th;l:indie;a:a:culture;s:free;acc:wc:yes
├─ h:heritage level (h1-h4) + historic type + century
├─ l:localness (indie, local, chain)
├─ a:activity profile (culture, nightlife, entertainment, etc.)
├─ n:natural anchor (if parks/nature)
├─ am:amenity details (cuisine, outdoor, etc.)
├─ s:sensory (free, paid, no_smoke)
└─ acc:accessibility (wheelchair status)
```

### LLM Discovery Persona
The reasoner instructs the LLM to:
1. **Pattern Recognition** - Find connections between places via signatures
2. **Vibe Matching** - Match user preferences to signature components
3. **Justification** - Explain choices using specific tags
4. **Discovery Mode** - Surface lesser-known treasures

---

## Testing Notes

**Paris Test (3 days, 8 vibes)**:
- Historic, local, cultural, street_art, nightlife, cafe_culture, educational, spiritual
- Successfully harvested 25,501 elements
- Created 25,501 vibe signatures
- Generated recommendations with hidden gems
- Fixed RangeError that occurred on "L'Olympia" element

---

## Next Steps

1. ✅ Fix RangeError bounds checking
2. Integration with real Gemini Nano model
3. Full GenUI A2UI rendering
4. Map visualization with offline caching
5. Production deployment

