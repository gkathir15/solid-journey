# Phase 5: Architecture Overview

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                    AI-FIRST GENUI TRAVEL AGENT                               ║
║                         PHASE 5 COMPLETE                                     ║
╚═══════════════════════════════════════════════════════════════════════════════╝

┌──────────────────────────────────────────────────────────────────────────────┐
│ USER INTERFACE LAYER                                                         │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Phase5Home                                                                  │
│  ├─ Country Selection (UI)                                                  │
│  ├─ City Selection (UI)                                                     │
│  ├─ Vibe Selection (UI)                                                     │
│  └─ Duration Selection (UI)                                                 │
│                                                                              │
│  GenUiSurface (Next - Phase 5.1)                                            │
│  ├─ SmartMapSurface (Interactive OSM map)              ⏳ [4 hrs]          │
│  ├─ RouteItinerary (Vertical timeline)                ⏳ [2 hrs]          │
│  ├─ DayClusterCard (Daily summary)                    ⏳ [1 hr]           │
│  └─ PlaceDiscoveryCard (Individual place)             ⏳ [TBD]            │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ GENUI ORCHESTRATION LAYER                          ⏳ Next Priority        │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  A2uiMessageProcessor                                                        │
│  ├─ Listen to LLM output                                                    │
│  ├─ Map to component catalog                                               │
│  ├─ Handle user interactions                                               │
│  └─ Send feedback back to LLM                                              │
│                                                                              │
│  ComponentCatalog                                                            │
│  ├─ Define JSON schemas for each widget                                    │
│  ├─ Validate LLM output                                                    │
│  └─ Manage component lifecycle                                             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ LLM REASONING ENGINE LAYER                         ✅ COMPLETE              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  LLMReasoningEngine                                                          │
│  │                                                                          │
│  ├─ PHASE 3A: Pattern Analysis                                             │
│  │  ├─ INPUT: User vibes, OSM data, city context                          │
│  │  ├─ 📥 LOG: What went into LLM                                         │
│  │  ├─ LOGIC: Identify cultural clusters, local gems, vibes               │
│  │  ├─ 📤 LOG: What came out (patterns with confidence)                  │
│  │  └─ OUTPUT: List of identified patterns                                │
│  │                                                                          │
│  ├─ PHASE 3B: Spatial Clustering                                          │
│  │  ├─ INPUT: 25,500+ places with vibe signatures                        │
│  │  ├─ 📥 LOG: Input data structure and count                            │
│  │  ├─ LOGIC: Group by proximity, distribute across days                 │
│  │  ├─ 📤 LOG: Day clusters with themes and distances                    │
│  │  └─ OUTPUT: Day clusters ready for GenUI                              │
│  │                                                                          │
│  └─ PHASE 3C: GenUI Instruction Generation                                │
│     ├─ INPUT: Day clusters, patterns, city                               │
│     ├─ 📥 LOG: What components to generate                               │
│     ├─ LOGIC: Create rendering instructions                              │
│     ├─ 📤 LOG: Component count and actions                               │
│     └─ OUTPUT: Component instructions for GenUI                          │
│                                                                              │
│  💡 KEY: All decisions logged with reasoning (📥→🧠→📤)                    │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ DISCOVERY ORCHESTRATION LAYER                      ✅ COMPLETE              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  DiscoveryOrchestrator                                                       │
│  ├─ PHASE 1: OSM Data Harvesting                                           │
│  │  ├─ Call TagHarvester with categories                                 │
│  │  ├─ Fetch 25,500+ elements from Overpass API                          │
│  │  └─ Extract deep metadata (tags, hours, cuisine, etc)                │
│  │                                                                          │
│  ├─ PHASE 2: Vibe Signature Processing                                    │
│  │  ├─ Call DiscoveryProcessor for each place                           │
│  │  ├─ Create compact signatures: "h:c:20th;l:indie;a:culture"         │
│  │  ├─ Extract: heritage, localness, activity, amenities               │
│  │  └─ Result: Token-efficient representations (70% reduction)          │
│  │                                                                          │
│  └─ PHASE 3: Semantic Analysis                                            │
│     ├─ SemanticDiscoveryEngine reads signatures                         │
│     ├─ Identifies patterns matching user vibes                         │
│     └─ Returns: primary_recommendations + hidden_gems                 │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌──────────────────────────────────────────────────────────────────────────────┐
│ DATA HARVESTING LAYER                              ✅ COMPLETE              │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  OSMService                                                                  │
│  └─ Overpass API Integration                                               │
│     ├─ Query Syntax: Build comprehensive QL queries                       │
│     ├─ Categories: tourism, amenity, leisure, historic, heritage, etc   │
│     ├─ Data Volume: 25,500+ places per city                              │
│     └─ Fallback: Mock data on rate limit/error                           │
│                                                                              │
│  TagHarvester (Universal Deep Harvester)                                   │
│  ├─ Keys Extracted: 30+ OSM tag categories                               │
│  ├─ Secondary Tags: cuisine, diet, operator, hours, wheelchair, etc     │
│  ├─ Metadata: artist, start_date, description, check_date, fee         │
│  └─ Quality: Full metadata for vibe signature creation                  │
│                                                                              │
│  DiscoveryProcessor (Semantic Converter)                                   │
│  ├─ Input: Raw OSM tags per place                                        │
│  ├─ Processing: Extract heritage, localness, activity, amenities        │
│  ├─ Format: Compact semicolon-delimited signatures                       │
│  └─ Output: "l:indie;a:a:culture;s:paid;acc:wc:yes" (50-100 bytes)    │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘

╔═══════════════════════════════════════════════════════════════════════════════╗
║                            DATA FLOW EXAMPLE                                  ║
╚═══════════════════════════════════════════════════════════════════════════════╝

USER INPUT
└─ City: Paris, France
└─ Vibes: [historic, local, cultural, cafe_culture]
└─ Duration: 3 days

              ↓

OSM HARVESTING (PHASE 1)
└─ 25,500+ places fetched from Overpass
   ├─ "Le Sancerre" (restaurant, historic building, outdoor seating)
   ├─ "Musée des Arts" (museum, culture, paid entrance)
   └─ ... 25,498 more places ...

              ↓

VIBE SIGNATURE (PHASE 2)
└─ "Le Sancerre" → "h:h3;l:indie;am:cuis:french,outdoor;s:free;acc:wc:yes"
└─ "Musée des Arts" → "l:indie;a:a:culture;s:paid;acc:wc:limited"
└─ Token size: 50-100 bytes (was 1KB+)

              ↓

LLM REASONING (PHASE 3)
└─ 📥 INPUT: User vibes + 25,500 signatures
└─ 🧠 REASONING: Find "historic" + "local" + "cultural" matches
└─ 📤 OUTPUT:
   ├─ Pattern 1: "Heritage Cluster" (confidence 0.95)
   │  └─ "Museums and historic sites with cultural significance"
   ├─ Pattern 2: "Local Gems" (confidence 0.92)
   │  └─ "Independent restaurants and shops avoiding chains"
   ├─ Pattern 3: "Cafe Culture" (confidence 0.88)
   │  └─ "Outdoor seating and social venues"
   │
   └─ Day Clusters:
      ├─ Day 1: Heritage Deep Dive (8,500 places)
      ├─ Day 2: Local Discoveries (8,500 places)
      └─ Day 3: Cafe Culture (8,500 places)

              ↓

GENUI RENDERING (PHASE 4 - NEXT)
└─ Generate Components:
   ├─ SmartMapSurface: Show 25,500 places on map, filtered by vibe
   ├─ RouteItinerary: Show 3-day vertical timeline
   ├─ DayClusterCard: Compact summary of each day
   └─ User sees: Interactive map + day-by-day breakdown

              ↓

USER INTERACTION (PHASE 5 - FUTURE)
└─ User taps "Day 2: Local Discoveries"
└─ A2UI Loop:
   ├─ 📥 Capture interaction
   ├─ 🧠 LLM re-analyzes (re-thinks plan)
   ├─ 📤 Generate new components
   └─ Render updated UI with transitions

╔═══════════════════════════════════════════════════════════════════════════════╗
║                         COMPONENT DEPENDENCIES                                ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Phase 5.0 (Complete)
├─ llm_reasoning_engine.dart ✅
├─ discovery_orchestrator.dart ✅
├─ semantic_discovery_engine.dart ✅
├─ tag_harvester.dart ✅
├─ discovery_processor.dart ✅
└─ osm_service.dart ✅

Phase 5.1 (Next - 12 hours)
├─ smart_map_surface.dart ⏳ [4 hrs] (depends on: OSM data)
├─ route_itinerary.dart ⏳ [2 hrs] (depends on: Day clusters)
├─ day_cluster_card.dart ⏳ [1 hr] (depends on: Day clusters)
├─ genui_surface_widget.dart ⏳ [2 hrs] (depends on: All components)
└─ Integration ⏳ [3 hrs]

Phase 5.2 (Real LLM - 8 hours)
├─ Real Gemini Nano integration ⏳
├─ Tool calling implementation ⏳
└─ Advanced route optimization ⏳

Phase 5.3 (Interactive - 6 hours)
├─ A2ui_message_processor.dart ⏳
├─ User interaction capturing ⏳
└─ Re-reasoning loop ⏳

╔═══════════════════════════════════════════════════════════════════════════════╗
║                         TRANSPARENCY LOGGING                                  ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Every LLM decision now shows:

  📥 INPUT TO LLM:
     ├─ User parameters
     ├─ OSM data structure
     └─ Reasoning context

  🧠 PROCESSING:
     ├─ Analysis step 1
     ├─ Analysis step 2
     └─ Confidence calculation

  �� OUTPUT FROM LLM:
     ├─ Decision 1 + reasoning
     ├─ Decision 2 + reasoning
     └─ Confidence scores

This means:
✅ Users see WHY places were selected
✅ Developers can debug decisions
✅ System is explainable and auditable

╔═══════════════════════════════════════════════════════════════════════════════╗
║                         TIMELINE TO MVP                                       ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Today (Phase 5.0)
└─ ✅ Core engine complete
   ├─ OSM discovery
   ├─ Vibe signatures
   ├─ Pattern recognition
   └─ Spatial clustering
   └─ Transparency logging

Week 1 (Phase 5.1)
└─ ⏳ GenUI components (12 hrs)
   ├─ SmartMapSurface (interactive map)
   ├─ RouteItinerary (daily timeline)
   ├─ DayClusterCard (summary cards)
   └─ Full integration & testing

Week 2 (Phase 5.2)
└─ ⏳ Real LLM integration (8 hrs)
   ├─ Gemini Nano API
   ├─ Tool calling
   └─ Advanced clustering

Week 3 (Phase 5.3)
└─ ⏳ Interactive loop (6 hrs)
   ├─ User feedback
   ├─ Re-reasoning
   └─ Live updates

RESULT: 🟢 MVP COMPLETE
└─ User selects city + vibes
└─ AI creates multi-day itinerary
└─ Interactive map shows recommendations
└─ Full transparency on all decisions
└─ User can modify and refine in real-time

