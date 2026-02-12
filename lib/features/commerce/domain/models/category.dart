class CategoryModel {
  final String nom;
  final String emoji;

  const CategoryModel({required this.nom, required this.emoji});

  String get displayName => '$emoji $nom';
}
