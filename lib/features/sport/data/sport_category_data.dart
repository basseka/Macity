class SportSubcategory {
  final String label;
  final String searchTag;
  final String emoji;
  final String group;
  final String? image;

  const SportSubcategory({
    required this.label,
    required this.searchTag,
    required this.emoji,
    required this.group,
    this.image,
  });
}

class SportCategoryGroup {
  final String name;
  final String emoji;
  final List<SportSubcategory> subcategories;

  const SportCategoryGroup({
    required this.name,
    required this.emoji,
    required this.subcategories,
  });
}

class SportCategoryData {
  SportCategoryData._();

  static const groups = [
    SportCategoryGroup(
      name: 'Cette Semaine',
      emoji: '\uD83D\uDCC5',
      subcategories: [
        SportSubcategory(label: 'Cette Semaine', searchTag: 'Cette Semaine', emoji: '\uD83D\uDCC5', group: 'Cette Semaine', image: 'assets/images/sc_cette_semaine.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Rugby',
      emoji: '\uD83C\uDFC9',
      subcategories: [
        SportSubcategory(label: 'Rugby', searchTag: 'Rugby', emoji: '\uD83C\uDFC9', group: 'Rugby', image: 'assets/images/sc_rugby.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Football',
      emoji: '\u26BD',
      subcategories: [
        SportSubcategory(label: 'Football', searchTag: 'Football', emoji: '\u26BD', group: 'Football', image: 'assets/images/sc_football.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Basketball',
      emoji: '\uD83C\uDFC0',
      subcategories: [
        SportSubcategory(label: 'Basketball', searchTag: 'Basketball', emoji: '\uD83C\uDFC0', group: 'Basketball', image: 'assets/images/sc_basketball.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Handball',
      emoji: '\uD83E\uDD3E',
      subcategories: [
        SportSubcategory(label: 'Handball', searchTag: 'Handball', emoji: '\uD83E\uDD3E', group: 'Handball', image: 'assets/images/sc_handball.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Boxe',
      emoji: '\uD83E\uDD4A',
      subcategories: [
        SportSubcategory(label: 'Boxe', searchTag: 'Boxe', emoji: '\uD83E\uDD4A', group: 'Boxe', image: 'assets/images/sc_boxe.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Natation',
      emoji: '\uD83C\uDFCA',
      subcategories: [
        SportSubcategory(label: 'Natation', searchTag: 'Natation', emoji: '\uD83C\uDFCA', group: 'Natation', image: 'assets/images/sc_natation.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Course a pied',
      emoji: '\uD83C\uDFC3',
      subcategories: [
        SportSubcategory(label: 'Course a pied', searchTag: 'Courses a pied', emoji: '\uD83C\uDFC3', group: 'Course a pied', image: 'assets/images/sc_course.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Salle de Fitness',
      emoji: '\uD83D\uDCAA',
      subcategories: [
        SportSubcategory(label: 'Salle de Fitness', searchTag: 'Salle de fitness', emoji: '\uD83D\uDCAA', group: 'Salle de Fitness', image: 'assets/images/sc_autres_sport.png'),
      ],
    ),
  ];

  static List<SportSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
