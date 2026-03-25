class EventSchedule {
  final String id;
  final String eventId;
  final String? title;
  final DateTime startTime;
  final DateTime? endTime;
  final String? locationDetail;
  final String? speaker;

  EventSchedule({
    required this.id,
    required this.eventId,
    this.title,
    required this.startTime,
    this.endTime,
    this.locationDetail,
    this.speaker,
  });

  factory EventSchedule.fromJson(Map<String, dynamic> json) {
    return EventSchedule(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      title: json['title'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      locationDetail: json['location_detail'] as String?,
      speaker: json['speaker'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'location_detail': locationDetail,
      'speaker': speaker,
    };
  }
}
