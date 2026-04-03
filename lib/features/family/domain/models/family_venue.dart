/// Modele unifie pour tous les lieux famille (cinema, bowling, escape game, etc.)
/// Mappe directement sur la table `family_venues` de Supabase.
class FamilyVenue {
  final int id;
  final String slug;
  final String name;
  final String category;
  final String groupe;
  final String description;
  final String adresse;
  final String ville;
  final String horaires;
  final String tarif;
  final String telephone;
  final double latitude;
  final double longitude;
  final String websiteUrl;
  final String ticketUrl;
  final String lienMaps;
  final String photo;
  final bool isVerified;

  const FamilyVenue({
    required this.id,
    required this.slug,
    required this.name,
    required this.category,
    this.groupe = '',
    this.description = '',
    this.adresse = '',
    this.ville = '',
    this.horaires = '',
    this.tarif = '',
    this.telephone = '',
    this.latitude = 0,
    this.longitude = 0,
    this.websiteUrl = '',
    this.ticketUrl = '',
    this.lienMaps = '',
    this.photo = '',
    this.isVerified = false,
  });

  factory FamilyVenue.fromJson(Map<String, dynamic> json) {
    return FamilyVenue(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      groupe: json['groupe'] as String? ?? '',
      description: json['description'] as String? ?? '',
      adresse: json['adresse'] as String? ?? '',
      ville: json['ville'] as String? ?? '',
      horaires: json['horaires'] as String? ?? '',
      tarif: json['tarif'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      websiteUrl: json['website_url'] as String? ?? '',
      ticketUrl: json['ticket_url'] as String? ?? '',
      lienMaps: json['lien_maps'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}
