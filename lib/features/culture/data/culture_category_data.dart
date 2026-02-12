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
        CultureSubcategory(label: 'Cette Semaine', searchTag: 'Cette Semaine', emoji: '\uD83D\uDCC5', group: 'Cette Semaine', image: 'assets/images/sc_cette_semaine.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Arts vivants',
      emoji: '\uD83C\uDFAD',
      subcategories: [
        CultureSubcategory(label: 'Theatre', searchTag: 'Theatre', emoji: '\uD83C\uDFAD', group: 'Arts vivants', image: 'assets/images/sc_theatre.png'),
        CultureSubcategory(label: 'Danse', searchTag: 'Danse', emoji: '\uD83D\uDC83', group: 'Arts vivants', image: 'assets/images/sc_animations.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Musees & expositions',
      emoji: '\uD83C\uDFDB\uFE0F',
      subcategories: [
        CultureSubcategory(label: 'Exposition', searchTag: 'Exposition', emoji: '\uD83D\uDDBC\uFE0F', group: 'Musees & expositions', image: 'assets/images/sc_expo.png'),
        CultureSubcategory(label: 'Galerie d\'art', searchTag: 'Galerie d\'art', emoji: '\uD83C\uDFA8', group: 'Musees & expositions', image: 'assets/images/sc_vernissage.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Patrimoine & monuments',
      emoji: '\uD83C\uDFF0',
      subcategories: [
        CultureSubcategory(label: 'Monument historique', searchTag: 'Monument historique', emoji: '\uD83C\uDFF0', group: 'Patrimoine & monuments', image: 'assets/images/sc_visites.png'),
      ],
    ),
    CultureCategoryGroup(
      name: 'Visites & animations',
      emoji: '\uD83C\uDFAA',
      subcategories: [
        CultureSubcategory(label: 'Visites guidees', searchTag: 'Visites guidees', emoji: '\uD83C\uDFDB\uFE0F', group: 'Visites & animations', image: 'assets/images/sc_visites.png'),
      ],
    ),
  ];

  static List<CultureSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
