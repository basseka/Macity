class DanceVenue {
  final String id;
  final String name;
  final String description;
  final String category;
  final String group;
  final String city;
  final String horaires;
  final String? websiteUrl;
  final String image;
  final bool isVerified;

  const DanceVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.group,
    required this.city,
    required this.horaires,
    this.websiteUrl,
    required this.image,
    this.isVerified = false,
  });
}
