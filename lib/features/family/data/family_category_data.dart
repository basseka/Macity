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

  static const groups = [
    FamilyCategoryGroup(
      name: 'Cette Semaine',
      emoji: '\uD83D\uDCC5',
      subcategories: [
        FamilySubcategory(label: 'Cette Semaine', searchTag: 'Cette Semaine', emoji: '\uD83D\uDCC5', group: 'Cette Semaine', image: 'assets/images/sc_cette_semaine.png'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Parcs & jeux',
      emoji: '\uD83C\uDFA0',
      subcategories: [
        FamilySubcategory(label: 'Parc d\'attractions', searchTag: 'Parc d\'attractions', emoji: '\uD83C\uDFA2', group: 'Parcs & jeux', image: 'assets/images/sc_parc_attraction.png'),
        FamilySubcategory(label: 'Aire de jeux', searchTag: 'Aire de jeux', emoji: '\uD83E\uDDD2', group: 'Parcs & jeux', image: 'assets/images/sc_parc_attraction.png'),
        FamilySubcategory(label: 'Parc animalier', searchTag: 'Parc animalier', emoji: '\uD83E\uDD81', group: 'Parcs & jeux', image: 'assets/images/sc_parc_animalier.png'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Loisirs',
      emoji: '\uD83C\uDFAC',
      subcategories: [
        FamilySubcategory(label: 'Cinema', searchTag: 'Cinema', emoji: '\uD83C\uDFAC', group: 'Loisirs', image: 'assets/images/sc_animations.png'),
        FamilySubcategory(label: 'Bowling', searchTag: 'Bowling', emoji: '\uD83C\uDFB3', group: 'Loisirs', image: 'assets/images/sc_animations.png'),
        FamilySubcategory(label: 'Laser game', searchTag: 'Laser game', emoji: '\uD83D\uDD2B', group: 'Loisirs', image: 'assets/images/sc_animations.png'),
        FamilySubcategory(label: 'Escape game', searchTag: 'Escape game', emoji: '\uD83D\uDD10', group: 'Loisirs', image: 'assets/images/sc_animations.png'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Culture',
      emoji: '\uD83C\uDFDB\uFE0F',
      subcategories: [
        FamilySubcategory(label: 'Aquarium', searchTag: 'Aquarium', emoji: '\uD83D\uDC20', group: 'Culture', image: 'assets/images/sc_parc_animalier.png'),
      ],
    ),
    FamilyCategoryGroup(
      name: 'Restauration',
      emoji: '\uD83C\uDF54',
      subcategories: [
        FamilySubcategory(label: 'Restaurant familial', searchTag: 'Restaurant familial', emoji: '\uD83D\uDC68\u200D\uD83D\uDC69\u200D\uD83D\uDC67\u200D\uD83D\uDC66', group: 'Restauration', image: 'assets/images/sc_fermes.png'),
      ],
    ),
  ];

  static List<FamilySubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
