class FoodSubcategory {
  final String label;
  final String searchTag;
  final String emoji;
  final String group;
  final String? image;

  const FoodSubcategory({
    required this.label,
    required this.searchTag,
    required this.emoji,
    required this.group,
    this.image,
  });
}

class FoodCategoryGroup {
  final String name;
  final String emoji;
  final List<FoodSubcategory> subcategories;

  const FoodCategoryGroup({
    required this.name,
    required this.emoji,
    required this.subcategories,
  });
}

class FoodCategoryData {
  FoodCategoryData._();

  static const groups = [
    FoodCategoryGroup(
      name: 'Cette Semaine',
      emoji: '\uD83D\uDCC5',
      subcategories: [
        FoodSubcategory(label: 'Cette Semaine', searchTag: 'Cette Semaine', emoji: '\uD83D\uDCC5', group: 'Cette Semaine'),
      ],
    ),
    FoodCategoryGroup(
      name: 'Restaurants',
      emoji: '\uD83C\uDF7D\uFE0F',
      subcategories: [
        FoodSubcategory(label: 'Restaurant', searchTag: 'Restaurant', emoji: '\uD83C\uDF7D\uFE0F', group: 'Restaurants'),
        FoodSubcategory(label: 'Sushi & japonais', searchTag: 'Sushi japonais', emoji: '\uD83C\uDF63', group: 'Restaurants'),
      ],
    ),
    FoodCategoryGroup(
      name: 'Cafes & brunchs',
      emoji: '\u2615',
      subcategories: [
        FoodSubcategory(label: 'Salon de the', searchTag: 'Salon de the', emoji: '\uD83C\uDF75', group: 'Cafes & brunchs'),
        FoodSubcategory(label: 'Brunch', searchTag: 'Brunch', emoji: '\uD83E\uDD50', group: 'Cafes & brunchs'),
      ],
    ),
    FoodCategoryGroup(
      name: 'Bien-etre & lifestyle',
      emoji: '\uD83E\uDDD8',
      subcategories: [
        FoodSubcategory(label: 'Spa & hammam', searchTag: 'Spa hammam', emoji: '\uD83E\uDDD6', group: 'Bien-etre & lifestyle'),
        FoodSubcategory(label: 'Yoga & meditation', searchTag: 'Yoga meditation', emoji: '\uD83E\uDDD8', group: 'Bien-etre & lifestyle'),
      ],
    ),
  ];

  static List<FoodSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
