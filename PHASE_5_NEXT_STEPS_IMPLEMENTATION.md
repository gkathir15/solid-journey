# Phase 5: Next Steps - Detailed Implementation Guide

**Priority Order**: Build GenUI → Real LLM → Interactive Loop

---

## 🎯 STEP 1: Implement SmartMapSurface Component

**Objective**: Create an interactive map widget that displays OSM places with vibe-based filtering.

### 1.1 Create the Widget File

```bash
touch lib/genui/components/smart_map_surface.dart
```

### 1.2 Implementation Requirements

```dart
class SmartMapSurface extends StatefulWidget {
  // Input: List of places with coordinates
  final List<Map<String, dynamic>> places;
  
  // Input: City center coordinates
  final double centerLat;
  final double centerLon;
  
  // Input: Vibe filters to apply
  final List<String> activeVibes;
  
  // Output: Callback when place selected
  final Function(Map<String, dynamic>) onPlaceSelected;
  
  // Features needed:
  // 1. Render flutter_map with OpenStreetMap tiles
  // 2. Add markers for each place
  // 3. Color markers by vibe type (heritage=blue, local=green, etc)
  // 4. Support tap to show place details
  // 5. Support vibe-based filtering (show/hide based on signature)
  // 6. Show route lines between places in a cluster
  // 7. Cache tiles offline using flutter_map_tile_caching
}
```

### 1.3 Key Logic

```dart
// Filter places based on active vibes
List<Map<String, dynamic>> _filterPlacesByVibe() {
  return places.where((place) {
    final signature = place['vibeSignature'] as String;
    for (final vibe in activeVibes) {
      if (signature.contains(vibe)) return true;
    }
    return false;
  }).toList();
}

// Determine marker color based on primary vibe
Color _getMarkerColor(String vibeSignature) {
  if (vibeSignature.contains('historic')) return Colors.blue;
  if (vibeSignature.contains('local')) return Colors.green;
  if (vibeSignature.contains('culture')) return Colors.purple;
  return Colors.grey;
}

// Build map with cached tiles
FlutterMap _buildMap() {
  return FlutterMap(
    options: MapOptions(center: LatLng(centerLat, centerLon), zoom: 13),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.travel_filter_app',
        // Add caching with flutter_map_tile_caching
      ),
      MarkerLayer(markers: _buildMarkers()),
      PolylineLayer(polylines: _buildRouteLines()),
    ],
  );
}

// Build markers for each place
List<Marker> _buildMarkers() {
  return filteredPlaces.map((place) {
    return Marker(
      point: LatLng(place['lat'], place['lon']),
      builder: (context) => _buildMarkerWidget(place),
      onTap: () => onPlaceSelected(place),
    );
  }).toList();
}
```

### 1.4 Integration Steps

1. Add dependencies to `pubspec.yaml`:
   ```yaml
   flutter_map: ^6.0.0
   flutter_map_tile_caching: ^10.0.0
   latlong2: ^0.9.0
   ```

2. Implement caching configuration:
   ```dart
   FlutterMapTileCachingPlugin.initialise(
     cacheDirPath: tempDir.path,
     throttle: Duration(milliseconds: 200),
   );
   ```

3. Connect to DiscoveryOrchestrator output:
   ```dart
   final result = await orchestrator.orchestrate(...);
   SmartMapSurface(
     places: result.allPlaces,
     centerLat: parisLat,
     centerLon: parisLon,
     activeVibes: userVibes,
   );
   ```

---

## 🎯 STEP 2: Implement RouteItinerary Component

**Objective**: Create a vertical timeline showing daily itineraries.

### 2.1 Create the Widget File

```bash
touch lib/genui/components/route_itinerary.dart
```

### 2.2 Implementation Requirements

```dart
class RouteItinerary extends StatefulWidget {
  // Input: Day clusters from LLM
  final List<Map<String, dynamic>> dayClusters;
  
  // Input: Selected places to highlight
  final List<String>? selectedPlaceIds;
  
  // Output: Callback when day selected
  final Function(int dayNumber)? onDaySelected;
  
  // Features:
  // 1. Vertical timeline layout
  // 2. Each day shows: day#, theme, places count, distance
  // 3. Expandable/collapsible for each day
  // 4. Show estimated time and route
  // 5. Visual separation between days
  // 6. Swipe to navigate between days
}
```

### 2.3 Key Logic

```dart
// Build timeline
ListView _buildTimeline() {
  return ListView.builder(
    itemCount: dayClusters.length,
    itemBuilder: (context, index) {
      final cluster = dayClusters[index];
      return _buildDayCard(cluster, index);
    },
  );
}

// Build individual day card
Card _buildDayCard(Map<String, dynamic> cluster, int index) {
  return Card(
    child: Column(
      children: [
        // Day header: "Day 1: Heritage Deep Dive"
        Text('Day ${cluster['day']}: ${cluster['theme']}'),
        
        // Metrics: "8 places, 5.2 km, Best time: Morning 9am"
        Row(
          children: [
            Text('${cluster['places'].length} places'),
            Text('${cluster['estimatedDistance']} km'),
            Text('${cluster['bestTime']}'),
          ],
        ),
        
        // Expandable place list
        if (_expandedDays.contains(index))
          ListView.builder(
            itemCount: cluster['places'].length,
            itemBuilder: (ctx, i) => _buildPlaceListTile(
              cluster['places'][i],
              i + 1,
            ),
          ),
      ],
    ),
    onTap: () => setState(() {
      if (_expandedDays.contains(index)) {
        _expandedDays.remove(index);
      } else {
        _expandedDays.add(index);
      }
    }),
  );
}

// Build individual place in list
ListTile _buildPlaceListTile(
  Map<String, dynamic> place,
  int order,
) {
  return ListTile(
    leading: Text('$order.'),
    title: Text(place['name']),
    subtitle: Text(place['vibeSignature']),
    trailing: Icon(_getVibeIcon(place['vibeSignature'])),
  );
}
```

### 2.4 Integration Steps

1. Connect to LLMReasoningEngine output:
   ```dart
   final planResult = await llmEngine.planTrip(...);
   RouteItinerary(
     dayClusters: planResult.dayClusters,
     onDaySelected: (day) => _scrollMapToDay(day),
   );
   ```

2. Synchronize with SmartMapSurface:
   ```dart
   // When day selected in itinerary, pan map to day's places
   void _scrollMapToDay(int dayNumber) {
     final dayCluster = dayClusters[dayNumber - 1];
     _mapController.move(
       LatLng(dayCluster['centerLat'], dayCluster['centerLon']),
       14,
     );
   }
   ```

---

## 🎯 STEP 3: Implement DayClusterCard Component

**Objective**: Create compact card representation of a single day.

### 3.1 Create the Widget File

```bash
touch lib/genui/components/day_cluster_card.dart
```

### 3.2 Implementation Requirements

```dart
class DayClusterCard extends StatelessWidget {
  final int dayNumber;
  final String theme;
  final List<Map<String, dynamic>> places;
  final double estimatedDistance;
  final String bestTime;
  
  // Features:
  // 1. Compact visual card layout
  // 2. Theme with icon representation
  // 3. Quick stats: places, distance, time
  // 4. 3-4 place previews as horizontal scroll
  // 5. "Add to favorites" and "Learn more" buttons
  // 6. Visual theme colors based on day theme
}
```

### 3.3 Key Logic

```dart
// Build card
Card _buildCard() {
  return Card(
    color: _getThemeColor(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Day $dayNumber', style: TextStyle(fontSize: 14, opacity: 0.7)),
              Text(theme, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                children: [
                  Chip(label: Text('${places.length} places')),
                  Chip(label: Text('${estimatedDistance.toStringAsFixed(1)} km')),
                  Chip(label: Text(bestTime)),
                ],
              ),
            ],
          ),
        ),
        
        // Place previews (horizontal scroll)
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: places.take(4).length,
            itemBuilder: (ctx, i) => _buildPlacePreview(places[i]),
          ),
        ),
        
        // Action buttons
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _addToFavorites(),
              child: Text('Add to Trip'),
            ),
            ElevatedButton(
              onPressed: () => _learnMore(),
              child: Text('Learn More'),
            ),
          ],
        ),
      ],
    ),
  );
}

Color _getThemeColor() {
  // Map theme to color
  switch (theme) {
    case 'Heritage Deep Dive':
      return Colors.blue[50]!;
    case 'Local Discoveries':
      return Colors.green[50]!;
    case 'Cultural Immersion':
      return Colors.purple[50]!;
    default:
      return Colors.grey[50]!;
  }
}
```

---

## 🎯 STEP 4: Implement GenUI Surface Container

**Objective**: Create the main canvas widget that orchestrates all components.

### 4.1 Create the Widget File

```bash
touch lib/genui/genui_surface_widget.dart
```

### 4.2 Implementation Structure

```dart
class GenUiSurface extends StatefulWidget {
  final LLMPlanningResult planningResult;
  final Function(Map<String, dynamic>) onPlaceSelected;
  
  @override
  State<GenUiSurface> createState() => _GenUiSurfaceState();
}

class _GenUiSurfaceState extends State<GenUiSurface> {
  late PageController _pageController;
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          // Page 1: Map
          SmartMapSurface(
            places: widget.planningResult.discoveredPlaces.allPlaces,
            centerLat: 48.8566,  // Paris
            centerLon: 2.3522,
            activeVibes: widget.planningResult.userVibes,
            onPlaceSelected: widget.onPlaceSelected,
          ),
          
          // Page 2: Itinerary
          RouteItinerary(
            dayClusters: widget.planningResult.dayClusters,
            onDaySelected: _onDaySelected,
          ),
          
          // Page 3: Day Details
          _buildDayDetailsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Itinerary'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Details'),
        ],
        onTap: (index) => _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      ),
    );
  }
  
  void _onDaySelected(int dayNumber) {
    _pageController.animateToPage(2, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    // Show details for selected day
  }
}
```

---

## 🎯 STEP 5: Integrate All Components into Phase5Home

**Objective**: Connect LLMReasoningEngine → Components → UI rendering.

### 5.1 Update Phase5Home Integration

```dart
class _Phase5HomeState extends State<Phase5Home> {
  LLMPlanningResult? _planningResult;
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    if (_planningResult == null) {
      return _buildSelectionScreen();
    }
    
    return GenUiSurface(
      planningResult: _planningResult!,
      onPlaceSelected: _onPlaceSelected,
    );
  }
  
  void _startPlanning() async {
    setState(() => _isLoading = true);
    
    try {
      // Get selections from UI
      final country = _selectedCountry;
      final city = _selectedCity;
      final vibes = _selectedVibes;
      final duration = _selectedDuration;
      
      // Orchestrate discovery
      final discoveryResult = await discoveryOrchestrator.orchestrate(
        city: city,
        country: country,
        userVibes: vibes,
        context: 'Trip planning',
      );
      
      // Run LLM reasoning
      final planResult = await llmReasoningEngine.planTrip(
        country: country,
        city: city,
        userVibes: vibes,
        durationDays: duration,
      );
      
      setState(() {
        _planningResult = planResult;
        _isLoading = false;
      });
    } catch (e) {
      _log.severe('Planning failed: $e');
      setState(() => _isLoading = false);
      // Show error to user
    }
  }
  
  void _onPlaceSelected(Map<String, dynamic> place) {
    // Show place details in bottom sheet
    showModalBottomSheet(
      context: context,
      builder: (ctx) => PlaceDetailsSheet(place: place),
    );
  }
}
```

---

## 🧪 Testing Checklist

- [ ] SmartMapSurface renders without errors
- [ ] Places appear as markers on map
- [ ] Markers color-coded by vibe
- [ ] Tap marker shows place info
- [ ] Vibe filters work (show/hide places)
- [ ] Offline caching works
- [ ] RouteItinerary displays all days
- [ ] Days are expandable/collapsible
- [ ] DayClusterCards show correct theme colors
- [ ] GenUiSurface pages swipe correctly
- [ ] Bottom nav switches between pages
- [ ] Full integration with LLM output works end-to-end

---

## 📊 Implementation Effort Estimate

| Component | Effort | Timeline |
|-----------|--------|----------|
| SmartMapSurface | 4 hours | Day 1 |
| RouteItinerary | 2 hours | Day 1 |
| DayClusterCard | 1 hour | Day 1 |
| GenUiSurface | 2 hours | Day 2 |
| Integration/Testing | 3 hours | Day 2 |
| **Total** | **12 hours** | **2 days** |

---

## 🚀 After GenUI Components

Once these components are complete, proceed to:

1. **Real LLM Integration**: Replace mock reasoning with actual Gemini Nano
2. **Tool Calling**: Implement tool definitions for LLM
3. **Advanced Clustering**: Add real distance matrices and route optimization
4. **A2UI Loop**: Make UI interactive with bidirectional communication

---

**Created**: 2026-01-22  
**Next**: Start with SmartMapSurface implementation
