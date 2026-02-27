import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gere la sous-categorie selectionnee pour chaque mode (day, sport, culture, …)
/// et persiste le choix dans SharedPreferences.
class ModeSubcategoriesNotifier extends StateNotifier<Map<String, String?>> {
  ModeSubcategoriesNotifier() : super({}) {
    _load();
  }

  static const _key = 'mode_selected_subcategories';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null) {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      state = decoded.map((k, v) => MapEntry(k, v as String?));
    }
  }

  void select(String mode, String? subcategory) {
    state = {...state, mode: subcategory};
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state));
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
