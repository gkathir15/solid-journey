# Phase 5: Next Steps & Requirements

**Current Status**: Discovery Engine + Components working. Fixing RangeError in vibe processing.

---

## ✅ What's Currently Working

1. **OSM Data Harvesting** - Universal Tag Harvester pulling 25k+ elements from Overpass API
2. **Vibe Signature Generation** - Creating compact minified signatures (e.g., `l:indie;a:a:culture;s:paid`)
3. **GenUI Components** - PlaceDiscoveryCard, RouteItinerary, SmartMapSurface UI widgets defined
4. **Discovery Orchestrator** - Orchestrating flow from data harvesting → processing → rendering
5. **Transparency Logging** - Full logging of what goes in/out of discovery engine

---

## ❌ What Needs Fixing/Completion

### CRITICAL - Bug Fixes
1. **RangeError in DiscoveryEngine** (URGENT - blocking)
   - Error: `RangeError (end): Invalid value: Not in inclusive range 0..3: 4`
   - Location: When processing vibe signatures, accessing invalid vibe index
   - Fix: Bounds check before accessing vibe array
   - Status: **FIX COMMITTED - WAITING FOR REBUILD**

### Phase 5A: LLM Integration (Missing)
2. **GenUI ↔ LLM Connection** 
   - [ ] Implement `LLMReasoningService` that:
     - Receives filtered OSM data + vibe signatures
     - Calls Gemini Nano with system prompt: "You are a Spatial Planner..."
     - Returns A2UI JSON for component rendering
   - [ ] A2UI Message Processor
     - Parse LLM output JSON
     - Map to GenUI component catalog
     - Handle validation

3. **LLM System Prompt Setup**
   ```
   "You are a Spatial Travel Planner with access to:
   - Real OSM place data with vibe signatures (l:indie;a:a:culture;s:paid)
   - User preferences for duration, vibes, and interests
   
   Your job:
   1. Analyze vibe signatures to find pattern matches
   2. Group places into 'Day Clusters' (1km radius = same day)
   3. Create anchor points (famous/highly-rated spots)
   4. Output ONLY valid A2UI JSON using this widget catalog:
      {
        'PlaceDiscoveryCard': {lat, lng, name, vibe, image},
        'RouteItinerary': {days: [{date, places: [...], route_path}]},
        'SmartMapSurface': {center: {lat, lng}, zoom, pins: [...]}
      }
   5. Justify choices using metadata: 'I chose X because it's a 1900s local-owned bookstore'"
   ```

### Phase 5B: Spatial Clustering (Partial)
4. **Distance Matrix + Clustering**
   - [ ] Implement `SpatialClusteringService.calculateDistanceMatrix()`
     - Input: List of Place objects with lat/lng
     - Output: JSON mapping of distances between all coordinates
     - Use Haversine formula for great-circle distances
   - [ ] Implement day-wise clustering algorithm
     - Places within 1km = same day cluster
     - Prioritize anchor points as day starts
     - Output: `List<DayCluster>`

### Phase 5C: Map Integration (Partial)
5. **SmartMapSurface Enhancement**
   - [ ] Integrate `flutter_map` with `flutter_map_tile_caching`
   - [ ] Render pins for each place with vibe icons
   - [ ] Draw route lines between clustered places
   - [ ] Offline tile caching support
   - [ ] Tap on pin → show PlaceDiscoveryCard

### Phase 5D: Data Flow Loop (Missing)
6. **User Interaction → LLM Re-reasoning**
   - [ ] When user taps "Add to Trip" on a card:
     - Capture action as `DataModelUpdate`
     - Send back to LLM as context
     - LLM re-reasons and generates new UI state
   - [ ] Implement state management for:
     - Selected places
     - Active day
     - Current vibe filters
   - [ ] Refresh GenUiSurface with new layout

---

## 🎯 Recommended Implementation Order

### Step 1: Fix RangeError (TODAY)
```bash
# After fix is tested, run:
flutter run -d <device>
# Verify: Paris query should complete without RangeError
```

### Step 2: Implement LLMReasoningService (NEXT)
- Create file: `lib/services/llm_reasoning_service.dart`
- Initialize Gemini Nano model
- Test with hardcoded vibe signatures first
- Verify A2UI JSON output

### Step 3: Connect LLM to GenUI
- Modify `GenUiSurface` to call `LLMReasoningService`
- Map LLM JSON output to widget catalog
- Test component rendering

### Step 4: Implement Spatial Clustering
- Create `SpatialClusteringService.calculateDistanceMatrix()`
- Group places by proximity
- Pass clusters to LLM for planning

### Step 5: Interactive Loop
- Implement event listeners on generated widgets
- Send user actions back to LLM
- Re-render surfaces dynamically

---

## 📊 Current Flow

```
User Input (City, Duration, Vibes)
    ↓
TagHarvester (25k+ OSM elements)
    ↓
DiscoveryEngine (vibe signatures) ← [RangeError HERE - FIXING]
    ↓
DiscoveryOrchestrator (collection)
    ↓
GenUiSurface (renders static components)
    ✗ MISSING: LLM Reasoning
    ✗ MISSING: Spatial Clustering
    ✗ MISSING: Interactive Loop
```

## 🔧 Missing Tools/Services

1. `LLMReasoningService` - Bridge between discovery engine and GenUI
2. `A2UIMessageProcessor` - Parse LLM JSON → widget catalog validation
3. `SpatialClusteringService.calculateDistanceMatrix()` - Not implemented
4. `RouteOptimizationService` - TSP solver for optimal route (Future)
5. `OfflineTileManager` - Cache tiles for offline (Future)

---

## 📝 Testing Checklist

- [ ] RangeError fix verified on iOS simulator
- [ ] Paris query completes without errors
- [ ] All 25k+ elements processed into vibe signatures
- [ ] GenUI components render correctly
- [ ] LLM returns valid A2UI JSON
- [ ] SmartMapSurface displays pins
- [ ] RouteItinerary shows day clusters
- [ ] User interaction triggers re-reasoning

---

## 🚀 Success Criteria (MVP)

1. User selects "Paris, 3 days, historic+cafe_culture"
2. System:
   - Queries OSM for 25k+ places ✓
   - Creates vibe signatures ✓
   - Calls Gemini Nano with data ← NEXT
   - Receives A2UI JSON ← NEXT
   - Renders SmartMapSurface + RouteItinerary ← NEXT
   - User taps a place
   - LLM re-plans and re-renders ← NEXT

---

## 🛠️ Technical Debt

- [ ] Add comprehensive error handling for Overpass API failures
- [ ] Implement rate limiting for tag harvester
- [ ] Cache OSM queries (avoid re-fetching same city)
- [ ] Add unit tests for vibe signature generation
- [ ] Performance optimization for 25k element processing

