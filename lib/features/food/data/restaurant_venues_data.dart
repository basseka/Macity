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
  final int displayPriority;
  // Override de priorite par categorie (clé = nom catégorie food, ex
  // "Guinguette", valeur = entier). Si la clé est absente pour la categorie
  // affichée, on retombe sur [displayPriority]. Cf. migration
  // 20260527100000_etablissements_priorities.sql.
  final Map<String, int> priorities;

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
    this.displayPriority = 0,
    this.priorities = const {},
  });

  /// Matche un theme sur `theme` OU `group` (= `categorie` cote DB).
  /// Convention attendue : `theme` rempli. Mais des saisies admin mettent
  /// parfois la valeur dans `categorie` a la place (ex: Le Petit L'U cat=
  /// Guinguette, theme=Francais). On accepte les deux.
  bool matchesTheme(String t) {
    final needle = t.toLowerCase();
    return theme.toLowerCase() == needle || group.toLowerCase() == needle;
  }

  /// Priorite effective pour une categorie : on prend l'override
  /// [priorities] si une clé matche (case-insensitive), sinon [displayPriority].
  int priorityFor(String category) {
    final needle = category.toLowerCase();
    for (final entry in priorities.entries) {
      if (entry.key.toLowerCase() == needle) return entry.value;
    }
    return displayPriority;
  }
}

/// Trie une liste de restaurants par leur priorite EFFECTIVE pour [category]
/// (decroissante) puis alphabetique. Utiliser apres un filtre par catégorie
/// pour respecter les overrides definis par l'admin.
List<RestaurantVenue> sortRestaurantsForCategory(
  List<RestaurantVenue> list,
  String category,
) {
  final copy = [...list];
  copy.sort((a, b) {
    final cmp = b.priorityFor(category).compareTo(a.priorityFor(category));
    if (cmp != 0) return cmp;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return copy;
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
