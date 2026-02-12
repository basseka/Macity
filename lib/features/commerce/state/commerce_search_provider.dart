import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/core/database/app_database.dart';

final commerceSearchQueryProvider = StateProvider<String>((ref) => '');

final commerceSearchResultsProvider =
    FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final query = ref.watch(commerceSearchQueryProvider);
  if (query.isEmpty) return [];

  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  return repository.searchByVille(ville: city, query: query);
});
