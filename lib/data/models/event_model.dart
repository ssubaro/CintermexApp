class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String imageUrl;
  final String? category;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.imageUrl,
    this.category,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] ?? json['start_date'] as String),
      location: json['location'] as String,
      imageUrl: json['image_url'] as String,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'location': location,
      'image_url': imageUrl,
      'category': category,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
