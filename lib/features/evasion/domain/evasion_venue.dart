import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Lieu d'évasion (domaine, château, gîte de séjour) — table `evasion_venues`.
class EvasionVenue {
  final int id;
  final String nom;
  final String adresse;

  /// Commune du domaine (affichée sur la carte).
  final String ville;

  /// Ville de rattachement (hub) : la rubrique Évasion de cette ville affiche
  /// le domaine. Ex : Toulouse pour une escapade à Gaillac.
  final String hubVille;
  final double latitude;
  final double longitude;

  /// Temps de trajet depuis la ville de référence, en heures (1, 2 ou 3).
  /// Sert aux filtres « À 1h / À 2h / À 3h » (cumulatifs : À 2h inclut les 1h).
  final int travelTimeH;

  final String siteWeb;
  final String telephone;
  /// Teaser affiché sur la carte et en tête de la fiche détail.
  final String description;
  final String photo;

  /// Galerie de la fiche détail (comme Food). Vide → photos de repli génériques.
  final List<String> photos;
  final bool isPartner;
  final int displayPriority;

  const EvasionVenue({
    required this.id,
    required this.nom,
    this.adresse = '',
    this.ville = '',
    this.hubVille = 'Toulouse',
    this.latitude = 0,
    this.longitude = 0,
    this.travelTimeH = 3,
    this.siteWeb = '',
    this.telephone = '',
    this.description = '',
    this.photo = '',
    this.photos = const [],
    this.isPartner = false,
    this.displayPriority = 0,
  });

  factory EvasionVenue.fromJson(Map<String, dynamic> json) => EvasionVenue(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nom: json['nom'] as String? ?? '',
        adresse: json['adresse'] as String? ?? '',
        ville: json['ville'] as String? ?? '',
        hubVille: json['hub_ville'] as String? ?? 'Toulouse',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        photos: (json['photos'] is List)
            ? (json['photos'] as List)
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .toList()
            : const [],
        travelTimeH: (json['travel_time_h'] as num?)?.toInt() ?? 3,
        siteWeb: json['site_web'] as String? ?? '',
        telephone: json['telephone'] as String? ?? '',
        description: json['description'] as String? ?? '',
        photo: json['photo'] as String? ?? '',
        isPartner: json['is_partner'] as bool? ?? false,
        displayPriority: (json['display_priority'] as num?)?.toInt() ?? 0,
      );

  /// Pont vers le modèle générique consommé par la fiche détail.
  CommerceModel toCommerce() => CommerceModel(
        nom: nom,
        adresse: adresse,
        ville: ville,
        latitude: latitude,
        longitude: longitude,
        categorie: 'Évasion',
        siteWeb: siteWeb,
        telephone: telephone,
        description: description,
        photo: photo,
        photos: photos,
        isPartner: isPartner,
      );
}
