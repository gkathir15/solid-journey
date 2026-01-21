# 🔍 Phase 5: The Intelligent Discovery Layer

## Overview

**Phase 5** introduces the **Data Discovery & Slimming Engine** - a sophisticated middle layer between the UI and LLM that extracts rich OSM metadata, creates token-efficient "vibe signatures", and enables intelligent pattern matching.

This is where the magic happens: turning raw open data into actionable discovery insights.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                             │
│         (Shows recommendations & hidden gems)                │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│        DISCOVERY ORCHESTRATOR (Phase 5)                      │
│  Coordinates entire discovery pipeline                       │
└────┬────────────┬────────────────┬────────────────┬─────────┘
     │            │                │                │
┌────▼─┐  ┌──────▼────┐  ┌────────▼─────┐  ┌──────▼───────┐
│ Phase│  │  Phase 2  │  │   Phase 3    │  │   Phase 4    │
│  1   │  │ PROCESS   │  │    REASON    │  │   DELIVER    │
│      │  │           │  │              │  │              │
│HARVEST   │Transform  │  │  LLM finds   │  │  Curate &    │
│          │OSM tags   │  │  patterns in │  │  rank        │
│          │into vibe  │  │  signatures  │  │  results     │
│          │signatures │  │              │  │              │
└────────┘ └───────────┘ └──────────────┘ └──────────────┘
```

## The Four Phases

### PHASE 1: Universal Tag Harvester 🏷️

**Purpose**: Extract deep OSM metadata

**What it harvests**:
- **Primary categories**: amenity, tourism, historic, leisure, heritage, shop, craft, man_made, natural
- **Secondary metadata**: 
  - Heritage info (level, century, style)
  - Dining details (cuisine, diet options)
  - Practical info (hours, fee, wheelchair access)
  - Verification (check_date, survey_date)

**Example output**:
```json
{
  "id": 12345,
  "name": "Louvre Museum",
  "lat": 48.8606,
  "lon": 2.3352,
  "primary_category": "tourism:museum",
  "heritage_level": "4",
  "historic_type": "building",
  "start_date": "1793",
  "architecture": "neoclassical",
  "opening_hours": "09:00-18:00",
  "fee": "yes",
  "wheelchair": "yes",
  "description": "World's largest art museum...",
  "raw_tags": { ...all OSM tags... }
}
```

### PHASE 2: Semantic Discovery Engine 🧠

**Purpose**: Transform raw tags into compact "Vibe Signatures"

**Vibe Signature Components**:

#### 1. **The Heritage Link**
```
Input: historic:castle, heritage:2, start_date:1650, architecture:baroque
Output: h:h2,hist:castle,c:17th,arch:baroque
```
Extracts:
- Heritage level (h1-h4)
- Historic type
- Century (from date)
- Architectural style
- Artist info

#### 2. **The Localness Test**
```
Input: operator:"Jean's Family Cafe", no global brand detected
Output: l:local

Input: operator:"Starbucks"
Output: l:chain
```
Checks:
- Is operator a global brand?
- Is it independent or corporate?
- Local character vs. chain homogeneity

#### 3. **The Activity Profile**
```
Input: leisure:hackerspace, craft:brewery
Output: a:tech,a:craft

Input: leisure:nature_reserve
Output: a:nature
```
Maps to social vibes:
- tech, craft, interactive
- social, nightlife
- quiet, culture, art
- entertainment, family, outdoor

#### 4. **The Natural Anchor**
```
Input: natural:wood, viewpoint:yes
Output: n:nature,n:serene,n:quiet
```
Identifies serene/nature spots

#### 5. **Final Compact Format**
```
FULL: h:h3,hist:castle,c:18th,arch:baroque;l:local;a:culture;n:quiet;s:free,no_smoke;acc:wc:yes

MINIFIED: h:h3,hist;l:local;a:culture;n:quiet;s:free;acc:wc
```

**Why minification matters**:
- Original OSM JSON: ~2KB per place
- Vibe signature: ~100 bytes
- Token savings: ~95% reduction for LLM consumption

### PHASE 3: LLM Discovery Reasoner 🤖

**Purpose**: LLM analyzes signatures to find patterns

**Discovery Persona**:
```
"You are a Travel Discovery Expert.
Analyze vibe signatures to find:
1. Direct matches (user vibe = signature content)
2. Semantic matches (user wants 'quiet' → look for n:nature)
3. Hidden gems (unexpected matches that fit the vibe)
4. Justifications (WHY each place matches)"
```

**Example Reasoning**:

User: "I want Quiet History"
LLM sees: h:*, n:quiet
LLM finds:
1. "Old Library" → h:h2,hist:building,c:18th; l:local; n:quiet ✅ Perfect
2. "Historic Garden" → h:h3; n:nature,quiet; s:free ✅ Great
3. "Antique Market" → h:h2,l:local; s:free ✅ Hidden gem (busy but historic)

Each with justification:
```
"Old Library": "I chose this because it's a locally-owned 18th-century 
building (h:h2,c:18th,l:local) in a quiet area (n:quiet) - exactly 
what you're looking for."
```

### PHASE 4: Final Delivery 📦

**Output format**:
```json
{
  "city": "Paris",
  "userVibe": "Quiet History",
  "totalAnalyzed": 245,
  "primaryRecommendations": [
    {
      "id": 1,
      "name": "Old Library",
      "signature": "h:h2,c:18th,l:local;n:quiet",
      "score": 9.5,
      "reason": "Locally-owned 18th-century library in quiet area"
    },
    ...
  ],
  "hiddenGems": [
    {
      "id": 245,
      "name": "Forgotten Antique Shop",
      "signature": "h:h3,l:indie;a:culture",
      "score": 7.2,
      "reason": "Hidden 19th-century gem with local character"
    }
  ]
}
```

## Token Efficiency

### Without Discovery Engine
```
User vibe: "Quiet History"
Send to LLM: All 245 attraction records (2KB each) = 490KB total
Token cost: ~50,000 tokens
```

### With Discovery Engine
```
User vibe: "Quiet History"
Send to LLM: 
  - Vibe signatures: 100 bytes each = 24.5 KB total
  - User query: 50 bytes
Token cost: ~2,500 tokens (95% reduction!)

Plus LLM gets CLEANER signal:
h:h2,c:18th,l:local,n:quiet
(Easy to pattern match)
```

## Vibe Signature Reference

### Heritage Components
| Signature | Meaning |
|-----------|---------|
| h:h1 | UNESCO World Heritage |
| h:h2 | National Heritage |
| h:h3 | Regional Heritage |
| h:h4 | Local Heritage |
| hist:castle | Historic castle |
| hist:church | Historic church |
| c:18th | Built in 1700s |
| arch:baroque | Baroque architecture |

### Localness Components
| Signature | Meaning |
|-----------|---------|
| l:local | Independent/local operator |
| l:indie | Likely independent |
| l:chain | Global brand |

### Activity Components
| Signature | Meaning |
|-----------|---------|
| a:tech | Tech/hackerspace vibe |
| a:craft | Craft/artisan vibe |
| a:culture | Museums/galleries |
| a:art | Art-focused |
| a:nature | Outdoor/natural |
| a:social | Social dining |
| a:quiet | Peaceful atmosphere |

### Sensory Signals
| Signature | Meaning |
|-----------|---------|
| s:free | Free entry |
| s:paid | Paid entry |
| s:outdoor | Has outdoor seating |
| s:no_smoke | Non-smoking |

### Accessibility
| Signature | Meaning |
|-----------|---------|
| acc:wc:yes | Full wheelchair access |
| acc:wc:limited | Limited access |
| acc:wc:no | Not wheelchair accessible |

## Real-World Example

### Paris - "Artisan & Local" Vibe

**User Request**:
```
City: Paris
Categories: cafes, shops, galleries
Vibe: "Artisan and Local"
Context: "I want to support independent makers, find unique crafts"
```

**Discovery Process**:

1. **Harvest** (200 cafes/shops/galleries)
   - Extract operator names
   - Get cuisine types (for cafes)
   - Find shop types

2. **Process** (200 vibe signatures)
   ```
   Cafe 1: "Marie's Coffee" 
   → l:local;a:cafe;cuis:specialty;outdoor;s:free_wifi
   
   Cafe 2: "Starbucks"
   → l:chain;a:cafe;cuis:coffee;s:wifi
   
   Shop 1: "Local Pottery Studio"
   → l:indie;a:craft;craft:pottery;f:workshop
   
   Gallery 1: "Street Art Collective"
   → l:local;a:art;arch:street_art;outdoor
   ```

3. **Reason** (LLM finds patterns)
   ```
   Query: "l:local OR l:indie" AND "a:craft OR a:art"
   
   Top Match: "Local Pottery Studio"
   → l:indie;a:craft;craft:pottery
   Score: 9.8
   Reason: "Indie pottery studio - exactly the artisan 
            maker you want to support"
   
   Hidden Gem: "Street Art Collective"
   → l:local;a:art;arch:street_art;outdoor
   Score: 8.5
   Reason: "Local-run street art space - unique, 
           underground character"
   ```

4. **Deliver**
   ```
   PRIMARY (3):
   1. Local Pottery Studio (9.8)
   2. Artisan Bread Bakery (9.5)
   3. Independent Jewelry Maker (9.2)
   
   HIDDEN GEMS (2):
   1. Street Art Collective (8.5)
   2. Vintage Textile Workshop (8.1)
   ```

## Implementation Integration

### File Structure
```
lib/services/
├── universal_tag_harvester.dart      ✅ PHASE 1
├── semantic_discovery_engine.dart    ✅ PHASE 2
├── llm_discovery_reasoner.dart      ✅ PHASE 3
└── discovery_orchestrator.dart       ✅ PHASE 4
```

### Usage Example
```dart
final orchestrator = DiscoveryOrchestrator();

final output = await orchestrator.discover(
  city: 'Paris',
  categories: ['museum', 'cafe', 'gallery'],
  userVibe: 'Artisan and Local',
  userContext: 'I want to support independent makers',
);

// Get primary recommendations
final primary = output.getPrimaryLLMFormat();

// Get all signatures for agent reasoning
final allSigs = output.getAllSignaturesLLMFormat();

// Export for next phase
final json = output.toJson();
```

## Benefits of This Approach

### ✅ **Token Efficiency**
- 95% reduction in token usage
- LLM processes cleaner signals
- Faster inference

### ✅ **Rich Context**
- Full OSM metadata harvested
- Vibe signatures encode character
- LLM can make sophisticated matches

### ✅ **Explainability**
- Each recommendation justified
- LLM explains WHY via signature analysis
- Users understand the discovery logic

### ✅ **Scalability**
- Works for any city
- Any number of attractions
- Any user vibe definition

### ✅ **Privacy**
- All processing local
- No external API calls beyond Overpass
- No user data stored

## Next Integration Points

### To Phase 3 (Spatial Clustering)
- Use vibe signatures to enhance clustering
- Filter clusters by user vibe
- Prioritize anchor points by signature quality

### To Phase 4 (Mapping)
- Display vibe signature on map pins
- Color pins by heritage level
- Show "local" badge on map

### To UI/GenUI
- Show vibe signature breakdown
- Highlight why each place matches
- Let users explore signature components

## Status

| Component | Status |
|-----------|--------|
| Universal Tag Harvester | ✅ Complete |
| Semantic Discovery Engine | ✅ Complete |
| LLM Discovery Reasoner | ✅ Complete |
| Discovery Orchestrator | ✅ Complete |
| Integration Tests | ⏳ Next |
| UI Integration | ⏳ Next |

---

**Phase 5 Status**: 🔍 Complete and Ready  
**Token Savings**: 95% reduction  
**Data Fidelity**: Maximum (all OSM tags)  
**LLM Integration**: Ready for Gemini Nano  

Ready to integrate with Phases 1-4! 🚀
