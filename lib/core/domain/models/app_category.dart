/// Modèle unifié pour toutes les catégories/sous-catégories.
/// Remplace les classes hardcodées *Subcategory de chaque mode.
class AppCategory {
  final String id;
  final String mode;
  final String groupe;
  final String groupeEmoji;
  final int groupeOrdre;
  final String label;
  final String searchTag;
  final String emoji;
  final String imageUrl;
  final int ordre;
  final String? ville;
  final String displayType;
  final Map<String, dynamic>? metadata;

  const AppCategory({
    required this.id,
    required this.mode,
    required this.groupe,
    required this.groupeEmoji,
    required this.groupeOrdre,
    required this.label,
    required this.searchTag,
    required this.emoji,
    required this.imageUrl,
    required this.ordre,
    this.ville,
    required this.displayType,
    this.metadata,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: json['id'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      groupe: json['groupe'] as String? ?? '',
      groupeEmoji: json['groupe_emoji'] as String? ?? '',
      groupeOrdre: json['groupe_ordre'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      searchTag: json['search_tag'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      ordre: json['ordre'] as int? ?? 0,
      ville: json['ville'] as String?,
      displayType: json['display_type'] as String? ?? 'venues',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Raccourci pour accéder à une valeur dans metadata.
  String? meta(String key) => metadata?[key] as String?;
}

/// Groupe de catégories (pour affichage hub avec sections).
class AppCategoryGroup {
  final String name;
  final String emoji;
  final int ordre;
  final List<AppCategory> categories;

  const AppCategoryGroup({
    required this.name,
    required this.emoji,
    required this.ordre,
    required this.categories,
  });
}
