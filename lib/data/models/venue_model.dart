class VenueLocation {
  final String id;
  final String name;
  final String? address;
  final String? floor;
  final Map<String, dynamic>? mapCoordinates;
  final int? capacity;
  final String? description;
  final DateTime createdAt;

  VenueLocation({
    required this.id,
    required this.name,
    this.address,
    this.floor,
    this.mapCoordinates,
    this.capacity,
    this.description,
    required this.createdAt,
  });

  factory VenueLocation.fromJson(Map<String, dynamic> json) {
    return VenueLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      floor: json['floor'] as String?,
      mapCoordinates: json['map_coordinates'] as Map<String, dynamic>?,
      capacity: json['capacity'] as int?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'floor': floor,
      'map_coordinates': mapCoordinates,
      'capacity': capacity,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
