# Phase 5B: Quick Start Implementation Guide

**Status:** Phase 5A Complete ✅ | Ready for Phase 5B ⏳  
**Time to Complete:** ~3.5 hours  
**Difficulty:** Medium

---

## 🚀 STEP 1: Update Phase5Home (30 min)

### File: `lib/phase5_home.dart`

**Add these imports:**
```dart
import 'services/llm_reasoning_engine.dart';
import 'services/genui_orchestration_layer.dart';
```

**Replace the discovery call in `_planTrip()` method:**

OLD:
```dart
final result = await discoveryOrchestrator.orchestrate(
  city: selectedCity,
  country: selectedCountry,
  userVibes: selectedVibes,
  context: 'Trip planning for $selectedCity',
);
```

NEW:
```dart
// Initialize engines
final llmEngine = LLMReasoningEngine(
  discoveryOrchestrator: discoveryOrchestrator,
);

// Get LLM planning result
final planningResult = await llmEngine.planTrip(
  country: selectedCountry,
  city: selectedCity,
  userVibes: selectedVibes,
  durationDays: tripDuration,
);

// Convert to GenUI components
final genUiOrch = GenUiOrchestrationLayer();
final surfaceUpdate = await genUiOrch.orchestrateUiFromLLMResult(
  llmResult: planningResult,
);

// Pass to GenUI renderer
_showGenUiPlan(surfaceUpdate);
```

**Add the renderer method:**
```dart
void _showGenUiPlan(GenUiSurfaceUpdate surfaceUpdate) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GenUiSurfaceRenderer(surfaceUpdate: surfaceUpdate),
    ),
  );
}
```

---

## 🎨 STEP 2: Create GenUI Surface Renderer (45 min)

### File: `lib/genui/genui_surface_renderer.dart`

```dart
import 'package:flutter/material.dart';
import '../services/genui_orchestration_layer.dart';

class GenUiSurfaceRenderer extends StatefulWidget {
  final GenUiSurfaceUpdate surfaceUpdate;

  const GenUiSurfaceRenderer({required this.surfaceUpdate});

  @override
  _GenUiSurfaceRendererState createState() => _GenUiSurfaceRendererState();
}

class _GenUiSurfaceRendererState extends State<GenUiSurfaceRenderer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.surfaceUpdate.metadata['city']} Trip'),
        elevation: 0,
      ),
      body: ListView(
        children: widget.surfaceUpdate.components.map((component) {
          return _buildComponent(component);
        }).toList(),
      ),
    );
  }

  Widget _buildComponent(GenUiComponentSpec component) {
    switch (component.type) {
      case 'RouteItinerary':
        return RouteItineraryWidget(props: component.props);
      
      case 'DayClusterCard':
        return DayClusterCardWidget(props: component.props);
      
      case 'SmartMapSurface':
        return SmartMapSurfaceWidget(props: component.props);
      
      case 'PlaceDiscoveryCard':
        return PlaceDiscoveryCardWidget(props: component.props);
      
      default:
        return SizedBox(height: 0);
    }
  }
}
```

---

## 🧩 STEP 3: Create Component Widgets (2 hours)

### 3.1: RouteItinerary Widget
**File:** `lib/genui/widgets/route_itinerary_widget.dart`

```dart
import 'package:flutter/material.dart';

class RouteItineraryWidget extends StatelessWidget {
  final Map<String, dynamic> props;

  const RouteItineraryWidget({required this.props});

  @override
  Widget build(BuildContext context) {
    final days = props['days'] as List? ?? [];

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your ${days.length}-Day Journey',
            style: Theme.of(context).textTheme.headline6,
          ),
          SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: days.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (_, index) {
              final day = days[index] as Map;
              return ListTile(
                leading: CircleAvatar(
                  child: Text('${day['day_number']}'),
                ),
                title: Text(day['theme'] ?? 'Day ${day['day_number']}'),
                subtitle: Text('${day['places']?.length ?? 0} places'),
                trailing: Icon(Icons.arrow_forward),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### 3.2: DayClusterCard Widget
**File:** `lib/genui/widgets/day_cluster_card_widget.dart`

```dart
import 'package:flutter/material.dart';

class DayClusterCardWidget extends StatelessWidget {
  final Map<String, dynamic> props;

  const DayClusterCardWidget({required this.props});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day ${props['day']}',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    props['theme'] ?? '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Icons.location_on, size: 20, color: Colors.grey),
                    SizedBox(height: 4),
                    Text('${props['place_count']} places'),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.directions_walk, size: 20, color: Colors.grey),
                    SizedBox(height: 4),
                    Text('${props['estimated_distance_km']?.toStringAsFixed(1) ?? '0'} km'),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.access_time, size: 20, color: Colors.grey),
                    SizedBox(height: 4),
                    Text('${props['best_time']}'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            if (props['highlights'] != null && (props['highlights'] as List).isNotEmpty)
              Text(
                'Highlights: ${(props['highlights'] as List).join(", ")}',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
```

### 3.3: PlaceDiscoveryCard Widget
**File:** `lib/genui/widgets/place_discovery_card_widget.dart`

```dart
import 'package:flutter/material.dart';

class PlaceDiscoveryCardWidget extends StatelessWidget {
  final Map<String, dynamic> props;

  const PlaceDiscoveryCardWidget({required this.props});

  @override
  Widget build(BuildContext context) {
    final score = (props['score'] as num?)?.toDouble() ?? 0.8;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          props['name'] ?? 'Unknown Place',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vibe: ${props['vibe_signature'] ?? ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(score * 100).toStringAsFixed(0)}% match',
                      style: TextStyle(fontSize: 12, color: Colors.green[900]),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                props['reason'] ?? 'Great place to visit',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Show on map or navigate
                  },
                  child: Text('View on map'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 3.4: SmartMapSurface Widget
**File:** `lib/genui/widgets/smart_map_surface_widget.dart`

```dart
import 'package:flutter/material.dart';

class SmartMapSurfaceWidget extends StatefulWidget {
  final Map<String, dynamic> props;

  const SmartMapSurfaceWidget({required this.props});

  @override
  _SmartMapSurfaceState createState() => _SmartMapSurfaceState();
}

class _SmartMapSurfaceState extends State<SmartMapSurfaceWidget> {
  @override
  Widget build(BuildContext context) {
    final places = widget.props['places'] as List? ?? [];

    return Container(
      height: 400,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Map placeholder (replace with actual flutter_map when ready)
          Container(
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Interactive Map: ${widget.props['city']}'),
                  SizedBox(height: 8),
                  Text('${places.length} places to explore'),
                  SizedBox(height: 16),
                  Text(
                    'Routes: ${widget.props['route_type']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          // Pin indicators
          if (places.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '📍 ${places.length} pins',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 🧪 STEP 4: Test End-to-End (30 min)

### Test Checklist:
- [ ] Phase5Home integrates without errors
- [ ] LLMReasoningEngine logs show all steps
- [ ] GenUiOrchestrationLayer validates components
- [ ] GenUiSurfaceRenderer displays correctly
- [ ] RouteItinerary shows days
- [ ] DayClusterCards display with stats
- [ ] PlaceDiscoveryCards show recommendations
- [ ] SmartMapSurface renders
- [ ] All components properly formatted
- [ ] No null/undefined data displayed

### Run:
```bash
flutter run -d <device-id>

# Watch logs:
flutter logs --grep "GenUi\|LLMReasoning\|DiscoveryOrch"
```

---

## 📝 Expected Output When Running

```
✅ GenUI ORCHESTRATION LAYER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Processing LLM result for Paris

🔧 STEP 1: EXTRACTING COMPONENTS FROM LLM OUTPUT
✅ Added RouteItinerary component

📅 STEP 2: GENERATING DAY CLUSTER COMPONENTS
✅ Added DayClusterCard for Day 1
✅ Added DayClusterCard for Day 2
✅ Added DayClusterCard for Day 3

🗺️  STEP 3: GENERATING MAP COMPONENT
✅ Added SmartMapSurface component

🎯 STEP 4: GENERATING PLACE DISCOVERY CARDS
✅ Added 8 PlaceDiscoveryCard components

✔️ STEP 5: VALIDATING COMPONENT SCHEMAS
✅ RouteItinerary: Valid
✅ DayClusterCard: Valid
✅ SmartMapSurface: Valid
✅ PlaceDiscoveryCard: Valid (x8)

✨ Surface update ready with 13 components
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🎯 Success Criteria

When STEP 4 completes successfully:
- ✅ Full reasoning logs visible
- ✅ GenUI components generated
- ✅ All widgets render without errors
- ✅ Data flows correctly through pipeline
- ✅ UI is interactive (can scroll, tap)
- ✅ Maps and cards display properly
- ✅ Day clusters make geographic sense

---

## 🚨 Troubleshooting

### "Cannot find llm_reasoning_engine"
→ Check import: `import 'services/llm_reasoning_engine.dart';`

### "GenUiSurfaceUpdate null"
→ Check GenUiOrchestrationLayer is returning valid result

### "Component validation failed"
→ Check component.props matches schema in genui_component_catalog.dart

### "Widget not building"
→ Add null checks in widget build methods

---

## 📚 Reference Files

- **PHASE5_NEXT_STEPS.md** - Detailed architecture
- **IMPLEMENTATION_STATUS.md** - Full system overview
- **lib/services/llm_reasoning_engine.dart** - Reasoning logic
- **lib/services/genui_component_catalog.dart** - Component definitions

---

**Estimated Time:** 3.5 hours to completion  
**Next Phase:** Phase 5C (Polish & Testing)  
**Final Phase:** Phase 5D (Real LLM Integration)
