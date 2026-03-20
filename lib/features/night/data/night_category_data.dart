class NightSubcategory {
  final String label;
  final String searchTag;
  final String emoji;
  final String group;
  final String? image;

  const NightSubcategory({
    required this.label,
    required this.searchTag,
    required this.emoji,
    required this.group,
    this.image,
  });
}

class NightCategoryGroup {
  final String name;
  final String emoji;
  final List<NightSubcategory> subcategories;

  const NightCategoryGroup({
    required this.name,
    required this.emoji,
    required this.subcategories,
  });
}

class NightCategoryData {
  NightCategoryData._();

  static const groups = [
    NightCategoryGroup(
      name: 'A venir',
      emoji: '\uD83D\uDCC5',
      subcategories: [
        NightSubcategory(label: 'Agenda', searchTag: 'A venir', emoji: '\uD83D\uDCC5', group: 'A venir', image: 'assets/images/pochette_default.png'),
      ],
    ),
    NightCategoryGroup(
      name: 'Bars & vie nocturne',
      emoji: '\uD83C\uDF78',
      subcategories: [
        NightSubcategory(label: 'Club / Discotheque', searchTag: 'Club Discotheque', emoji: '\uD83C\uDF86', group: 'Bars & vie nocturne', image: 'assets/images/pochette_discotheque.png'),
        NightSubcategory(label: 'Bar de nuit', searchTag: 'Bar de nuit', emoji: '\uD83C\uDF19', group: 'Bars & vie nocturne', image: 'assets/images/pochette_pub.png'),
        NightSubcategory(label: 'Bar a cocktails', searchTag: 'Bar a cocktails', emoji: '\uD83C\uDF79', group: 'Bars & vie nocturne', image: 'assets/images/pochette_pub.png'),
        NightSubcategory(label: 'Bar a chicha', searchTag: 'Bar a chicha', emoji: '\uD83D\uDCA8', group: 'Bars & vie nocturne', image: 'assets/images/pochette_chicha.png'),
        NightSubcategory(label: 'Pub', searchTag: 'Pub', emoji: '\uD83C\uDF7B', group: 'Bars & vie nocturne', image: 'assets/images/pochette_pub.png'),
      ],
    ),
    NightCategoryGroup(
      name: 'Commerces ouverts la nuit',
      emoji: '\uD83D\uDED2',
      subcategories: [
        NightSubcategory(label: 'SOS Apero', searchTag: 'SOS Apero', emoji: '\uD83C\uDF7B', group: 'Commerces ouverts la nuit', image: 'assets/images/pochette_sosapero.png'),
        NightSubcategory(label: 'Epicerie de nuit', searchTag: 'Epicerie de nuit', emoji: '\uD83C\uDF1C', group: 'Commerces ouverts la nuit', image: 'assets/images/pochette_epicerie.png'),
        NightSubcategory(label: 'Tabac de nuit', searchTag: 'Tabac de nuit', emoji: '\uD83D\uDEAC', group: 'Commerces ouverts la nuit', image: 'assets/images/pochette_tabac.png'),
      ],
    ),
    NightCategoryGroup(
      name: 'Hebergement',
      emoji: '\uD83C\uDFE8',
      subcategories: [
        NightSubcategory(label: 'Hotel', searchTag: 'Hotel', emoji: '\uD83D\uDECF\uFE0F', group: 'Hebergement', image: 'assets/images/pochette_hotel.png'),
      ],
    ),
  ];

  static List<NightSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
