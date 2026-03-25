class TicketType {
  final String id;
  final String eventId;
  final String name;
  final String? description;
  final double price;
  final int? capacity;
  final int soldCount;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final bool isActive;

  TicketType({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    required this.price,
    this.capacity,
    this.soldCount = 0,
    this.availableFrom,
    this.availableUntil,
    this.isActive = true,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] ?? 0.0).toDouble(),
      capacity: json['capacity'] as int?,
      soldCount: json['sold_count'] ?? 0,
      availableFrom: json['available_from'] != null
          ? DateTime.parse(json['available_from'] as String)
          : null,
      availableUntil: json['available_until'] != null
          ? DateTime.parse(json['available_until'] as String)
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'name': name,
      'description': description,
      'price': price,
      'capacity': capacity,
      'sold_count': soldCount,
      'available_from': availableFrom?.toIso8601String(),
      'available_until': availableUntil?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
