# Quick Start: Phase 5 Implementation

## 🚀 Get Started in 5 Minutes

### 1. Understand the Architecture (1 min)
```
User selects options (Phase5Home)
    ↓
LLM plans trip (GenUiSurface + DiscoveryOrchestrator)
    ↓
Shows itinerary (RouteItinerary)
```

### 2. Key Files to Know (2 min)
| File | Purpose |
|------|---------|
| `lib/phase5_home.dart` | User selection interface |
| `lib/genui/genui_orchestrator.dart` | AI ↔ UI bridge |
| `lib/genui/component_catalog.dart` | Widget definitions |
| `lib/services/discovery_orchestrator.dart` | Discovery pipeline |
| `lib/main.dart` | App entry point |

### 3. Run the App (1 min)
```bash
cd travel_filter_app
flutter clean
flutter pub get
flutter run
```

### 4. Try It Out (1 min)
1. Select country (France, Italy, Spain, etc)
2. Enter city (Paris, Rome, Barcelona, etc)
3. Set duration (1-14 days)
4. Select vibes (historic, local, cultural, etc)
5. Tap "Generate Itinerary"

## 📊 Data Flow Summary

```
Phase5Home Input:
  Country: France
  City: Paris
  Duration: 3 days
  Vibes: [historic, local, cultural]

↓ Discovery Pipeline ↓

HARVEST: Fetch OSM data (342 attractions)
PROCESS: Create vibe signatures
REASON: LLM matches to user preferences
DELIVER: Group into 3 day clusters

↓ GenUI Rendering ↓

RouteItinerary Widget shows:
  Day 1: Historic Journey (5 attractions, 5.2 km)
  Day 2: Cultural Deep Dive (5 attractions, 4.8 km)
  Day 3: Local Hidden Gems (5 attractions, 5.1 km)
```

## 🔍 Check the Logs

Look for these in the console:

```
[INFO] PHASE 1: HARVESTING OSM METADATA
[INFO] ✅ Harvested 342 elements

[INFO] PHASE 2: PROCESSING INTO VIBE SIGNATURES
[INFO] ✅ Created 342 vibe signatures
[INFO] SAMPLE SIGNATURES:
[INFO]   Louvre: v:museum,historic,cultural,family

[INFO] PHASE 3: LLM DISCOVERY REASONING
[INFO] ✅ Found 45 primary + 12 hidden gems

[INFO] PHASE 4: FINAL DISCOVERY OUTPUT
[INFO] Creating 3-day itinerary...
[INFO] ✅ Itinerary generated: 3 days
```

## 🎯 How It Works

### 1. User Selection
- Country chip selector
- City text input
- Duration slider (1-14 days)
- Vibe multi-select

### 2. Discovery (in order)
1. **Harvest**: Query OpenStreetMap for attractions
2. **Process**: Create vibe signatures from OSM tags
3. **Reason**: LLM analyzes which match user vibes
4. **Deliver**: Group into day clusters

### 3. Rendering
- Route Itinerary widget displays results
- Shows day number, theme, attractions
- Includes reasons why each was chosen

## 💡 Understanding Vibes

Each attraction gets a vibe signature:
```
Louvre → v:museum,historic,cultural,family,free
Notre-Dame → v:historic,religious,architecture
Musée Rodin → v:museum,artistic,local,1730s
```

User selects vibes → LLM finds matching signatures → Creates itinerary

## 🔧 Customization

### Add a New Vibe
Edit `lib/genui/component_catalog.dart`:
```dart
static const List<String> commonVibes = [
  'historic',
  'local',
  'quiet',
  'vibrant',
  'nature',
  // Add new ones here:
  'foodie',
  'luxury',
  ...
];
```

### Change Default Duration
Edit `lib/phase5_home.dart`:
```dart
int _selectedDuration = 3;  // Change this
```

### Modify Day Theme Generation
Edit `lib/services/discovery_orchestrator.dart`:
```dart
String _generateDayTheme(DayCluster cluster, List<String> vibes) {
  // Customize logic here
}
```

## 🧪 Testing

### Test the UI
```bash
# Run on desktop
flutter run -d macos

# Check selection works
# Verify "Generate Itinerary" button state
# See RouteItinerary renders
```

### Test Discovery
```bash
# Look at console logs
# Should see HARVEST → PROCESS → REASON → DELIVER
# Each phase shows progress
```

### Test LLM Integration
```bash
# When real Gemma is integrated:
# Check [LLM INPUT] logs
# Check [LLM OUTPUT] logs
# Verify reasoning is correct
```

## 🐛 Troubleshooting

| Issue | Fix |
|-------|-----|
| App won't start | `flutter clean && flutter pub get` |
| No attractions found | Check city name spelling |
| Takes too long | Check internet connection |
| Wrong results | Adjust selected vibes |
| No logs | Enable verbose: `flutter run -v` |

## 📚 Next Steps

1. **Read Architecture**: Check CONTEXT.md
2. **Understand Flow**: Review PHASE_5_COMPLETE_GUIDE.md
3. **Run Examples**: Try different cities and vibes
4. **Check Logs**: Understand what's happening behind scenes
5. **Extend It**: Add new vibes, customize themes

## 📞 Key Concepts

- **Phase5Home**: Where user selects options
- **GenUiSurface**: Where LLM takes over the planning
- **Discovery Pipeline**: HARVEST → PROCESS → REASON → DELIVER
- **Vibe Signature**: Compressed OSM metadata (v:tag1,tag2,tag3)
- **Day Cluster**: Group of nearby attractions for one day
- **RouteItinerary**: Final result showing all days

## 🎓 Learning Path

### Beginner (Read These First)
1. This file (Quick Start)
2. CONTEXT.md (Architecture)
3. phase5_home.dart (UI)

### Intermediate (Then Read)
4. genui/component_catalog.dart (Components)
5. discovery_orchestrator.dart (Pipeline)
6. PHASE_5_COMPLETE_GUIDE.md (Detailed Flow)

### Advanced (Deep Dive)
7. All service files
8. LLM integration details
9. OSM data structure

## ✅ Completion Checklist

- [ ] App runs without errors
- [ ] Phase5Home displays correctly
- [ ] Can select country, city, duration, vibes
- [ ] "Generate Itinerary" button works
- [ ] RouteItinerary widget shows results
- [ ] Logs show all 4 phases
- [ ] Results look reasonable

## 🏁 Success Criteria

✅ App compiles cleanly
✅ Phase5Home is interactive
✅ Discovery pipeline runs end-to-end
✅ RouteItinerary renders correctly
✅ Logs show transparent discovery process
✅ Results match user vibe preferences

---

**Status**: Ready to use and extend
**Last Updated**: 2026-01-22
**Next Phase**: Phase 6 (Map Integration)
