class Banner {
  final String id;
  final String title;
  final String imageUrl;
  final String linkUrl;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;

  Banner({
    required this.id,
    this.title = '',
    required this.imageUrl,
    this.linkUrl = '',
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
  });

  factory Banner.fromSupabaseJson(Map<String, dynamic> json) => Banner(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        imageUrl: json['image_url'] as String,
        linkUrl: json['link_url'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
        displayOrder: json['display_order'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}
