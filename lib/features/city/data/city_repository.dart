import 'package:pulz_app/features/city/data/city_api_service.dart';
import 'package:pulz_app/features/city/domain/models/ville.dart';
import 'package:pulz_app/features/city/domain/models/geo_commune.dart';

class CityRepository {
  final CityApiService _api;

  CityRepository({CityApiService? api}) : _api = api ?? CityApiService();

  Future<List<VilleModel>> searchCities(String query) async {
    final communes = await _api.searchCommunes(query);
    return communes.map(_communeToVille).toList();
  }

  VilleModel _communeToVille(GeoCommune commune) {
    return VilleModel(
      nom: commune.nom,
      codePostal:
          commune.codesPostaux.isNotEmpty ? commune.codesPostaux.first : '',
      departement: commune.codeDepartement,
      population: commune.population,
    );
  }
}
