import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/domain/models/ville.dart';

final citySearchQueryProvider = StateProvider<String>((ref) => '');

const _availableCities = [
  VilleModel(nom: 'Toulouse', codePostal: '31000', departement: 'Haute-Garonne', population: 504078),
  VilleModel(nom: 'Montpellier', codePostal: '34000', departement: 'Herault', population: 299096),
  VilleModel(nom: 'Bordeaux', codePostal: '33000', departement: 'Gironde', population: 260958),
  VilleModel(nom: 'Nice', codePostal: '06000', departement: 'Alpes-Maritimes', population: 342669),
  VilleModel(nom: 'Lyon', codePostal: '69000', departement: 'Rhone', population: 522228),
  VilleModel(nom: 'Paris', codePostal: '75000', departement: 'Paris', population: 2145906),
  VilleModel(nom: 'Marseille', codePostal: '13000', departement: 'Bouches-du-Rhone', population: 873076),
  VilleModel(nom: 'Lille', codePostal: '59000', departement: 'Nord', population: 236234),
  VilleModel(nom: 'Nantes', codePostal: '44000', departement: 'Loire-Atlantique', population: 320732),
  VilleModel(nom: 'Strasbourg', codePostal: '67000', departement: 'Bas-Rhin', population: 290576),
];

final citySearchResultsProvider = FutureProvider<List<VilleModel>>((ref) async {
  final query = ref.watch(citySearchQueryProvider).toLowerCase();
  if (query.isEmpty) return _availableCities;

  return _availableCities
      .where((v) => v.nom.toLowerCase().contains(query))
      .toList();
});
