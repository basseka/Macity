class MonumentVenue {
  final String id;
  final String name;
  final String description;
  final String type;
  final String group;
  final String adresse;
  final double latitude;
  final double longitude;
  final String websiteUrl;
  final String lienMaps;
  final String image;
  final bool isVerified;

  const MonumentVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.group,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.websiteUrl,
    required this.lienMaps,
    required this.image,
    this.isVerified = false,
  });
}
