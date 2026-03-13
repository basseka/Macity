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
      name: 'Arts vivants',
      emoji: '\uD83C\uDFAD',
      subcategories: [
        CultureSubcategory(label: 'Theatre', searchTag: 'Theatre', emoji: '\uD83C\uDFAD', group: 'Arts vivants', image: 'assets/images/pochette_theatre.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Musees & expositions',
      emoji: '\uD83C\uDFDB\uFE0F',
      subcategories: [
        CultureSubcategory(label: 'Musee', searchTag: 'Musee', emoji: '\uD83C\uDFDB\uFE0F', group: 'Musees & expositions', image: 'assets/images/pochette_musee.png'),
        CultureSubcategory(label: 'Exposition', searchTag: 'Exposition', emoji: '\uD83D\uDDBC\uFE0F', group: 'Musees & expositions', image: 'assets/images/pochette_exposition.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Patrimoine & monuments',
      emoji: '\uD83C\uDFF0',
      subcategories: [
        CultureSubcategory(label: 'Monument historique', searchTag: 'Monument historique', emoji: '\uD83C\uDFF0', group: 'Patrimoine & monuments', image: 'assets/images/pochette_monument.png'),
        CultureSubcategory(label: 'Bibliotheque', searchTag: 'Bibliotheque', emoji: '\uD83D\uDCDA', group: 'Patrimoine & monuments', image: 'assets/images/pochette_bibliotheque.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Visites & animations',
      emoji: '\uD83C\uDFAA',
      subcategories: [
        CultureSubcategory(label: 'Visites guidees', searchTag: 'Visites guidees', emoji: '\uD83C\uDFDB\uFE0F', group: 'Visites & animations', image: 'assets/images/pochette_visite.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Art',
      emoji: '\uD83C\uDFA8',
      subcategories: [
        CultureSubcategory(label: 'Galerie d\'art', searchTag: 'Galerie d\'art', emoji: '\uD83C\uDFA8', group: 'Art', image: 'assets/images/pochette_culture_art.png'),
      ],
    ),
  ];

  static List<CultureSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
