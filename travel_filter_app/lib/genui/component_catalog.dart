import 'package:flutter/material.dart';

/// Defines all widgets the LLM can generate via A2UI protocol
class ComponentCatalog {
  static const Map<String, dynamic> schema = {
    'PlaceDiscoveryCard': {
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'description': 'Place name'},
        'vibe': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Vibe tags (e.g., historic, local, quiet)'
        },
        'distance': {'type': 'number', 'description': 'Distance in km'},
        'imageUrl': {'type': 'string', 'description': 'Place image URL'},
        'description': {'type': 'string', 'description': 'Short description'},
        'rating': {'type': 'number', 'description': 'Rating 0-5'},
        'osmId': {'type': 'string', 'description': 'OSM ID for reference'}
      },
      'required': ['name', 'vibe', 'osmId']
    },
    'SmartMapSurface': {
      'type': 'object',
      'properties': {
        'places': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'lat': {'type': 'number'},
              'lon': {'type': 'number'},
              'vibe': {'type': 'array', 'items': {'type': 'string'}}
            }
          }
        },
        'vibeFilter': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Filter places by these vibe tags'
        },
        'centerLat': {'type': 'number'},
        'centerLon': {'type': 'number'},
        'zoomLevel': {'type': 'number', 'default': 13}
      },
      'required': ['places']
    },
    'RouteItinerary': {
      'type': 'object',
      'properties': {
        'days': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'dayNumber': {'type': 'integer'},
              'theme': {'type': 'string', 'description': 'Daily theme'},
              'places': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'name': {'type': 'string'},
                    'order': {'type': 'integer'},
                    'vibe': {'type': 'array', 'items': {'type': 'string'}},
                    'reason': {
                      'type': 'string',
                      'description': 'Why LLM chose this place'
                    }
                  }
                }
              },
              'totalDistance': {'type': 'number', 'description': 'km'}
            }
          }
        },
        'tripSummary': {'type': 'string', 'description': 'Overall trip narrative'}
      },
      'required': ['days']
    },
    'VibeSelector': {
      'type': 'object',
      'properties': {
        'selectedVibes': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'User-selected vibe preferences'
        },
        'availableVibes': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'All available vibe options'
        }
      },
      'required': ['selectedVibes', 'availableVibes']
    }
  };

  static const List<String> availableComponents = [
    'PlaceDiscoveryCard',
    'SmartMapSurface',
    'RouteItinerary',
    'VibeSelector'
  ];

  static const List<String> commonVibes = [
    'historic',
    'local',
    'quiet',
    'vibrant',
    'nature',
    'urban',
    'cultural',
    'hidden_gem',
    'family_friendly',
    'budget',
    'luxury',
    'instagram_worthy',
    'off_the_beaten_path',
    'street_art',
    'cafe_culture',
    'nightlife',
    'adventure',
    'relaxation',
    'educational',
    'spiritual'
  ];
}

/// Widget implementations for the component catalog

class PlaceDiscoveryCard extends StatelessWidget {
  final String name;
  final List<String> vibes;
  final double? distance;
  final String? imageUrl;
  final String? description;
  final double? rating;
  final String osmId;
  final VoidCallback? onTap;

  const PlaceDiscoveryCard({
    required this.name,
    required this.vibes,
    required this.osmId,
    this.distance,
    this.imageUrl,
    this.description,
    this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rating != null)
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        SizedBox(width: 4),
                        Text('${rating!.toStringAsFixed(1)}'),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: vibes
                    .map((vibe) => Chip(
                          label: Text(vibe),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
              if (description != null) ...[
                SizedBox(height: 8),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (distance != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '${distance!.toStringAsFixed(1)} km away',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RouteItinerary extends StatelessWidget {
  final List<DayCluster> days;
  final String? tripSummary;

  const RouteItinerary({
    required this.days,
    this.tripSummary,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tripSummary != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                tripSummary!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ...days.map((day) => _DayClusterCard(day: day)),
        ],
      ),
    );
  }
}

class _DayClusterCard extends StatelessWidget {
  final DayCluster day;

  const _DayClusterCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day ${day.dayNumber}: ${day.theme}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12),
            ...day.places.asMap().entries.map((entry) {
              final place = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      child: Center(
                        child: Text(
                          '${place.order}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (place.reason != null)
                            Text(
                              place.reason!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Wrap(
                            spacing: 4,
                            children: place.vibes
                                .map((v) => Text(
                                      v,
                                      style: TextStyle(fontSize: 10),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (day.totalDistance != null)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Total distance: ${day.totalDistance!.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DayCluster {
  final int dayNumber;
  final String theme;
  final List<ItineraryPlace> places;
  final double? totalDistance;

  DayCluster({
    required this.dayNumber,
    required this.theme,
    required this.places,
    this.totalDistance,
  });

  factory DayCluster.fromJson(Map<String, dynamic> json) {
    return DayCluster(
      dayNumber: json['dayNumber'] ?? 1,
      theme: json['theme'] ?? 'Exploration',
      places: (json['places'] as List<dynamic>? ?? [])
          .map((p) => ItineraryPlace.fromJson(p))
          .toList(),
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
    );
  }
}

class ItineraryPlace {
  final String name;
  final int order;
  final List<String> vibes;
  final String? reason;

  ItineraryPlace({
    required this.name,
    required this.order,
    required this.vibes,
    this.reason,
  });

  factory ItineraryPlace.fromJson(Map<String, dynamic> json) {
    return ItineraryPlace(
      name: json['name'] ?? 'Unknown',
      order: json['order'] ?? 0,
      vibes: (json['vibe'] as List<dynamic>? ?? []).cast<String>(),
      reason: json['reason'],
    );
  }
}

class VibeSelector extends StatefulWidget {
  final List<String> selectedVibes;
  final List<String> availableVibes;
  final ValueChanged<List<String>> onVibesChanged;

  const VibeSelector({
    required this.selectedVibes,
    required this.availableVibes,
    required this.onVibesChanged,
  });

  @override
  State<VibeSelector> createState() => _VibeSelectorState();
}

class _VibeSelectorState extends State<VibeSelector> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedVibes);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your vibe?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.availableVibes.map((vibe) {
              final isSelected = _selected.contains(vibe);
              return FilterChip(
                label: Text(vibe),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selected.add(vibe);
                    } else {
                      _selected.remove(vibe);
                    }
                  });
                  widget.onVibesChanged(_selected);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
