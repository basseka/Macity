import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gere la sous-categorie selectionnee pour chaque mode (day, sport, culture, …).
/// Pas de persistence : on repart toujours de la grille au demarrage.
class ModeSubcategoriesNotifier extends StateNotifier<Map<String, String?>> {
  ModeSubcategoriesNotifier() : super({});

  void select(String mode, String? subcategory) {
    state = {...state, mode: subcategory};
  }
}

final modeSubcategoriesProvider =
    StateNotifierProvider<ModeSubcategoriesNotifier, Map<String, String?>>(
  (ref) => ModeSubcategoriesNotifier(),
);

/// Providers derives par mode — utilises par les ecrans et les data providers.
final selectedDaySubcategoryProvider = Provider<String?>((ref) {
  return ref.watch(modeSubcategoriesProvider)['day'];
});

final daySubcategoryProvider = Provider<String?>((ref) {
  return ref.watch(modeSubcategoriesProvider)['day'];
});

final sportSubcategoryProvider = Provider<String?>((ref) {
  return ref.watch(modeSubcategoriesProvider)['sport'];
});

final cultureCategoryProvider = Provider<String?>((ref) {
  return ref.watch(modeSubcategoriesProvider)['culture'];
});

final familyCategoryProvider = Provider<String?>((ref) {
  return ref.watch(modeSubcategoriesProvider)['family'];
});

final foodCategoryProvider = Provider<String?>((ref) {
  return ref.watch(modeSubcategoriesProvider)['food'];
});

final gamingCategoryProvider = Provider<String?>((ref) {
  return ref.watch(modeSubcategoriesProvider)['gaming'];
});

final nightCategoryProvider = Provider<String?>((ref) {
  return ref.watch(modeSubcategoriesProvider)['night'];
});
