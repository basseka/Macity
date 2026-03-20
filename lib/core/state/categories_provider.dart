import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/categories_service.dart';
import 'package:pulz_app/core/domain/models/app_category.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

/// Service singleton.
final categoriesServiceProvider = Provider((_) => CategoriesService());

/// Cache de toutes les catégories pour la ville sélectionnée.
/// Se rafraîchit automatiquement quand la ville change.
final allCategoriesProvider = FutureProvider<List<AppCategory>>((ref) {
  final ville = ref.watch(selectedCityProvider);
  return ref.read(categoriesServiceProvider).fetchAllCategories(ville: ville);
});

/// Catégories filtrées par mode (dérivé du cache global).
final modeCategoriesProvider =
    FutureProvider.family<List<AppCategory>, String>((ref, mode) async {
  final all = await ref.watch(allCategoriesProvider.future);
  return all.where((c) => c.mode == mode).toList();
});

/// Catégories groupées par groupe pour un mode donné (pour les hubs).
final modeCategoryGroupsProvider =
    FutureProvider.family<List<AppCategoryGroup>, String>((ref, mode) async {
  final cats = await ref.watch(modeCategoriesProvider(mode).future);
  return CategoriesService.groupCategories(cats);
});

/// Catégories de premier niveau pour un mode (groupe vide = racine, ou groupes uniques).
/// Utilisé pour la grille principale d'un mode comme Day.
final modeRootCategoriesProvider =
    FutureProvider.family<List<AppCategory>, String>((ref, mode) async {
  final cats = await ref.watch(modeCategoriesProvider(mode).future);
  // Catégories racines = celles avec groupe vide, groupe_ordre == 0, ou "A venir"
  return cats.where((c) => c.groupe.isEmpty || c.groupeOrdre <= 0 || c.searchTag == 'A venir').toList();
});

/// Sous-catégories d'un groupe donné pour un mode.
/// Ex: mode=day, groupe=Concert → les salles de concert.
final groupChildrenProvider = FutureProvider.family<List<AppCategory>,
    ({String mode, String groupe})>((ref, params) async {
  final cats = await ref.watch(modeCategoriesProvider(params.mode).future);
  return cats
      .where((c) =>
          c.groupe == params.groupe &&
          c.groupeOrdre > 0) // Exclure les catégories racines du groupe
      .toList();
});

/// Trouver une catégorie par son searchTag dans un mode.
final categoryByTagProvider = FutureProvider.family<AppCategory?,
    ({String mode, String tag})>((ref, params) async {
  final cats = await ref.watch(modeCategoriesProvider(params.mode).future);
  try {
    return cats.firstWhere((c) => c.searchTag == params.tag);
  } catch (_) {
    return null;
  }
});
