class Order {
  final String id;
  final String userId;
  final String eventId;
  final String? scheduleId;
  final String? ticketTypeId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double serviceFee;
  final double total;
  final String currency;
  final String status;
  final DateTime? expiresAt;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.eventId,
    this.scheduleId,
    this.ticketTypeId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.serviceFee = 0.0,
    required this.total,
    this.currency = 'MXN',
    required this.status,
    this.expiresAt,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      scheduleId: json['schedule_id'] as String?,
      ticketTypeId: json['ticket_type_id'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      serviceFee: (json['service_fee'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'MXN',
      status: json['status'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'schedule_id': scheduleId,
      'ticket_type_id': ticketTypeId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'service_fee': serviceFee,
      'total': total,
      'currency': currency,
      'status': status,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
