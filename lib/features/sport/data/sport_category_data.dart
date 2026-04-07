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
      name: 'A venir',
      emoji: '\uD83D\uDCC5',
      subcategories: [
        SportSubcategory(label: 'Agenda', searchTag: 'A venir', emoji: '\uD83D\uDCC5', group: 'A venir', image: 'assets/images/pochette_cettesemaine.jpg'),
      ],
    ),
    SportCategoryGroup(
      name: 'Rugby',
      emoji: '',
      subcategories: [
        SportSubcategory(label: 'Rugby', searchTag: 'Rugby', emoji: '', group: 'Rugby', image: 'assets/images/shell_sport_rugby.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Football',
      emoji: '\u26BD',
      subcategories: [
        SportSubcategory(label: 'Football', searchTag: 'Football', emoji: '\u26BD', group: 'Football', image: 'assets/images/shell_sport_football.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Basketball',
      emoji: '\uD83C\uDFC0',
      subcategories: [
        SportSubcategory(label: 'Basketball', searchTag: 'Basketball', emoji: '\uD83C\uDFC0', group: 'Basketball', image: 'assets/images/shell_sport_basketball.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Handball',
      emoji: '\uD83E\uDD3E',
      subcategories: [
        SportSubcategory(label: 'Handball', searchTag: 'Handball', emoji: '\uD83E\uDD3E', group: 'Handball', image: 'assets/images/shell_sport_handball.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Boxe',
      emoji: '\uD83E\uDD4A',
      subcategories: [
        SportSubcategory(label: 'Boxe', searchTag: 'Boxe', emoji: '\uD83E\uDD4A', group: 'Boxe', image: 'assets/images/pochette_boxe.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Natation',
      emoji: '\uD83C\uDFCA',
      subcategories: [
        SportSubcategory(label: 'Natation', searchTag: 'Natation', emoji: '\uD83C\uDFCA', group: 'Natation', image: 'assets/images/pochette_natation.jpg'),
      ],
    ),
    SportCategoryGroup(
      name: 'Course a pied',
      emoji: '\uD83C\uDFC3',
      subcategories: [
        SportSubcategory(label: 'Course a pied', searchTag: 'Courses a pied', emoji: '\uD83C\uDFC3', group: 'Course a pied', image: 'assets/images/pochette_course.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Golf',
      emoji: '\u26F3',
      subcategories: [
        SportSubcategory(label: 'Golf', searchTag: 'Golf', emoji: '\u26F3', group: 'Golf', image: 'assets/images/pochette_Golf.jpg'),
      ],
    ),
    SportCategoryGroup(
      name: 'Raquette',
      emoji: '\uD83C\uDFBE',
      subcategories: [
        SportSubcategory(label: 'Raquette', searchTag: 'Raquette', emoji: '\uD83C\uDFBE', group: 'Raquette', image: 'assets/images/pochette_autre.jpg'),
      ],
    ),
    SportCategoryGroup(
      name: 'Stage de danse',
      emoji: '\uD83D\uDC83',
      subcategories: [
        SportSubcategory(label: 'Stage de danse', searchTag: 'Stage de danse', emoji: '\uD83D\uDC83', group: 'Stage de danse', image: 'assets/images/pochette_stagedanse.png'),
      ],
    ),
    SportCategoryGroup(
      name: 'Salle de Fitness',
      emoji: '\uD83D\uDCAA',
      subcategories: [
        SportSubcategory(label: 'Salle de Fitness', searchTag: 'Salle de fitness', emoji: '\uD83D\uDCAA', group: 'Salle de Fitness', image: 'assets/images/shell_sport_fitness.png'),
      ],
    ),
  ];

  static List<SportSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();

  /// Sous-catégories affichées dans le hub Matchs (sports collectifs).
  static List<SportSubcategory> get matchSubcategories =>
      groups
          .where((g) => const {
                'Rugby', 'Football', 'Basketball', 'Handball',
              }.contains(g.name))
          .expand((g) => g.subcategories)
          .toList();

  /// Sous-catégories affichées dans le hub Events (autres sports).
  static List<SportSubcategory> get eventSubcategories =>
      groups
          .where((g) => const {
                'A venir', 'Boxe', 'Natation', 'Course a pied', 'Golf', 'Stage de danse',
              }.contains(g.name))
          .expand((g) => g.subcategories)
          .toList();

  /// Sous-catégories affichées dans le hub Complexe sportif.
  static const complexeSportifSubcategories = [
    SportSubcategory(label: 'Salle de Fitness', searchTag: 'Salle de fitness', emoji: '\uD83D\uDCAA', group: 'Salle de Fitness', image: 'assets/images/shell_sport_fitness.png'),
    SportSubcategory(label: 'Salle de danse', searchTag: 'Danse', emoji: '\uD83D\uDC83', group: 'Danse', image: 'assets/images/pochette_animation.png'),
    SportSubcategory(label: 'Salles de boxe', searchTag: 'Salles de boxe', emoji: '\uD83E\uDD4A', group: 'Boxe', image: 'assets/images/pochette_boxe.png'),
    SportSubcategory(label: 'Terrain de football', searchTag: 'Terrain de football', emoji: '\u26BD', group: 'Football', image: 'assets/images/shell_sport_football.png'),
    SportSubcategory(label: 'Terrain de basketball', searchTag: 'Terrain de basketball', emoji: '\uD83C\uDFC0', group: 'Basketball', image: 'assets/images/shell_sport_basketball.png'),
    SportSubcategory(label: 'Piscine', searchTag: 'Piscine', emoji: '\uD83C\uDFCA', group: 'Natation', image: 'assets/images/pochette_natation.jpg'),
    SportSubcategory(label: 'Golf', searchTag: 'Golf', emoji: '\u26F3', group: 'Golf', image: 'assets/images/pochette_Golf.jpg'),
    SportSubcategory(label: 'Raquette', searchTag: 'Raquette', emoji: '\uD83C\uDFBE', group: 'Raquette', image: 'assets/images/pochette_autre.jpg'),
  ];

  /// Sous-catégories affichées dans le hub Raquette.
  static const raquetteSubcategories = [
    SportSubcategory(label: 'Tennis', searchTag: 'Tennis', emoji: '\uD83C\uDFBE', group: 'Raquette', image: 'assets/images/pochette_autre.jpg'),
    SportSubcategory(label: 'Padel', searchTag: 'Padel', emoji: '\uD83C\uDFBE', group: 'Raquette', image: 'assets/images/pochette_autre.jpg'),
    SportSubcategory(label: 'Squash', searchTag: 'Squash', emoji: '\uD83C\uDFBE', group: 'Raquette', image: 'assets/images/pochette_autre.jpg'),
    SportSubcategory(label: 'Ping-pong', searchTag: 'Ping-pong', emoji: '\uD83C\uDFD3', group: 'Raquette', image: 'assets/images/pochette_autre.jpg'),
    SportSubcategory(label: 'Badminton', searchTag: 'Badminton', emoji: '\uD83C\uDFF8', group: 'Raquette', image: 'assets/images/pochette_autre.jpg'),
  ];
}
