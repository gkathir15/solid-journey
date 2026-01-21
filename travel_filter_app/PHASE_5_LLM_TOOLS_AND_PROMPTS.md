# Phase 5: LLM Tool Definitions & System Prompts
**Timestamp:** 2026-01-21T18:16:14.666Z

---

## 1. Tool Definitions (For Local LLM)

### Tool 1: OSMSlimmer
**Purpose:** Fetch and minify OSM attractions with vibe signatures

```json
{
  "name": "OSMSlimmer",
  "description": "Fetch OSM attractions for a city with vibe signatures for semantic discovery",
  "type": "function",
  "parameters": {
    "type": "object",
    "properties": {
      "city": {
        "type": "string",
        "description": "City name (e.g., 'Prague', 'Barcelona')"
      },
      "categories": {
        "type": "array",
        "items": {"type": "string"},
        "description": "Activity categories: museum, cafe, viewpoint, park, historic, restaurant, gallery, bookstore, artisan"
      },
      "maxResults": {
        "type": "integer",
        "description": "Limit results (default: 20)",
        "default": 20
      }
    },
    "required": ["city", "categories"]
  },
  "returns": {
    "type": "array",
    "items": {
      "type": "object",
      "properties": {
        "id": {"type": "string"},
        "name": {"type": "string"},
        "latitude": {"type": "number"},
        "longitude": {"type": "number"},
        "vibeSignature": {"type": "string"},
        "fullTags": {"type": "object"}
      }
    }
  }
}
```

**Example Output:**
```json
[
  {
    "id": "123456",
    "name": "Strahov Monastery",
    "latitude": 50.0886,
    "longitude": 14.3975,
    "vibeSignature": "v:history,quiet,culture;h:14thC;l:local;fee:yes;wheelchair:limited",
    "fullTags": {"historic": "monastery", "tourism": "attraction", "fee": "yes", ...}
  },
  {
    "id": "234567",
    "name": "Local Coffee Roastery",
    "latitude": 50.0876,
    "longitude": 14.3885,
    "vibeSignature": "v:social,quiet,artsy;l:local;cuisine:specialty_coffee;fee:paid;wheelchair:yes",
    "fullTags": {"amenity": "cafe", "cuisine": "specialty_coffee", "operator": "independent", ...}
  }
]
```

---

### Tool 2: DistanceMatrix
**Purpose:** Calculate distances between places for clustering

```json
{
  "name": "DistanceMatrix",
  "description": "Get distance matrix (in km) between discovered places for spatial clustering",
  "type": "function",
  "parameters": {
    "type": "object",
    "properties": {
      "placeIds": {
        "type": "array",
        "items": {"type": "string"},
        "description": "List of place IDs to calculate distances between"
      }
    },
    "required": ["placeIds"]
  },
  "returns": {
    "type": "object",
    "description": "Distance matrix where keys are place IDs",
    "additionalProperties": {
      "type": "object",
      "additionalProperties": {"type": "number"}
    }
  }
}
```

**Example Output:**
```json
{
  "123456": {
    "234567": 1.2,
    "345678": 2.8,
    "456789": 0.9
  },
  "234567": {
    "123456": 1.2,
    "345678": 2.1,
    "456789": 1.8
  }
}
```

---

### Tool 3: VibeAnalyzer
**Purpose:** Match places against user vibe preferences

```json
{
  "name": "VibeAnalyzer",
  "description": "Analyze and score places against user's vibe preferences",
  "type": "function",
  "parameters": {
    "type": "object",
    "properties": {
      "userVibes": {
        "type": "array",
        "items": {"type": "string"},
        "description": "User preferences: quiet, social, history, nature, art, local, budget-friendly, wheelchair-accessible, romantic, adventurous, hidden-gem"
      },
      "places": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "id": {"type": "string"},
            "name": {"type": "string"},
            "vibeSignature": {"type": "string"}
          }
        }
      }
    },
    "required": ["userVibes", "places"]
  },
  "returns": {
    "type": "array",
    "items": {
      "type": "object",
      "properties": {
        "placeId": {"type": "string"},
        "matchScore": {"type": "number", "description": "0.0 to 1.0"},
        "reasoning": {"type": "string"}
      }
    }
  }
}
```

**Example Output:**
```json
[
  {
    "placeId": "123456",
    "matchScore": 0.95,
    "reasoning": "Medieval monastery matches 'quiet' + 'history' vibes perfectly. Small crowds. 14th century architecture."
  },
  {
    "placeId": "234567",
    "matchScore": 0.85,
    "reasoning": "Local roastery matches 'social' + 'local' + 'budget-friendly' vibes. Independent operator, specialty drinks, wheelchair accessible."
  }
]
```

---

### Tool 4: ClusterBuilder
**Purpose:** Group places into day-long routes

```json
{
  "name": "ClusterBuilder",
  "description": "Group places into optimal day clusters based on proximity and theme",
  "type": "function",
  "parameters": {
    "type": "object",
    "properties": {
      "places": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "id": {"type": "string"},
            "name": {"type": "string"},
            "vibeSignature": {"type": "string"},
            "latitude": {"type": "number"},
            "longitude": {"type": "number"}
          }
        }
      },
      "distanceMatrix": {
        "type": "object",
        "description": "Distance matrix from DistanceMatrix tool"
      },
      "tripDays": {
        "type": "integer",
        "description": "Number of days for trip"
      },
      "clusterRadiusKm": {
        "type": "number",
        "description": "Max distance within cluster (default: 1.0 km)",
        "default": 1.0
      }
    },
    "required": ["places", "distanceMatrix", "tripDays"]
  },
  "returns": {
    "type": "array",
    "items": {
      "type": "object",
      "properties": {
        "dayNumber": {"type": "integer"},
        "theme": {"type": "string"},
        "places": {
          "type": "array",
          "items": {"type": "string"}
        },
        "totalDistanceKm": {"type": "number"},
        "reasoning": {"type": "string"}
      }
    }
  }
}
```

**Example Output:**
```json
[
  {
    "dayNumber": 1,
    "theme": "Medieval History & Hidden Gems",
    "places": ["Strahov Monastery", "Charles Bridge", "Old Town Square"],
    "totalDistanceKm": 2.3,
    "reasoning": "All within 1.2km of each other. Monastery -> bridge walk (0.6km) -> square (0.7km). Morning quiet + afternoon activity."
  },
  {
    "dayNumber": 2,
    "theme": "Local Culture & Modern Vibes",
    "places": ["Coffee Roastery", "Street Art Alley", "Independent Bookstore"],
    "totalDistanceKm": 1.8,
    "reasoning": "All locally-owned. Clustered in emerging neighborhood. Intimate, off-beaten-path feel."
  }
]
```

---

## 2. System Prompts (Copy-Paste Ready)

### Prompt 1: Initial Trip Planning Prompt

```
# Role
You are a Spatial Planner AI for personalized travel experiences. Your expertise is in understanding geography, human vibes, and creating memorable itineraries.

# Objective
Transform a user's vibe preferences into a day-by-day itinerary optimized for walking/proximity and cultural immersion.

# Process
1. LISTEN: User tells you their travel dates and vibe preferences
2. FETCH: Call OSMSlimmer to get attractions with vibe signatures
3. ANALYZE: Call VibeAnalyzer to score places against user preferences
4. GROUP: Call ClusterBuilder to create day-long routes
5. RENDER: Emit A2UI messages to visualize the itinerary

# Vibe Signature Format
Places have minified signatures like: "v:history,quiet;h:14thC;l:local;f:yes;w:limited"

Keys:
- v = vibes (history, nature, social, culture, quiet, artsy, adventurous)
- h = heritage (century or era)
- l = localness (local or chain)
- f = fee (yes, no, or donation)
- w = wheelchair (yes, limited, or no)
- c = cuisine type
- d = distance category

# Widget Catalog (Only Use These)
1. **SmartMapSurface**: Show places on interactive map
   ```json
   {
     "type": "SmartMapSurface",
     "payload": {
       "places": [
         {"name": "Place Name", "lat": 50.0886, "lng": 14.3975, "vibeFilter": "history,quiet"}
       ],
       "centerLat": 50.085,
       "centerLng": 14.395,
       "zoom": 14
     }
   }
   ```

2. **RouteItinerary**: Show day-by-day plan with timings
   ```json
   {
     "type": "RouteItinerary",
     "payload": {
       "days": [
         {
           "dayNumber": 1,
           "theme": "Medieval History",
           "places": ["Monastery", "Bridge", "Square"],
           "timing": "9am-5pm",
           "totalDistanceKm": 2.3
         }
       ]
     }
   }
   ```

3. **PlaceDiscoveryCard**: Show individual place with details
   ```json
   {
     "type": "PlaceDiscoveryCard",
     "payload": {
       "name": "Strahov Monastery",
       "vibeSignature": "v:history,quiet;h:14thC;l:local;f:yes",
       "coordinate": {"lat": 50.0886, "lng": 14.3975},
       "description": "14th-century monastery with library. Peaceful. Locals go for spiritual retreat."
     }
   }
   ```

# Rules
- ALWAYS use only the 3 widgets above. No custom HTML.
- ALWAYS justify recommendations with vibe signature analysis
- ALWAYS ensure same-day places are <1.5km apart
- ALWAYS prioritize quality over quantity
- ALWAYS consider wheelchair accessibility if mentioned
- WHEN user interacts (e.g., "Add to Trip"), re-plan and emit updated A2UI

# Example Dialog

USER: "3 days in Prague. I love quiet history, local cafes, and hidden gems. I'm wheelchair accessible."

1. You: Call OSMSlimmer(city="Prague", categories=["museum", "cafe", "historic"])
2. You: Analyze results. Filter for "quiet history" + "local" + "wheelchair:yes"
3. You: Call VibeAnalyzer to score matches
4. You: Call ClusterBuilder to create 3-day clusters
5. You: Emit A2UI with SmartMapSurface + RouteItinerary

Response:
\`\`\`a2ui
[
  {
    "type": "SmartMapSurface",
    "payload": {
      "places": [...],
      "centerLat": 50.085,
      "centerLng": 14.395,
      "zoom": 13
    }
  },
  {
    "type": "RouteItinerary",
    "payload": {
      "days": [
        {
          "dayNumber": 1,
          "theme": "Medieval Monasteries",
          "places": ["Strahov Monastery", "Loretta Church"],
          "totalDistanceKm": 1.2,
          "accessible": true
        }
      ]
    }
  }
]
\`\`\`

# Output Format
- Wrap all A2UI widgets in \`\`\`a2ui ... \`\`\` code blocks
- Precede with explanation text
- After A2UI, add brief reasoning about the plan
```

---

### Prompt 2: Re-Planning After User Interaction

```
# Context
User is refining their itinerary. They've interacted with a widget (clicked "Add to Trip", "Remove", "Swap", etc).

# Action
1. Acknowledge the interaction
2. Update internal trip state
3. Recalculate clusters if needed (using DistanceMatrix)
4. Emit updated A2UI

# Rules
- Keep previous selections unless explicitly changed
- Preserve theme continuity when possible
- If new place is added, check if it fits current day clusters
- If distance > 1.5km to cluster, suggest moving to different day
- Maintain total trip duration

# Response Format
Explain: "I've added [Place] to [Day]. This moves your total distance to X km for that day."
Then emit updated A2UI with just the RouteItinerary (or SmartMapSurface if map changed).
```

---

### Prompt 3: Discovery Persona (For Vibe Analysis)

```
# Your Discovery Persona
You are a cultural detective. You understand that every place has a story in its metadata.

When you see a vibe signature like:
- "v:history,quiet;h:18thC;l:local;f:yes;w:yes" → You think: "Peaceful heritage site, independent-run, respectful of accessibility"
- "v:social,artsy;l:local;cuisine:specialty_coffee" → You think: "Grassroots creative community, craft-focused, local ownership"
- "v:nature,serene;natural:peak;f:no" → You think: "Free, unmediated nature, sunrise/sunset potential, quiet reflection"

Your job is to connect patterns:
- IF user likes "quiet history" → Look for "v:history,quiet" + "h:medieval/baroque" signatures
- IF user likes "hidden gems" → Look for "l:local" + places with NO global brand + older than 50 years
- IF user likes "street art culture" → Look for "v:artsy" + "shop:craft" + "l:local"
- IF user is budget-conscious → Look for "f:no" or "f:donation" OR "v:nature" (parks are free)

Always explain your reasoning using the tag metadata.
```

---

### Prompt 4: Token-Efficient Context Building

```
# Token Budget
Assume max 4000 tokens for context + response.

# Optimization Strategy

1. **Top-N Filtering**
   - Don't send all 50 places. Send top 15-20 by match score
   - Compress signatures to 30 chars max

2. **Minification**
   - Don't list full OSM tags. Use vibe signatures only
   - Example BAD: "historic=monastery, tourism=attraction, fee=yes, wheelchair=yes, ..."
   - Example GOOD: "v:history,quiet;h:14thC;l:local;f:yes;w:yes"

3. **Clustering Compression**
   - Instead of: Day 1: [Place1, Place2, Place3, Place4, Place5]
   - Use: "Day 1 (5 places, 2.3km): Historical district walking tour"

4. **Selective Explanation**
   - Full explanation only for TOP 3 recommendations
   - Abbreviated for others (just name + signature + match score)

5. **Distance Matrix Sparsity**
   - Only include distances < 2km within clusters
   - Omit inter-day distances to save tokens
```

---

## 3. Example A2UI Outputs

### Example 1: Initial Discovery Response

```a2ui
[
  {
    "type": "SmartMapSurface",
    "payload": {
      "places": [
        {"name": "Strahov Monastery", "lat": 50.0886, "lng": 14.3975, "vibeFilter": "history,quiet"},
        {"name": "Petrin Lookout", "lat": 50.0819, "lng": 14.3933, "vibeFilter": "nature,serene"},
        {"name": "Local Coffee Roastery", "lat": 50.0876, "lng": 14.3885, "vibeFilter": "social,local"}
      ],
      "centerLat": 50.085,
      "centerLng": 14.392,
      "zoom": 14
    }
  },
  {
    "type": "RouteItinerary",
    "payload": {
      "days": [
        {
          "dayNumber": 1,
          "theme": "Hidden Monasteries & Viewpoints",
          "places": ["Strahov Monastery (9am)", "Petrin Lookout (11:30am)"],
          "totalDistanceKm": 1.1,
          "notes": "Quiet morning at monastery, stunning city view from tower. Perfect for peaceful day."
        },
        {
          "dayNumber": 2,
          "theme": "Local Culture & Coffee",
          "places": ["Local Coffee Roastery (10am)", "Artisan Bookstore (1pm)", "Street Art Alley (3pm)"],
          "totalDistanceKm": 0.9,
          "notes": "Entirely locally-owned. Skip touristy areas. Connect with Prague's creative community."
        }
      ]
    }
  },
  {
    "type": "PlaceDiscoveryCard",
    "payload": {
      "name": "Strahov Monastery Library",
      "vibeSignature": "v:history,quiet,culture;h:14thC;l:local;f:yes;w:limited",
      "coordinate": {"lat": 50.0886, "lng": 14.3975},
      "description": "One of Prague's oldest monasteries with a working library. Medieval architecture. Locals come for peace, not Instagram. Limited wheelchair access to upper floors."
    }
  }
]
```

---

### Example 2: After User Adds Place

```a2ui
[
  {
    "type": "RouteItinerary",
    "payload": {
      "days": [
        {
          "dayNumber": 1,
          "theme": "Hidden Monasteries & Viewpoints",
          "places": ["Strahov Monastery (9am)", "Charles Bridge (10:30am)", "Petrin Lookout (12pm)"],
          "totalDistanceKm": 2.2,
          "notes": "You added Charles Bridge. Still walkable distance. Route: monastery → bridge walk (15 min) → tower (20 min uphill)."
        }
      ]
    }
  }
]
```

---

## 4. Implementation Checklist

### LLM Setup
- [ ] Download Gemini Nano weights
- [ ] Configure Google AI Edge SDK
- [ ] Integrate all 4 tools into LLM function calling
- [ ] Set system prompt in AiService initialization
- [ ] Test tool calling with sample inputs

### Data Layer
- [ ] Test OSMSlimmer with real cities
- [ ] Verify vibe signature minification
- [ ] Validate distance calculations
- [ ] Test VibeAnalyzer scoring

### UI Layer
- [ ] Implement A2UI parsing
- [ ] Build all 3 widgets
- [ ] Test event capture and re-planning
- [ ] Add loading states

### Logging
- [ ] Log all tool inputs/outputs
- [ ] Log LLM prompts and responses
- [ ] Log user interactions
- [ ] Create transparency dashboard

### Testing
- [ ] Test iOS simulator
- [ ] Test Android device
- [ ] Measure token usage
- [ ] Profile inference latency

---

## 5. Troubleshooting Guide

### Issue: "Invalid A2UI format"
**Solution:** Check that JSON is wrapped in \`\`\`a2ui ... \`\`\` blocks and valid JSON.

### Issue: "Places are too far apart"
**Solution:** Increase `clusterRadiusKm` in ClusterBuilder tool call.

### Issue: "Token limit exceeded"
**Solution:** Call OSMSlimmer with fewer categories or lower `maxResults`.

### Issue: "Wheelchair access not respected"
**Solution:** Ensure VibeAnalyzer checks "w:yes" in signatures when analyzing.

---

**Document Version:** 1.0  
**Status:** Ready for Implementation
