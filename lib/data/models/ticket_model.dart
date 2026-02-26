class Ticket {
  final String id;
  final String userId;
  final String eventId;
  final String status;
  final String? qrCodeData;
  final DateTime createdAt;

  // Optional: Event details if joined
  final String? eventTitle;
  final DateTime? eventDate;
  final String? eventLocation;

  Ticket({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    this.qrCodeData,
    required this.createdAt,
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      status: json['status'] as String,
      qrCodeData: json['qr_code_data'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      // Si hacemos join con eventos
      eventTitle: json['events'] != null ? json['events']['title'] as String : null,
      eventDate: json['events'] != null ? DateTime.parse(json['events']['start_date'] as String) : null,
      eventLocation: json['events'] != null ? json['events']['location'] as String : null,
    );
  }
}
