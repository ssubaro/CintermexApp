class Announcement {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final bool active;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    required this.active,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      linkUrl: json['link_url'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
