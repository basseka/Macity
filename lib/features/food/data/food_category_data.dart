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
      name: 'A venir',
      emoji: '',
      subcategories: [
        FoodSubcategory(label: 'Calendrier', searchTag: 'A venir', emoji: '', group: 'A venir', image: 'assets/images/pochette_cettesemaine.jpg'),
      ],
    ),
    FoodCategoryGroup(
      name: 'Restaurants',
      emoji: '',
      subcategories: [
        FoodSubcategory(label: 'Restaurant', searchTag: 'Restaurant', emoji: '', group: 'Restaurants', image: 'assets/images/pochette_restaurant.jpg'),
        FoodSubcategory(label: 'Guinguette', searchTag: 'Guinguette', emoji: '', group: 'Restaurants', image: 'assets/images/pochette_restaurant.jpg'),
        FoodSubcategory(label: 'Buffets', searchTag: 'Buffets', emoji: '', group: 'Restaurants', image: 'assets/images/pochette_restaurant.jpg'),
      ],
    ),
    FoodCategoryGroup(
      name: 'Cafes & brunchs',
      emoji: '',
      subcategories: [
        FoodSubcategory(label: 'Salon de the', searchTag: 'Salon de the', emoji: '', group: 'Cafes & brunchs', image: 'assets/images/pochette_salondethe.jpg'),
        FoodSubcategory(label: 'Brunch', searchTag: 'Brunch', emoji: '', group: 'Cafes & brunchs', image: 'assets/images/pochette_brunch.jpg'),
      ],
    ),
    FoodCategoryGroup(
      name: 'Bien-etre & lifestyle',
      emoji: '',
      subcategories: [
        FoodSubcategory(label: 'Spa & hammam', searchTag: 'Spa hammam', emoji: '', group: 'Bien-etre & lifestyle', image: 'assets/images/pochette_spa&hammam.png'),
        FoodSubcategory(label: 'Massage', searchTag: 'Massage', emoji: '', group: 'Bien-etre & lifestyle', image: 'assets/images/pochette_spa&hammam.png'),
        FoodSubcategory(label: 'Yoga & meditation', searchTag: 'Yoga meditation', emoji: '', group: 'Bien-etre & lifestyle', image: 'assets/images/pochette_yoga.jpg'),
      ],
    ),
  ];

  static List<FoodSubcategory> get allSubcategories =>
      groups.expand((g) => g.subcategories).toList();
}
