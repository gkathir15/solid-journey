# Start Integration - Phase 5 GenUI

## You Are Here
✅ Components built and documented
⏳ Ready to integrate with existing services

## What Needs Integration

The **GenUI layer** needs to hook into the **discovery pipeline**.

Current state:
```
discovery_orchestrator.dart
└── Calls OSM, vibe engine, LLM
    └── Returns raw JSON data
```

Needed state:
```
discovery_orchestrator.dart
├── Calls OSM, vibe engine, LLM
│   └── Returns raw JSON data
└── GenUiOrchestrator
    └── Parses JSON → Renders GenUiSurface
        └── Shows interactive itinerary to user
```

## 3 Changes Required

### 1. Import GenUI Classes
In `discovery_orchestrator.dart`, add:
```dart
import 'package:travel_filter_app/genui/genui_orchestrator.dart';
import 'package:travel_filter_app/genui/component_catalog.dart';
```

### 2. Create GenUI Orchestrator
In `DiscoveryOrchestrator` class, add:
```dart
late GenUiOrchestrator _genui;

void initialize() {
  _genui = GenUiOrchestrator(discoveryOrchestrator: this);
}
```

### 3. Return GenUI Surface
Change the main method from returning JSON to returning Widget:
```dart
// Before:
Future<Map<String, dynamic>> orchestrate({...}) async {
  // ... OSM, vibe, LLM logic
  return itineraryJson;
}

// After:
Future<Widget> generateItineraryUI({
  required String city,
  required String country,
  required List<String> selectedVibes,
}) async {
  return GenUiSurface(
    orchestrator: _genui,
    city: city,
    country: country,
    selectedVibes: selectedVibes,
  );
}
```

## Testing Flow

1. **Basic Rendering**
   - Create simple test
   - Select city "Paris"
   - Select vibe "historic"
   - Verify GenUiSurface appears

2. **Data Accuracy**
   - Verify OSM data fetching
   - Check vibe signature generation
   - Validate LLM reasoning output

3. **UI Display**
   - RouteItinerary shows all days
   - PlaceDiscoveryCard shows correct data
   - Loading state appears during processing

4. **Error Handling**
   - Test with invalid city
   - Test with network error
   - Verify error message displays

## Documentation to Reference

| Task | Document |
|------|----------|
| Quick overview | QUICK_START_PHASE_5.md |
| Component details | lib/genui/component_catalog.dart |
| Orchestrator logic | lib/genui/genui_orchestrator.dart |
| Complete reference | PHASE_5_COMPLETE_GUIDE.md |
| Implementation checklist | PHASE_5_CHECKLIST.md |

## Expected Timeline

- Integration: 4-6 hours
- Testing: 4-6 hours
- Debugging: 2-4 hours
- Cross-platform: 4-6 hours

**Total: 3-4 days**

## Success Criteria

✅ Clicks "Plan Trip"
✅ Selects vibe preferences  
✅ App fetches from OSM
✅ GenUI renders itinerary
✅ User sees interactive timeline
✅ All logging is visible
✅ Works on iOS & Android

## Debugging Checklist

If it's not working:

1. **Check logs** for `[GenUI]` tags
2. **Verify JSON schema** compliance
3. **Check error state** in GenUiSurface widget
4. **Test LLM output** independently
5. **Verify component mapping** in renderComponent()

## Next Command

After integration:
```bash
cd travel_filter_app
flutter run
# Should display: GenUiSurface loading → Itinerary rendering
```

Ready? Start with the 3 changes above!

