import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/gaming/data/gaming_category_data.dart';
import 'package:pulz_app/core/database/app_database.dart';

final gamingCategoryProvider = StateProvider<String?>((ref) => null);

final gamingCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final city = ref.watch(selectedCityProvider);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  if (searchTag == 'Cette Semaine') {
    final allTags = GamingCategoryData.allSubcategories
        .where((s) => s.searchTag != 'Cette Semaine')
        .map((s) => s.searchTag);
    var total = 0;
    for (final tag in allTags) {
      final venues = await repository.searchByVille(ville: city, query: tag);
      total += venues.length;
    }
    return total;
  }
  final venues = await repository.searchByVille(ville: city, query: searchTag);
  return venues.length;
});

final gamingVenuesProvider = FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final category = ref.watch(gamingCategoryProvider);

  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  if (category == 'Cette Semaine') {
    final allTags = GamingCategoryData.allSubcategories
        .where((s) => s.searchTag != 'Cette Semaine')
        .map((s) => s.searchTag);
    final all = <CommerceModel>[];
    for (final tag in allTags) {
      final venues = await repository.searchByVille(ville: city, query: tag);
      all.addAll(venues);
    }
    return all;
  }
  return repository.searchByVille(ville: city, query: category);
});

/// Provider groupé par searchTag pour l'affichage "Cette Semaine".
final gamingGroupedVenuesProvider =
    FutureProvider<Map<String, List<CommerceModel>>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  final grouped = <String, List<CommerceModel>>{};
  for (final sub in GamingCategoryData.allSubcategories) {
    if (sub.searchTag == 'Cette Semaine') continue;
    grouped[sub.searchTag] =
        await repository.searchByVille(ville: city, query: sub.searchTag);
  }
  return grouped;
});
