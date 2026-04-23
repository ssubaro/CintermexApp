class Ticket {
  final String id;
  final String userId;
  final String eventId;
  final String status;
  final String? qrCodeData;
  final DateTime createdAt;
  final double? pricePaid;
  final int quantity;
  final String paymentStatus;
  final String? orderId;
  final String? ticketNumber;
  final String? qrCodeHash;
  final DateTime? usedAt;
  final String? usedBy;
  final String? source;
  final String? scheduleId;

  // Optional: Event details if joined
  final String? eventTitle;
  final DateTime? eventDate;
  final String? eventLocation;
  final DateTime? selectedDate;
  final String? ticketTypeName;

  Ticket({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    this.qrCodeData,
    required this.createdAt,
    this.pricePaid,
    this.quantity = 1,
    this.paymentStatus = 'completed',
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.selectedDate,
    this.orderId,
    this.ticketNumber,
    this.qrCodeHash,
    this.usedAt,
    this.usedBy,
    this.source,
    this.scheduleId,
    this.ticketTypeName,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      status: json['status'] as String,
      qrCodeData: json['qr_code_data'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      pricePaid:
          (json['price_paid'] != null) ? (json['price_paid']).toDouble() : null,
      quantity: json['quantity'] ?? 1,
      paymentStatus: json['payment_status'] ?? 'completed',
      orderId: json['order_id'] as String?,
      ticketNumber: json['ticket_number'] as String?,
      qrCodeHash: json['qr_code_hash'] as String?,
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      usedBy: json['used_by'] as String?,
      source: json['source'] as String?,
      scheduleId: json['schedule_id'] as String?,
      // Si hacemos join con eventos
      eventTitle:
          json['events'] != null ? json['events']['title'] as String : null,
      eventDate: json['events'] != null
          ? DateTime.parse(json['events']['start_date'] as String)
          : null,
      eventLocation:
          json['events'] != null ? json['events']['location'] as String : null,
      selectedDate: json['selected_date'] != null
          ? DateTime.parse(json['selected_date'] as String)
          : null,
      ticketTypeName: json['ticket_types'] != null
          ? json['ticket_types']['name'] as String
          : null,
    );
  }
}
