# 🧠 AI-First Travel Agent Architecture

## Overview

This is an **agentic AI system** where the LLM is the decision-maker that orchestrates real-world data and spatial reasoning to create optimized travel itineraries.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    UI / GenUI Layer                          │
│  (TripDurationPicker, CountryGrid, CityHeroCard,            │
│   ItineraryPreview, SmartMapSurface)                         │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│         Travel Agent Service (LLM Orchestrator)              │
│  ✅ Receives user intent (city, categories, duration, vibe) │
│  ✅ Calls OSM tools to fetch real data                      │
│  ✅ Analyzes spatial relationships                          │
│  ✅ Makes grouping decisions                                │
│  ✅ Returns optimized itinerary                             │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──────┐ ┌───▼──────┐ ┌──▼─────────────────┐
│ OSM Service  │ │Clustering│ │ Distance Matrix    │
│              │ │ Service  │ │ Calculator         │
│ Tool: Fetch  │ │          │ │                    │
│ Attractions  │ │ Groups   │ │ Computes distances │
│ from Real    │ │ by       │ │ between all        │
│ OSM Data     │ │ proximity│ │ attractions        │
│              │ │ (1km)    │ │                    │
└──────────────┘ └──────────┘ └────────────────────┘
```

## Core Services

### 1. OSM Service (Data Engine)

**Purpose**: Fetch real-world data from OpenStreetMap

**Tools Available**:
- `fetchAttractions(city, categories)` - Uses Overpass API
- `calculateDistanceMatrix(places)` - Haversine formula

**Overpass Query**:
```
[out:json][timeout:60];
{geocodeArea:"Paris"}->.searchArea;
(
  nwr["tourism"~"museum|attraction"](area.searchArea);
  nwr["amenity"~"cafe|restaurant|church"](area.searchArea);
  nwr["leisure"~"park|garden"](area.searchArea);
);
out center;
```

**Returns**:
```json
[
  {
    "id": 12345,
    "name": "Louvre Museum",
    "lat": 48.8606,
    "lon": 2.3352,
    "category": "museum",
    "rating": 4.8,
    "description": "World's largest art museum"
  },
  ...
]
```

### 2. Spatial Clustering Service

**Purpose**: Group attractions into logical day clusters

**Algorithm**:
1. Sort attractions by rating (highest first - "anchor points")
2. For each unvisited attraction:
   - Start new day cluster with it as anchor
   - Find nearby attractions (within 1km)
   - Group up to 8 attractions per day
   - Mark all as visited

**Output**: List of DayCluster objects

```dart
DayCluster {
  dayNumber: 1,
  anchorPoint: {"name": "Louvre", ...},
  attractions: [...7 more within 1km],
  totalDistance: 2.3 km,
  estimatedTime: "360 minutes"
}
```

### 3. Travel Agent Service (Orchestrator)

**Purpose**: The AI decision-maker

**Flow**:
1. **Receives**: city, categories, duration, userVibe
2. **Calls OSM Tools**: Fetch attractions + distance matrix
3. **Reasons**: Creates spatial clusters
4. **Filters**: By user vibe (cultural, nature, nightlife, etc.)
5. **Optimizes**: For trip duration
6. **Returns**: Complete TravelItinerary

**Example Agent Decision**:
```
User Input:
- City: "Paris"
- Categories: ["museum", "art"]
- Duration: 3 days
- Vibe: "cultural"

Agent Reasoning:
1. ✅ Tool: Fetch 45 museums/galleries in Paris
2. ✅ Tool: Calculate distances between all
3. ✅ Reasoning: Group into clusters (museums 1-8, 9-16, 17-24)
4. ✅ Filter: Keep cultural attractions, exclude nightlife
5. ✅ Optimize: Select best 3 days (most highly rated clusters)
6. ✅ Return: 3-day cultural itinerary with optimized routes
```

## User Flow

### Phase 1: Onboarding
```
App Starts
    ↓
GenUI: TripDurationPicker (LLM generates UI)
    ↓
User selects: 3 days
```

### Phase 2: Location Selection
```
GenUI: CountryGrid (with flags)
    ↓
User selects: France
    ↓
GenUI: CityHeroCard
    ↓
User selects: Paris
```

### Phase 3: Planning
```
Agent: Call OSM Tools
    ├─ fetchAttractions("Paris", categories)
    └─ calculateDistanceMatrix()
    ↓
Agent: Spatial Reasoning
    ├─ Create day clusters (1km proximity)
    └─ Sort by rating
    ↓
Agent: Filter by User Vibe
    └─ Keep museums, galleries, cultural sites
    ↓
Agent: Optimize for Duration
    └─ Select best 3 days
    ↓
Return: TravelItinerary
```

### Phase 4: Execution
```
GenUI: ItineraryPreview
    ├─ Day 1: Louvre + 7 nearby museums
    ├─ Day 2: Musée d'Orsay + 7 nearby
    └─ Day 3: Montmartre + 7 nearby
    ↓
GenUI: SmartMapSurface
    ├─ Shows all pins
    ├─ Shows routes (via Mapbox)
    └─ Uses cached tiles (offline)
```

## Data Flow Example

### Input
```
{
  "city": "Paris",
  "categories": ["museum", "cafe"],
  "durationDays": 3,
  "userVibe": "cultural"
}
```

### OSM Service Output
```
[
  {"id": 1, "name": "Louvre", "lat": 48.8606, "lon": 2.3352, "category": "museum", "rating": 4.8},
  {"id": 2, "name": "Cafe de Flore", "lat": 48.8551, "lon": 2.3311, "category": "cafe", "rating": 4.6},
  {"id": 3, "name": "Musée d'Orsay", "lat": 48.8601, "lon": 2.3261, "category": "museum", "rating": 4.7},
  ... (42 more)
]
```

### Distance Matrix
```
{
  "1": {"2": 0.65, "3": 0.42, ...},
  "2": {"1": 0.65, "3": 1.08, ...},
  "3": {"1": 0.42, "2": 1.08, ...},
  ...
}
```

### Spatial Clustering Output
```
DayCluster 1 (Anchor: Louvre #1)
  - Louvre (Museum) ⭐⭐⭐⭐⭐
  - Tuileries Garden (0.3km)
  - Palais Garnier (0.8km)
  - 5 more museums (all <1km)

DayCluster 2 (Anchor: Musée d'Orsay #3)
  - Musée d'Orsay (Museum) ⭐⭐⭐⭐⭐
  - Rodin Museum (0.6km)
  - Les Invalides (0.9km)
  - 5 more museums (all <1km)

DayCluster 3 (Anchor: Montmartre Museum #15)
  - Montmartre (Art) ⭐⭐⭐⭐
  - Sacré-Cœur (0.4km)
  - Art Galleries (0.7km)
  - 5 more galleries (all <1km)
```

### Final Itinerary
```
{
  "city": "Paris",
  "days": 3,
  "userVibe": "cultural",
  "itinerary": [
    {
      "dayNumber": 1,
      "theme": "Art & Museums",
      "attractions": 8,
      "route": "Louvre → Tuileries → Palais Garnier → ...",
      "totalDistance": 2.3 km,
      "estimatedTime": "8 hours"
    },
    {
      "dayNumber": 2,
      "theme": "Impressionist & Modern",
      "attractions": 8,
      "route": "Musée d'Orsay → Rodin → Les Invalides → ...",
      "totalDistance": 2.1 km,
      "estimatedTime": "8 hours"
    },
    {
      "dayNumber": 3,
      "theme": "Bohemian & Artistic",
      "attractions": 8,
      "route": "Montmartre → Sacré-Cœur → Galleries → ...",
      "totalDistance": 1.9 km,
      "estimatedTime": "8 hours"
    }
  ]
}
```

## Why This Architecture Works

### ✅ True AI Agency
- LLM makes decisions (not just filters)
- Uses real tools (OSM data)
- Understands spatial relationships
- Optimizes for user preferences

### ✅ Real-World Data
- Overpass API gives live OSM data
- Current ratings and reviews
- Always up-to-date

### ✅ Spatial Intelligence
- Understands proximity clustering
- Optimizes routes
- Maximizes efficiency

### ✅ User-Centric
- Respects user "vibe"
- Adapts to duration
- Prioritizes highly-rated places

### ✅ Scalable
- Works for any city
- Any categories
- Any duration

## Implementation Status

| Component | Status |
|-----------|--------|
| OSM Service | ✅ Implemented |
| Spatial Clustering | ✅ Implemented |
| Travel Agent Service | ✅ Implemented |
| UI/GenUI | ⏳ Next Phase |
| Map Integration | ⏳ Next Phase |
| Offline Caching | ⏳ Next Phase |

## Next Steps

1. ✅ Create services layer (DONE)
2. ⏳ Build UI with GenUI
3. ⏳ Integrate Mapbox for visualization
4. ⏳ Add offline map caching
5. ⏳ Deploy and test with real data

---

**Status**: 🧠 Agentic System Ready  
**Privacy**: ✅ All local processing  
**Data Source**: ✅ Real OSM via Overpass  
**Decision Making**: ✅ LLM-powered  

Ready to build the UI layer! ��
