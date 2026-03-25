import 'venue_model.dart';
import 'schedule_model.dart';
import 'category_model.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String imageUrl;
  final String? category;
  final String? categoryId;
  final double price;
  final int capacity;
  final String? venueLocationId;
  final String? organizerName;
  final String? organizerContact;
  final bool isFree;
  final bool requiresTicket;
  final String status;
  final bool isFeatured;
  final String? externalTicketUrl;

  // Virtual fields / Joins
  final VenueLocation? venue;
  final List<EventSchedule>? schedules;
  final List<Category>? categoriesList;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.imageUrl,
    this.category,
    this.categoryId,
    this.price = 0.0,
    this.capacity = 0,
    this.venueLocationId,
    this.organizerName,
    this.organizerContact,
    this.isFree = false,
    this.requiresTicket = true,
    this.status = 'active',
    this.isFeatured = false,
    this.externalTicketUrl,
    this.venue,
    this.schedules,
    this.categoriesList,
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
      categoryId: json['category_id'] as String?,
      price: (json['price'] ?? 0.0).toDouble(),
      capacity: json['capacity'] ?? 0,
      venueLocationId: json['venue_location_id'] as String?,
      organizerName: json['organizer_name'] as String?,
      organizerContact: json['organizer_contact'] as String?,
      isFree: json['is_free'] ?? false,
      requiresTicket: json['requires_ticket'] ?? true,
      status: json['status'] ?? 'active',
      isFeatured: json['is_featured'] ?? false,
      externalTicketUrl: json['external_ticket_url'] as String?,
      venue: json['venue_locations'] != null
          ? VenueLocation.fromJson(json['venue_locations'])
          : null,
      schedules: json['event_schedules'] != null
          ? (json['event_schedules'] as List)
              .map((i) => EventSchedule.fromJson(i))
              .toList()
          : null,
      categoriesList: json['event_categories'] != null
          ? (json['event_categories'] as List)
              .map((i) => Category.fromJson(i['categories']))
              .toList()
          : null,
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
      'category_id': categoryId,
      'price': price,
      'capacity': capacity,
    };
  }

  List<DateTime> getDaysList() {
    List<DateTime> days = [];
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    DateTime end = DateTime(endDate.year, endDate.month, endDate.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
