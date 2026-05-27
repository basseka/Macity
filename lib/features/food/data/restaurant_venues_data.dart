class RestaurantVenue {
  final String id;
  final String name;
  final String description;
  final String group;
  final String theme;     // Asiatique, Orientale, etc.
  final String quartier;  // Capitole, Carmes, etc.
  final String style;     // Romantique, Chic, etc.
  final String adresse;
  final String horaires;
  final String telephone;
  final double latitude;
  final double longitude;
  final String websiteUrl;
  final String lienMaps;
  final String photo;
  final List<String> photos;
  final bool isVerified;

  const RestaurantVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.group,
    this.theme = '',
    this.quartier = '',
    this.style = '',
    required this.adresse,
    required this.horaires,
    required this.telephone,
    required this.latitude,
    required this.longitude,
    required this.websiteUrl,
    required this.lienMaps,
    this.photo = '',
    this.photos = const [],
    this.isVerified = false,
  });

  /// Matche un theme sur `theme` OU `group` (= `categorie` cote DB).
  /// Convention attendue : `theme` rempli. Mais des saisies admin mettent
  /// parfois la valeur dans `categorie` a la place (ex: Le Petit L'U cat=
  /// Guinguette, theme=Francais). On accepte les deux.
  bool matchesTheme(String t) {
    final needle = t.toLowerCase();
    return theme.toLowerCase() == needle || group.toLowerCase() == needle;
  }
}

class RestaurantVenuesData {
  RestaurantVenuesData._();

  static const groupOrder = [
    'Experiences uniques',
    'Ambiances insolites / thematiques',
    'Creativite culinaire',
    'Concepts originaux a proximite',
  ];

  static const themes = [
    'Tous',
    'Francais',
    'Asiatique',
    'Japonais',
    'Italien',
    'Orientale',
    'Mediterraneen',
    'Mexicain',
    'Africain',
    'Indien',
    'Fusion',
    'Sud-Ouest',
    'Fruits de mer',
    'Vegetarien',
    'West Indies',
    'Guinguette',
    'Buffet',
  ];

  static const quartiers = [
    'Tous',
    'Capitole',
    'Saint-Georges',
    'Esquirol',
    'Saint-Etienne',
    'Carmes',
    'Saint-Cyprien',
    'Compans-Caffarelli',
    'Francois-Verdier',
    'Matabiau',
    'Cote Pavee',
    'Lardenne',
    'Rangueil',
    'Minimes',
    'Empalot',
    'Bagatelle',
    'Mirail',
    'Saint-Michel',
    'Balma',
    'Ramonville',
    'Aucamville',
    'Blagnac',
    'Plaisance-du-Touch',
    'Portet-sur-Garonne',
  ];

  static const styles = [
    'Tous',
    'Romantique',
    'Chic',
    'Gastronomique',
    'Bistronomique',
    'Convivial',
    'Familial',
    'Festif',
    'Cosy',
    'Decontracte',
    'Traditionnel',
    'Authentique',
    'Moderne',
    'Branche',
    'Instagrammable',
    'Rooftop',
    'Nature / vegetal',
    'Industriel',
    'Vintage',
    'A theme',
    'Street food',
    'Lounge',
    'Tapas / partage',
    'Bar a vin',
    'Gourmet',
  ];
}
