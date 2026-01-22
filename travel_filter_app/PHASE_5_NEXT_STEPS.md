# Phase 5: Next Steps & Requirements

## Current Status
✅ **Completed:**
1. OSM Data Harvesting (TagHarvester) - Fetches 25k+ elements
2. Vibe Signature Generation (DiscoveryEngine) - Creates compact signatures
3. GenUI Component Catalog - Defined PlaceDiscoveryCard, SmartMapSurface, RouteItinerary
4. GenUI Orchestrator - Renders components from AI messages
5. Discovery Orchestrator - Orchestrates the full flow
6. Transparency Logging - Comprehensive logging throughout

❌ **Issues Found:**
1. RangeError in vibe signature processing (FIXED)
2. LLM reasoning not fully connected
3. A2UI message generation needs proper LLM integration
4. Spatial clustering/grouping not implemented
5. Route optimization missing

## NEXT STEPS (Priority Order)

### Step 1: Fix LLM Integration
**What:** Connect Gemini Nano to actually reason about vibe signatures
**Why:** Currently the system harvests data but LLM doesn't analyze patterns
**How:**
- Fix `llm_discovery_reasoner.dart` to properly call LLM with tool schemas
- Pass vibe signatures to LLM
- Parse LLM response and generate A2UI messages

### Step 2: Implement Spatial Clustering
**What:** Group nearby places (within 1km) into "Day Clusters"
**Why:** Creates coherent itineraries instead of scattered locations
**How:**
- Create `SpatialClusterer` service
- Use haversine distance calculation
- Group places by proximity
- Identify "Anchor Points" (high-rated places)

### Step 3: Implement Route Optimization
**What:** Order day clusters and places within clusters for efficient travel
**Why:** Creates realistic, walkable itineraries
**How:**
- Create `RouteOptimizer` service
- Use nearest-neighbor or similar algorithm
- Minimize total distance traveled per day
- Account for opening hours

### Step 4: A2UI Message Generation
**What:** Convert LLM reasoning + spatial data into A2UI format
**Why:** GenUI surface needs properly formatted messages to render
**How:**
- Create `A2uiMessageGenerator` 
- Generate SmartMapSurface with clustered places
- Generate RouteItinerary with day-by-day breakdown
- Include place metadata and navigation info

### Step 5: Interactive State Management
**What:** Handle user interactions (tap place, select day, change vibe)
**Why:** App should be interactive, not just display-only
**How:**
- Add event callbacks to GenUI components
- Send user actions back to LLM
- LLM re-reasons and sends updated A2UI messages
- Update surface in real-time

### Step 6: Offline Map Caching
**What:** Cache map tiles for offline viewing
**Why:** User should see maps even without internet
**How:**
- Integrate `flutter_map_tile_caching`
- Download tiles for selected areas
- Use cached tiles in SmartMapSurface

## Key Files to Update

1. `lib/services/llm_discovery_reasoner.dart` - FIX: LLM integration
2. `lib/services/spatial_clusterer.dart` - NEW: Spatial grouping
3. `lib/services/route_optimizer.dart` - NEW: Route ordering
4. `lib/genui/a2ui_message_generator.dart` - NEW: A2UI format conversion
5. `lib/genui/genui_orchestrator.dart` - UPDATE: Event handling

## Testing Strategy

1. **Unit Tests**: Test each service independently
2. **Integration Tests**: Test full flow end-to-end
3. **UI Tests**: Test GenUI rendering and interactions
4. **Performance Tests**: Test with 25k+ elements

## Success Metrics

- [ ] LLM generates meaningful recommendations (not random)
- [ ] Places grouped into sensible day clusters
- [ ] Route optimized for walking distance
- [ ] A2UI messages render correctly
- [ ] User can interact and see real-time updates
- [ ] Works offline with cached maps

