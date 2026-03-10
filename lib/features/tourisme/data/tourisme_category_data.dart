class TourismeSubcategory {
  final String label;
  final String searchTag;
  final String emoji;
  final String group;
  final String? image;

  const TourismeSubcategory({
    required this.label,
    required this.searchTag,
    required this.emoji,
    required this.group,
    this.image,
  });
}

class TourismeCategoryGroup {
  final String name;
  final String emoji;
  final List<TourismeSubcategory> subcategories;

  const TourismeCategoryGroup({
    required this.name,
    required this.emoji,
    required this.subcategories,
  });
}

class TourismeCategoryData {
  TourismeCategoryData._();

  static const groups = [
    TourismeCategoryGroup(
      name: 'Se deplacer',
      emoji: '\uD83D\uDE8C',
      subcategories: [
        TourismeSubcategory(label: 'Se deplacer', searchTag: 'Se deplacer', emoji: '\uD83D\uDE8C', group: 'Se deplacer', image: 'assets/images/carte_se_deplacer.png'),
      ],
    ),
    TourismeCategoryGroup(
      name: 'Plan touristique',
      emoji: '\uD83D\uDDFA\uFE0F',
      subcategories: [
        TourismeSubcategory(label: 'Plan touristique', searchTag: 'Plan touristique', emoji: '\uD83D\uDDFA\uFE0F', group: 'Plan touristique', image: 'assets/images/carte_plan_touristique.png'),
      ],
    ),
    TourismeCategoryGroup(
      name: 'Activites',
      emoji: '\uD83C\uDFA8',
      subcategories: [
        TourismeSubcategory(label: 'Activites', searchTag: 'Activites', emoji: '\uD83C\uDFA8', group: 'Activites', image: 'assets/images/pochette_tourisme_toulouse.png'),
      ],
    ),
    TourismeCategoryGroup(
      name: 'Visiter',
      emoji: '\uD83C\uDFF0',
      subcategories: [
        TourismeSubcategory(label: 'Visiter', searchTag: 'Visiter', emoji: '\uD83C\uDFF0', group: 'Visiter', image: 'assets/images/pochette_tourisme_toulouse.png'),
      ],
    ),
  ];

  static List<TourismeSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
