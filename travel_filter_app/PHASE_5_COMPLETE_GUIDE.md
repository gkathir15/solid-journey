# Phase 5: AI-First Travel Agent - Complete Implementation Guide

## Overview
This guide covers the end-to-end implementation of an AI-first travel planning system with:
- **Local LLM** (Gemini Nano/Gemma) for intelligent decision-making
- **OSM Data Discovery Engine** with semantic tag parsing
- **GenUI Integration** for AI-driven dynamic UI generation
- **Spatial Clustering** for trip planning

---

## Architecture Layers

### Layer 1: Data Discovery & Slimming
**Purpose**: Extract rich OSM data, create compact "vibe signatures", minimize token usage

**Components**:
1. **UniversalTagHarvester** (`universal_tag_harvester.dart`)
   - Queries Overpass API for all relevant tags: amenity, tourism, historic, leisure, heritage, shop, craft, natural
   - Pulls secondary metadata: cuisine, diet:*, operator, opening_hours, fee, wheelchair, architecture, artist, start_date

2. **SemanticDiscoveryEngine** (`semantic_discovery_engine.dart`)
   - Transforms raw OSM tags into "Vibe Signatures"
   - Logic:
     * Heritage Link: Extract century/style from historic/heritage tags
     * Localness Test: Check brand vs operator (independent = local flag)
     * Activity Profile: Map leisure tags to social vibes
     * Natural Anchor: Identify viewpoints, peaks, parks as serene spots
   - Output: Compact string like `v:nature,quiet,free|heritage:18thC|local:true`

3. **DiscoveryProcessor** (`semantic_discovery_engine.dart`)
   - Minifies findings into token-efficient format
   - Reduces verbosity while preserving semantic richness

### Layer 2: LLM Reasoning Engine
**Purpose**: Use local LLM to analyze discovered patterns and make planning decisions

**Components**:
1. **LLMDiscoveryReasoner** (`llm_discovery_reasoner.dart`)
   - Configured with Discovery Persona system prompt
   - Receives vibe signatures and user preferences
   - Outputs spatial groupings and recommendations with justifications
   - Example output: "I chose this 1900s local bookstore with café because it matches your 'Quiet History' preference and is within walking distance of the museum"

2. **TravelAgentService** (`travel_agent_service.dart`)
   - Coordinates LLM calls
   - Implements tool calling for OSM data access
   - Manages conversation context

### Layer 3: GenUI Component Layer
**Purpose**: AI generates dynamic UI based on reasoning

**Components**:
1. **ComponentCatalog** (`genui/component_catalog.dart`)
   - Defines 4 core widgets:
     * `PlaceDiscoveryCard`: Single place with vibe tags, rating, distance
     * `RouteItinerary`: Day clusters with ordered places and reasoning
     * `SmartMapSurface`: OSM map with place pins and route
     * `VibeSelector`: User preference selection interface
   - Includes JSON schemas for AI to know exact data structure

2. **GenUiOrchestrator** (`genui/genui_orchestrator.dart`)
   - Listens to LLM output (A2UI protocol messages)
   - Maps component names to widget constructors
   - Handles user interactions and sends back to LLM
   - Main container: `GenUiSurface`

### Layer 4: Orchestration & Spatial Logic
**Purpose**: Coordinate all layers, implement clustering

**Components**:
1. **DiscoveryOrchestrator** (`services/discovery_orchestrator.dart`)
   - Master coordinator
   - Flow: OSM Fetch → Vibe Signature Generation → LLM Reasoning → GenUI Rendering
   - Implements spatial clustering:
     * Groups places within 1km as single "cluster"
     * Prioritizes famous/rated spots as "Anchor Points"
     * Creates balanced day itineraries

---

## Step-by-Step Implementation Flow

### Phase 5.1: Data Collection
1. User selects city/country
2. **UniversalTagHarvester.fetchAttractions()** calls Overpass API
   ```
   [out:json][timeout:30];
   {{geocodeArea:{{city}}}}->.searchArea;
   ( nwr["tourism"~"museum|attraction"](area.searchArea);
     nwr["amenity"~"cafe|church"](area.searchArea); );
   out center;
   ```
3. Results: ~200-500 raw place objects with full tag metadata

### Phase 5.2: Semantic Minification
1. **SemanticDiscoveryEngine.processPlaces()** transforms each place
2. Raw: `{name: "X", tourism: "museum", historic: "yes", start_date: "1850", architect: "Y", ...}`
3. Output: `{name: "X", v: "historic,cultural,quiet|heritage:1850s|independent:true"}`
4. Token count reduced by 70-80%

### Phase 5.3: LLM Spatial Reasoning
1. **LLMDiscoveryReasoner.analyzeAndCluster()** processes minified places
2. System prompt: 
   ```
   "You are a Spatial Planner. Analyze these places and their vibe signatures.
    Group them into Day Clusters where places within 1km are visited together.
    Prioritize high-rated or famous spots as Anchor Points.
    Return a JSON itinerary with daily themes and place ordering."
   ```
3. LLM output (via tool_use):
   ```json
   {
     "days": [
       {
         "dayNumber": 1,
         "theme": "Historic City Center",
         "places": [
           {"name": "Museum", "order": 1, "reason": "Famous anchor point..."},
           {"name": "Historic Square", "order": 2, "reason": "Adjacent, complements..."}
         ]
       }
     ]
   }
   ```

### Phase 5.4: GenUI Rendering
1. **GenUiOrchestrator.renderComponent()** receives LLM itinerary
2. Converts JSON → `RouteItinerary` widget with `DayCluster` objects
3. User sees interactive timeline with place cards

### Phase 5.5: User Interaction Loop
1. User taps "Add to Favorites" on a place card
2. `GenUiSurface.onComponentInteraction()` captures event
3. Event sent back to LLM as: `{event: "favorite_added", place: "Museum", day: 1}`
4. LLM adjusts itinerary (removes nearby place, adds user's choice)
5. GenUI re-renders updated plan

---

## Key System Instructions for LLM

### Discovery Persona
```
You are a Spatial Planning Expert. Your goal is to find patterns in vibe signatures.

When analyzing places:
- Look for the 'v:' field for vibe tags
- Check 'heritage:' for historical significance
- Note 'local:true' for independent businesses
- Identify 'nearby:' fields for distance relationships

Decision logic:
- User likes "Quiet History"? → Look for historic=yes AND quiet=true
- User wants "Urban Edge"? → Look for street_art AND craft AND vibrant
- Always prioritize places with high relevance scores

Output format:
- Always provide 'reason' for each place choice
- Explain WHY based on vibe signatures, not generic descriptions
- Group places within 1km into same-day clusters
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ USER INPUT (City, Country, Vibes)                          │
└────────────────┬────────────────────────────────────────────┘
                 │
         ┌───────▼────────┐
         │ OSMService     │
         │ (Overpass API) │
         └───────┬────────┘
                 │
         ┌───────▼──────────────────┐
         │ UniversalTagHarvester    │
         │ (Extract all tags)       │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ SemanticDiscoveryEngine  │
         │ (Create vibe signatures) │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ LLMDiscoveryReasoner     │
         │ (Local Gemini Nano)      │
         │ (Spatial clustering)     │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ DiscoveryOrchestrator    │
         │ (Coordinate flow)        │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ GenUiOrchestrator        │
         │ (Parse A2UI messages)    │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ ComponentCatalog         │
         │ (Render widgets)         │
         └───────┬──────────────────┘
                 │
         ┌───────▼──────────────────┐
         │ GenUiSurface             │
         │ (Display to user)        │
         └────────────────────────────┘
```

---

## File Structure

```
lib/
├── genui/
│   ├── component_catalog.dart        # Widget definitions
│   └── genui_orchestrator.dart       # A2UI rendering & surface
├── services/
│   ├── universal_tag_harvester.dart  # OSM tag extraction
│   ├── semantic_discovery_engine.dart# Vibe signature generation
│   ├── llm_discovery_reasoner.dart   # Local LLM reasoning
│   ├── spatial_clustering_service.dart # Distance-based grouping
│   ├── osm_service.dart              # Overpass API wrapper
│   ├── discovery_orchestrator.dart   # Master coordinator
│   └── travel_agent_service.dart     # LLM communication
├── config.dart                       # Configuration
├── main.dart                         # App entry
└── home_screen.dart                  # Initial UI
```

---

## Configuration

### pubspec.yaml additions (if needed)
```yaml
dependencies:
  google_generative_ai: ^latest  # For Gemini Nano
  http: ^1.2.0                   # For Overpass API
  logging: ^1.2.0                # For transparency logging
```

### System Prompt for Gemini Nano
See `PHASE_5_LLM_TOOLS_AND_PROMPTS.md` for complete prompts

---

## Testing & Validation

### Test Case 1: Vibe Signature Generation
- Input: Raw OSM place with 20 tags
- Expected: Compact v: string < 200 chars
- Verify: All critical tags preserved, no data loss

### Test Case 2: LLM Spatial Clustering
- Input: 50 places across city
- Expected: 3-5 day clusters, places within 1km grouped
- Verify: Day themes make sense, anchor points prioritized

### Test Case 3: GenUI Rendering
- Input: LLM JSON itinerary
- Expected: RouteItinerary widget with all places visible
- Verify: User can tap cards, vibe tags display correctly

---

## Transparency Logging

All major steps include logging:
```dart
debugPrint('[OSM] Fetching attractions in $city');
debugPrint('[Vibe] Generated signature: $signature');
debugPrint('[LLM] Reasoning input: $input');
debugPrint('[GenUI] Rendering component: $componentType');
```

See `TRANSPARENCY_LOGGING.md` for complete logging reference

---

## Next Steps

1. ✅ Create GenUI component catalog
2. ✅ Create GenUI orchestrator & surface
3. → Update discovery_orchestrator to use GenUI
4. → Test end-to-end flow
5. → Add offline map caching
6. → Deploy to iOS/Android

