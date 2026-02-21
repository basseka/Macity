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
      name: 'Cette Semaine',
      emoji: '\uD83D\uDCC5',
      subcategories: [
        CultureSubcategory(label: 'Cette Semaine', searchTag: 'Cette Semaine', emoji: '\uD83D\uDCC5', group: 'Cette Semaine', image: 'assets/images/pochette_default.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Arts vivants',
      emoji: '\uD83C\uDFAD',
      subcategories: [
        CultureSubcategory(label: 'Theatre', searchTag: 'Theatre', emoji: '\uD83C\uDFAD', group: 'Arts vivants', image: 'assets/images/pochette_theatre.png'),
        CultureSubcategory(label: 'Danse', searchTag: 'Danse', emoji: '\uD83D\uDC83', group: 'Arts vivants', image: 'assets/images/pochette_animation.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Musees & expositions',
      emoji: '\uD83C\uDFDB\uFE0F',
      subcategories: [
        CultureSubcategory(label: 'Musee', searchTag: 'Musee', emoji: '\uD83C\uDFDB\uFE0F', group: 'Musees & expositions', image: 'assets/images/pochette_culture_art.png'),
        CultureSubcategory(label: 'Exposition', searchTag: 'Exposition', emoji: '\uD83D\uDDBC\uFE0F', group: 'Musees & expositions', image: 'assets/images/pochette_culture_art.png'),
        CultureSubcategory(label: 'Galerie d\'art', searchTag: 'Galerie d\'art', emoji: '\uD83C\uDFA8', group: 'Musees & expositions', image: 'assets/images/pochette_culture_art.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Patrimoine & monuments',
      emoji: '\uD83C\uDFF0',
      subcategories: [
        CultureSubcategory(label: 'Monument historique', searchTag: 'Monument historique', emoji: '\uD83C\uDFF0', group: 'Patrimoine & monuments', image: 'assets/images/pochette_visite.png'),
        CultureSubcategory(label: 'Bibliotheque', searchTag: 'Bibliotheque', emoji: '\uD83D\uDCDA', group: 'Patrimoine & monuments', image: 'assets/images/pochette_culture_art.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Visites & animations',
      emoji: '\uD83C\uDFAA',
      subcategories: [
        CultureSubcategory(label: 'Visites guidees', searchTag: 'Visites guidees', emoji: '\uD83C\uDFDB\uFE0F', group: 'Visites & animations', image: 'assets/images/pochette_visite.png'),
      ],
    ),
  ];

  static List<CultureSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
