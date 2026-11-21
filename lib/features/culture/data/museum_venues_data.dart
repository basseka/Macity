class MuseumVenue {
  final String id;
  final String name;
  final String description;
  final String category;
  final String city;
  final String horaires;
  final String? ticketUrl;
  final String websiteUrl;
  final bool hasOnlineTicket;
  final String image;
  final bool isVerified;
  /// Galerie et vidéo de la fiche (colonnes `photos` et `video_url`).
  final List<String> photos;
  final String videoUrl;
  final String adresse;
  final String lienMaps;
  final double latitude;
  final double longitude;

  const MuseumVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.city,
    required this.horaires,
    this.ticketUrl,
    required this.websiteUrl,
    required this.hasOnlineTicket,
    required this.image,
    this.isVerified = false,
    this.photos = const [],
    this.videoUrl = '',
    this.adresse = '',
    this.lienMaps = '',
    this.latitude = 0,
    this.longitude = 0,
  });
}
