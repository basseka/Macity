class CultureSubcategory {
  final String label;
  final String searchTag;
  final String emoji;
  final String group;
  final String? image;

  const CultureSubcategory({
    required this.label,
    required this.searchTag,
    required this.emoji,
    required this.group,
    this.image,
  });
}

class CultureCategoryGroup {
  final String name;
  final String emoji;
  final List<CultureSubcategory> subcategories;

  const CultureCategoryGroup({
    required this.name,
    required this.emoji,
    required this.subcategories,
  });
}

class CultureCategoryData {
  CultureCategoryData._();

  static const groups = [
    CultureCategoryGroup(
      name: 'A venir',
      emoji: '📅',
      subcategories: [
        CultureSubcategory(label: 'Agenda', searchTag: 'A venir', emoji: '📅', group: 'A venir', image: 'assets/images/pochette_cettesemaine.jpg'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Cinema',
      emoji: '🎬',
      subcategories: [
        CultureSubcategory(label: 'Cinema', searchTag: 'Cinema', emoji: '🎬', group: 'Cinema', image: 'assets/images/pochette_cinema.webp'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Arts vivants',
      emoji: '🎭',
      subcategories: [
        CultureSubcategory(label: 'Theatre', searchTag: 'Theatre', emoji: '🎭', group: 'Arts vivants', image: 'assets/images/pochette_theatre.webp'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Musees & expositions',
      emoji: '🏛️',
      subcategories: [
        CultureSubcategory(label: 'Musee', searchTag: 'Musee', emoji: '🏛️', group: 'Musees & expositions', image: 'assets/images/pochette_musee.webp'),
        CultureSubcategory(label: 'Exposition', searchTag: 'Exposition', emoji: '🖼️', group: 'Musees & expositions', image: 'assets/images/pochette_exposition.webp'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Patrimoine & monuments',
      emoji: '🏰',
      subcategories: [
        CultureSubcategory(label: 'Monument historique', searchTag: 'Monument historique', emoji: '🏰', group: 'Patrimoine & monuments', image: 'assets/images/pochette_monument.jpg'),
        CultureSubcategory(label: 'Bibliotheque', searchTag: 'Bibliotheque', emoji: '📚', group: 'Patrimoine & monuments', image: 'assets/images/pochette_bibliotheque.jpg'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Visites & animations',
      emoji: '🎪',
      subcategories: [
        CultureSubcategory(label: 'Visites guidees', searchTag: 'Visites guidees', emoji: '🏛️', group: 'Visites & animations', image: 'assets/images/pochette_visite.webp'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Art',
      emoji: '🎨',
      subcategories: [
        CultureSubcategory(label: 'Galerie d\'art', searchTag: 'Galerie d\'art', emoji: '🎨', group: 'Art', image: 'assets/images/pochette_culture_art.webp'),
      ],
    ),
  ];

  static List<CultureSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
