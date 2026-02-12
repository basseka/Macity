class GamingSubcategory {
  final String label;
  final String searchTag;
  final String emoji;
  final String group;
  final String? image;

  const GamingSubcategory({
    required this.label,
    required this.searchTag,
    required this.emoji,
    required this.group,
    this.image,
  });
}

class GamingCategoryGroup {
  final String name;
  final String emoji;
  final List<GamingSubcategory> subcategories;

  const GamingCategoryGroup({
    required this.name,
    required this.emoji,
    required this.subcategories,
  });
}

class GamingCategoryData {
  GamingCategoryData._();

  static const groups = [
    GamingCategoryGroup(
      name: 'Cette Semaine',
      emoji: '\uD83D\uDCC5',
      subcategories: [
        GamingSubcategory(label: 'Cette Semaine', searchTag: 'Cette Semaine', emoji: '\uD83D\uDCC5', group: 'Cette Semaine'),
      ],
    ),
    GamingCategoryGroup(
      name: 'Jeux video',
      emoji: '\uD83C\uDFAE',
      subcategories: [
        GamingSubcategory(label: 'Salle d\'arcade', searchTag: 'Salle arcade', emoji: '\uD83D\uDD79\uFE0F', group: 'Jeux video'),
        GamingSubcategory(label: 'Gaming cafe', searchTag: 'Gaming cafe', emoji: '\uD83C\uDFAE', group: 'Jeux video'),
        GamingSubcategory(label: 'VR & realite virtuelle', searchTag: 'Realite virtuelle VR', emoji: '\uD83E\uDD7D', group: 'Jeux video'),
      ],
    ),
    GamingCategoryGroup(
      name: 'Jeux de societe & cartes',
      emoji: '\uD83C\uDFB2',
      subcategories: [
        GamingSubcategory(label: 'Bar a jeux', searchTag: 'Bar a jeux', emoji: '\uD83C\uDFB2', group: 'Jeux de societe & cartes'),
        GamingSubcategory(label: 'Boutique jeux', searchTag: 'Boutique jeux', emoji: '\uD83C\uDCCF', group: 'Jeux de societe & cartes'),
        GamingSubcategory(label: 'Escape game', searchTag: 'Escape game', emoji: '\uD83D\uDD10', group: 'Jeux de societe & cartes'),
      ],
    ),
    GamingCategoryGroup(
      name: 'Manga, comics & BD',
      emoji: '\uD83D\uDCDA',
      subcategories: [
        GamingSubcategory(label: 'Boutique manga', searchTag: 'Boutique manga', emoji: '\uD83D\uDCDA', group: 'Manga, comics & BD'),
        GamingSubcategory(label: 'Comics & BD', searchTag: 'Comics BD', emoji: '\uD83E\uDDB8', group: 'Manga, comics & BD'),
        GamingSubcategory(label: 'Figurines & goodies', searchTag: 'Figurines goodies', emoji: '\uD83E\uDDF8', group: 'Manga, comics & BD'),
      ],
    ),
    GamingCategoryGroup(
      name: 'Evenements & conventions',
      emoji: '\uD83C\uDFAA',
      subcategories: [
        GamingSubcategory(label: 'Convention & salon', searchTag: 'Convention salon geek', emoji: '\uD83C\uDFAA', group: 'Evenements & conventions'),
        GamingSubcategory(label: 'Tournoi e-sport', searchTag: 'Tournoi esport', emoji: '\uD83C\uDFC6', group: 'Evenements & conventions'),
        GamingSubcategory(label: 'Cosplay', searchTag: 'Cosplay', emoji: '\uD83C\uDFAD', group: 'Evenements & conventions'),
      ],
    ),
  ];

  static List<GamingSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
