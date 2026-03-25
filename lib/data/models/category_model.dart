class Category {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconUrl: json['icon_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon_url': iconUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
