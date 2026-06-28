class FamilySubcategory {
  final String label;
  final String searchTag;
  final String emoji;
  final String group;
  final String? image;

  const FamilySubcategory({
    required this.label,
    required this.searchTag,
    required this.emoji,
    required this.group,
    this.image,
  });
}

class FamilyCategoryGroup {
  final String name;
  final String emoji;
  final List<FamilySubcategory> subcategories;

  const FamilyCategoryGroup({
    required this.name,
    required this.emoji,
    required this.subcategories,
  });
}

class FamilyCategoryData {
  FamilyCategoryData._();

  // Refonte taxonomie Famille : 6 rubriques (= chips de la landing) + leurs
  // types. `label` = affichage (accents), `searchTag` = valeur stockee dans
  // family_venues.category (sans accent, convention existante). Note :
  // "Aquarium" est volontairement present dans "Animaux et Nature" ET
  // "Activite Aquatique".
  static const groups = [
    FamilyCategoryGroup(
      name: 'A venir',
      emoji: '📅',
      subcategories: [
        FamilySubcategory(label: 'Calendrier', searchTag: 'A venir', emoji: '📅', group: 'A venir', image: 'assets/images/pochette_default.jpg'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Divertissements',
      emoji: '🎢',
      subcategories: [
        FamilySubcategory(label: 'Parc d\'attractions', searchTag: 'Parc d\'attractions', emoji: '🎢', group: 'Divertissements', image: 'assets/images/pochette_parc_attraction.webp'),
        FamilySubcategory(label: 'Laser game', searchTag: 'Laser game', emoji: '🔫', group: 'Divertissements', image: 'assets/images/pochette_gaming.jpg'),
        FamilySubcategory(label: 'Escape game', searchTag: 'Escape game', emoji: '🔐', group: 'Divertissements', image: 'assets/images/pochette_gaming.jpg'),
        FamilySubcategory(label: 'Bowling', searchTag: 'Bowling', emoji: '🎳', group: 'Divertissements', image: 'assets/images/pochette_enfamille.jpg'),
        FamilySubcategory(label: 'Cinema', searchTag: 'Cinema', emoji: '🎬', group: 'Divertissements', image: 'assets/images/pochette_spectacle.webp'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Jeux d\'enfants',
      emoji: '🧒',
      subcategories: [
        FamilySubcategory(label: 'Aire de jeux', searchTag: 'Aire de jeux', emoji: '🧒', group: 'Jeux d\'enfants', image: 'assets/images/pochette_enfamille.jpg'),
        FamilySubcategory(label: 'Parc de loisirs', searchTag: 'Parc de loisirs', emoji: '🎠', group: 'Jeux d\'enfants', image: 'assets/images/pochette_enfamille.jpg'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Animaux et Nature',
      emoji: '🦁',
      subcategories: [
        FamilySubcategory(label: 'Parc animalier', searchTag: 'Parc animalier', emoji: '🦁', group: 'Animaux et Nature', image: 'assets/images/pochette_parc_animalier.webp'),
        FamilySubcategory(label: 'Ferme pedagogique', searchTag: 'Ferme pedagogique', emoji: '🐄', group: 'Animaux et Nature', image: 'assets/images/pochette_enfamille.jpg'),
        FamilySubcategory(label: 'Aquarium', searchTag: 'Aquarium', emoji: '🐠', group: 'Animaux et Nature', image: 'assets/images/pochette_parc_animalier.webp'),
        FamilySubcategory(label: 'Zoo', searchTag: 'Zoo', emoji: '🦍', group: 'Animaux et Nature', image: 'assets/images/pochette_parc_animalier.webp'),
        FamilySubcategory(label: 'Jardin botanique', searchTag: 'Jardin botanique', emoji: '🌿', group: 'Animaux et Nature', image: 'assets/images/pochette_parc_animalier.webp'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Activite Aquatique',
      emoji: '🏊',
      subcategories: [
        FamilySubcategory(label: 'Aquarium', searchTag: 'Aquarium', emoji: '🐠', group: 'Activite Aquatique', image: 'assets/images/pochette_parc_animalier.webp'),
        FamilySubcategory(label: 'Centre aquatique', searchTag: 'Centre aquatique', emoji: '🏊', group: 'Activite Aquatique', image: 'assets/images/pochette_enfamille.jpg'),
        FamilySubcategory(label: 'Piscine', searchTag: 'Piscine', emoji: '🌊', group: 'Activite Aquatique', image: 'assets/images/pochette_enfamille.jpg'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Sortie en Plein Air',
      emoji: '🌳',
      subcategories: [
        FamilySubcategory(label: 'Parcs', searchTag: 'Parcs', emoji: '🌳', group: 'Sortie en Plein Air', image: 'assets/images/pochette_enfamille.jpg'),
        FamilySubcategory(label: 'Balades familiales', searchTag: 'Balade familiale', emoji: '🚶', group: 'Sortie en Plein Air', image: 'assets/images/pochette_enfamille.jpg'),
        FamilySubcategory(label: 'Accrobranche', searchTag: 'Accrobranche', emoji: '🧗', group: 'Sortie en Plein Air', image: 'assets/images/pochette_enfamille.jpg'),
        FamilySubcategory(label: 'Mini golf', searchTag: 'Mini golf', emoji: '⛳', group: 'Sortie en Plein Air', image: 'assets/images/pochette_enfamille.jpg'),
        FamilySubcategory(label: 'Base de loisirs', searchTag: 'Base de loisirs', emoji: '🏖️', group: 'Sortie en Plein Air', image: 'assets/images/pochette_enfamille.jpg'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Decouvrir',
      emoji: '🔭',
      subcategories: [
        FamilySubcategory(label: 'Musee pour enfants', searchTag: 'Musee pour enfants', emoji: '🏛️', group: 'Decouvrir', image: 'assets/images/pochette_spectacle.webp'),
        FamilySubcategory(label: 'Planetarium', searchTag: 'Planetarium', emoji: '🪐', group: 'Decouvrir', image: 'assets/images/pochette_spectacle.webp'),
        FamilySubcategory(label: 'Atelier creatif', searchTag: 'Atelier creatif', emoji: '🎨', group: 'Decouvrir', image: 'assets/images/pochette_enfamille.jpg'),
      ],
    ),
  ];

  static List<FamilySubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();

  /// Les 6 rubriques affichees comme chips dans la landing (exclut "A venir",
  /// qui est le calendrier d'evenements, pas une rubrique de lieux).
  static List<FamilyCategoryGroup> get browsableGroups =>
      groups.where((g) => g.name != 'A venir').toList();

  /// searchTags (= family_venues.category) de tous les types d'une rubrique.
  /// Dedoublonne (ex: Aquarium present dans 2 rubriques).
  static List<String> typeTagsForGroup(String groupName) {
    final g = groups.where((g) => g.name == groupName);
    if (g.isEmpty) return const [];
    final seen = <String>{};
    final tags = <String>[];
    for (final s in g.first.subcategories) {
      if (seen.add(s.searchTag)) tags.add(s.searchTag);
    }
    return tags;
  }
}
