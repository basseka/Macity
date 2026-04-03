class LibraryVenue {
  final String id;
  final String name;
  final String description;
  final String group;
  final String adresse;
  final String horaires;
  final String services;
  final String telephone;
  final double latitude;
  final double longitude;
  final String websiteUrl;
  final String lienMaps;
  final String image;
  final bool isVerified;

  const LibraryVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.group,
    required this.adresse,
    required this.horaires,
    required this.services,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.websiteUrl,
    required this.lienMaps,
    required this.image,
    this.isVerified = false,
  });
}
