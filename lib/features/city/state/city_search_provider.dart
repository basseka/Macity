import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/data/city_repository.dart';
import 'package:pulz_app/features/city/domain/models/ville.dart';

final citySearchQueryProvider = StateProvider<String>((ref) => '');

final citySearchResultsProvider = FutureProvider<List<VilleModel>>((ref) async {
  final query = ref.watch(citySearchQueryProvider);
  if (query.length < 2) return [];

  final repository = CityRepository();
  return repository.searchCities(query);
});
