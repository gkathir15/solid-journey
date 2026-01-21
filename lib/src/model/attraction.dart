class Attraction {
  final String name;
  final String category;
  final String description;

  Attraction({
    required this.name,
    required this.category,
    required this.description,
  });

  factory Attraction.fromJson(Map<String, dynamic> json) {
    return Attraction(
      name: json['n'],
      category: json['c'],
      description: json['d'],
    );
  }
}
