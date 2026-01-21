# Phase 5: GenUI-Driven AI Travel Agent

**Status:** 📚 Complete Architecture + Ready for Implementation  
**Last Updated:** 2026-01-21T18:16:14.666Z

---

## What is Phase 5?

A complete redesign of the travel planner app to use:

1. **Local LLM (Gemini Nano)** for all intelligence
2. **OpenStreetMap data** with rich semantic tagging
3. **flutter_genui** for AI-generated dynamic UI
4. **A2UI protocol** for LLM-to-UI communication
5. **Vibe signatures** for token-efficient semantic discovery

---

## Quick Example

```
User: "3 days in Prague. Quiet history, local cafes."

System:
1. OSMService fetches museums, cafes, historic sites
2. DiscoveryProcessor creates vibe signatures:
   - Monastery: "v:history,quiet;h:14thC;l:local;f:yes;w:limited"
   - Coffee Roastery: "v:social,artsy;l:local;c:specialty_coffee;f:paid;w:yes"
3. SpatialClusterer groups by proximity
4. LocalLLMService (Gemini Nano) analyzes patterns
5. LLM emits A2UI JSON for UI rendering
6. App shows interactive map + day-by-day itinerary
7. User clicks "Add to Trip" → LLM re-plans live
```

---

## 📚 Documentation Files

### For Project Overview
- **README_PHASE_5.md** ← You are here
- **PHASE_5_DOCUMENTATION_SUMMARY.txt** - Complete index

### For Architecture Understanding
1. **PHASE_5_QUICK_START.md** - Start here! (60-second overview + checklist)
2. **PHASE_5_GENUI_ARCHITECTURE.md** - Full architecture with diagrams
3. **PHASE_5_LLM_TOOLS_AND_PROMPTS.md** - Tool specs + system prompts

### For Implementation
- **PHASE_5_IMPLEMENTATION_REFERENCE.md** - Copy-paste ready code

### For Project Context
- **CONTEXT.md** - How Phase 5 fits in the bigger picture

---

## 🎯 What You Can Find In Each Document

| Document | Best For | Read Time |
|----------|----------|-----------|
| **QUICK_START** | Getting oriented, checklist | 15 min |
| **ARCHITECTURE** | Understanding design, data flow | 45 min |
| **TOOLS_AND_PROMPTS** | LLM tool specs, example outputs | 30 min |
| **IMPLEMENTATION** | Actually writing the code | 60+ min |
| **DOCUMENTATION_SUMMARY** | Index of all docs | 10 min |

---

## 🚀 Implementation Roadmap

```
Week 1: Data Services (Phase 5a)
├─ OSMService (Overpass API integration)
├─ DiscoveryProcessor (Vibe signature generation)
└─ SpatialClusterer (Day grouping algorithm)

Week 2: LLM Engine (Phase 5b)
├─ LocalLLMService (Gemini Nano + system prompt)
├─ Tool calling (4 tools for data discovery)
└─ A2UI parsing (Extract JSON from LLM response)

Week 3: UI & GenUI (Phase 5c)
├─ GenUI widget catalog (3 widgets)
├─ A2uiMessageProcessor (Match widgets to AI output)
└─ DiscoverySurface (Main container + interaction handling)

Week 4: Testing (Phase 5d)
├─ iOS simulator validation
├─ Android device testing
├─ Performance profiling
└─ Offline map caching
```

---

## 🔑 Key Concepts

### Vibe Signature
Token-efficient representation of place characteristics:

```
Format: "v:vibe1,vibe2;attribute:value;..."

Example: "v:history,quiet;h:14thC;l:local;f:yes;w:limited"
Tokens: 6 (vs 60+ for raw OSM tags)
Savings: 87%
```

**Vibe Categories:**
- `history`, `nature`, `social`, `culture`, `quiet`, `artsy`, `adventurous`, `romantic`

**Attributes:**
- `h` = heritage (14thC, medieval, baroque, etc.)
- `l` = localness (local or chain)
- `f` = fee (yes, no, donation)
- `w` = wheelchair (yes, limited, no)
- `c` = cuisine type
- `d` = distance category

### A2UI Protocol
LLM outputs UI instructions as JSON wrapped in ```a2ui ... ``` blocks:

```json
{
  "type": "SmartMapSurface",  // Widget type
  "payload": {
    "places": [...],          // Place data
    "zoom": 14
  }
}
```

**Only 3 widgets allowed:**
1. `PlaceDiscoveryCard` - Individual place display
2. `SmartMapSurface` - OSM map with pins
3. `RouteItinerary` - Day-by-day itinerary

### Local LLM as Orchestrator
Gemini Nano sits at the center:
- Receives minified discovery data
- Analyzes vibe patterns
- Invokes tools (OSMSlimmer, DistanceMatrix, VibeAnalyzer, ClusterBuilder)
- Reasons about spatial clustering
- Emits A2UI UI instructions

---

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **LLM** | Gemini Nano (2B params) | All reasoning & planning |
| **UI Generation** | flutter_genui + A2UI | Dynamic component rendering |
| **Data Source** | OpenStreetMap + Overpass API | Attraction data |
| **Mapping** | flutter_map | Interactive maps |
| **State** | Provider | State management |
| **Logging** | logger package | Transparency |
| **HTTP** | http package | API calls |

---

## 📝 Transparency Logging

Every layer has logging with prefixes:

```
[OSM]           - Overpass API operations
[DISCOVERY]     - Vibe signature generation
[CLUSTER]       - Spatial clustering
[LLM_INPUT]     - What we send to LLM
[LLM_OUTPUT]    - What LLM returns
[LLM_ERROR]     - LLM errors
[A2UI]          - A2UI parsing
[WIDGET]        - Widget interactions
```

Complete audit trail of data flow through the system.

---

## 💡 Why This Architecture?

### Token Efficiency
- Vibe signatures: 6 tokens
- Raw OSM tags: 60+ tokens
- Savings: 87%

### Local-First Privacy
- Zero API keys
- Zero cloud calls
- 100% on-device inference
- Zero data leakage

### Spatial Intelligence
- Distance-based clustering
- Proximity-aware recommendations
- Optimal routing within days

### GenUI-Driven
- UI not hard-coded
- Generated by AI based on context
- Highly customizable
- Adapts to user interactions

### Transparent
- Every input/output logged
- Inspect data at each layer
- Debug with confidence
- Understand why AI made decisions

---

## 🎯 Success Criteria

Phase 5 is complete when:

- [ ] User enters "3 days, quiet history Prague"
- [ ] OSM fetches 15+ relevant places
- [ ] Each place has vibe signature
- [ ] Clusterer groups into 3 day routes
- [ ] LLM analyzes and outputs A2UI
- [ ] App renders map + itinerary
- [ ] All operations logged with [PREFIX] tags
- [ ] User can interact and see live re-planning

---

## 🚀 Getting Started

### Step 1: Read the Quick Start
```bash
open PHASE_5_QUICK_START.md
```
Takes 15 minutes. Gives you the big picture.

### Step 2: Deep Dive Architecture
```bash
open PHASE_5_GENUI_ARCHITECTURE.md
```
Takes 45 minutes. Understand every component.

### Step 3: Check Tool Specs
```bash
open PHASE_5_LLM_TOOLS_AND_PROMPTS.md
```
Takes 30 minutes. See LLM tools and example outputs.

### Step 4: Start Coding
```bash
open PHASE_5_IMPLEMENTATION_REFERENCE.md
```
Copy code snippets. Follow the structure. Build incrementally.

---

## 📊 Expected Performance

| Metric | Target | Notes |
|--------|--------|-------|
| OSM fetch | < 5 sec | Overpass API response time |
| LLM inference | < 10 sec | Gemini Nano on-device |
| A2UI parsing | < 200 ms | JSON parsing |
| Total pipeline | < 15 sec | End-to-end user input to rendered UI |
| Token per place | < 10 | Average signature size |
| Context size | < 2000 tokens | Max input to LLM |
| Token savings | > 80% | vs raw OSM tags |

---

## 🔗 Quick Links

- **Google Generative AI**: https://ai.google.dev/
- **flutter_genui Package**: https://pub.dev/packages/flutter_genui
- **OpenStreetMap Overpass**: https://overpass-turbo.eu/
- **Haversine Distance**: https://en.wikipedia.org/wiki/Haversine_formula
- **A2UI Protocol**: https://github.com/google/generative-ai-js/blob/main/docs/a2ui.md

---

## 📞 Documentation Hierarchy

```
START HERE
    ↓
QUICK_START.md (60-second overview)
    ↓
ARCHITECTURE.md (full design)
    ↓
TOOLS_AND_PROMPTS.md (LLM specs)
    ↓
IMPLEMENTATION_REFERENCE.md (code templates)
    ↓
BEGIN CODING
```

---

## ✅ Checklist to Start Implementation

- [ ] Read QUICK_START.md (15 min)
- [ ] Read ARCHITECTURE.md (45 min)
- [ ] Read TOOLS_AND_PROMPTS.md (30 min)
- [ ] Skim IMPLEMENTATION_REFERENCE.md (5 min)
- [ ] Create lib/services/osm/ directory
- [ ] Create lib/services/discovery/ directory
- [ ] Create lib/services/spatial/ directory
- [ ] Create lib/services/ai/ directory
- [ ] Create lib/genui/ directory
- [ ] Begin Phase 5a implementation (Week 1)

---

## 🎓 Learning Resources

1. **Understand Vibe Signatures**
   - See QUICK_START.md → "Vibe Vocabulary"
   - See ARCHITECTURE.md → Phase 2 section

2. **Understand A2UI Protocol**
   - See QUICK_START.md → "A2UI Protocol"
   - See TOOLS_AND_PROMPTS.md → "Example A2UI Outputs"

3. **Understand Data Flow**
   - See ARCHITECTURE.md → "Architecture Overview" (diagram)
   - See QUICK_START.md → "Architecture in One Diagram"

4. **Understand Tool Calling**
   - See TOOLS_AND_PROMPTS.md → "Section 1: Tool Definitions"
   - See ARCHITECTURE.md → "Phase 5: Tool Definitions for LLM"

5. **Understand Implementation**
   - See IMPLEMENTATION_REFERENCE.md → Each section
   - Follow code entry points (5 steps)

---

## 🎯 Philosophy

> **"The LLM is the intelligence. The services are the tools. The UI is the canvas."**

- LLM shouldn't be a black box; it should be transparent
- Services shouldn't be dumb; they should provide rich context
- UI shouldn't be hard-coded; it should be generated

---

## 📮 Questions?

Refer to the relevant documentation:

- "How do I structure code?" → IMPLEMENTATION_REFERENCE.md
- "What is a vibe signature?" → QUICK_START.md
- "How does LLM work?" → TOOLS_AND_PROMPTS.md
- "What's the big picture?" → ARCHITECTURE.md
- "What document should I read?" → DOCUMENTATION_SUMMARY.txt

---

**Good luck! Phase 5 is ready. Start building! 🚀**

