import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/utils/city_hub_resolver.dart';

/// Commune française avec son centre géographique et son hub de rattachement.
class CommuneGeo {
  final String nom;
  final String codePostal;
  final String codeDepartement;
  final int population;
  final double lat;
  final double lng;

  const CommuneGeo({
    required this.nom,
    required this.codePostal,
    required this.codeDepartement,
    required this.population,
    required this.lat,
    required this.lng,
  });

  /// Hub de l'app auquel la commune est rattachée (Montauban -> Toulouse).
  String get hub => CityHubResolver.resolveHub(nom, codePostal);

  static CommuneGeo? fromJson(Map<String, dynamic> json) {
    final coords = (json['centre'] as Map?)?['coordinates'] as List?;
    if (coords == null || coords.length < 2) return null;
    final cps = (json['codesPostaux'] as List?)?.cast<String>() ?? const [];
    return CommuneGeo(
      nom: json['nom'] as String? ?? '',
      codePostal: cps.isNotEmpty ? cps.first : '',
      codeDepartement: json['codeDepartement'] as String? ?? '',
      population: (json['population'] as num?)?.toInt() ?? 0,
      lat: (coords[1] as num).toDouble(),
      lng: (coords[0] as num).toDouble(),
    );
  }
}

/// geo.api.gouv.fr (gratuit, sans clé, France uniquement) : commune à partir
/// d'une position GPS, et recherche de communes par nom avec leur centre.
class CommuneGeoService {
  final Dio _dio;

  CommuneGeoService({Dio? dio})
      : _dio = dio ?? DioClient.withBaseUrl(ApiConstants.geoBaseUrl);

  static const _fields = 'nom,codesPostaux,codeDepartement,centre,population';

  /// Commune qui contient le point, null hors de France ou en cas d'erreur.
  Future<CommuneGeo?> communeAt(double lat, double lng) async {
    try {
      final response = await _dio.get(
        ApiConstants.geoCommunesEndpoint,
        queryParameters: {'lat': lat, 'lon': lng, 'fields': _fields},
      );
      final data = response.data as List;
      if (data.isEmpty) return null;
      return CommuneGeo.fromJson(data.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Communes dont le nom correspond, les plus peuplées d'abord.
  Future<List<CommuneGeo>> search(String query) async {
    try {
      final response = await _dio.get(
        ApiConstants.geoCommunesEndpoint,
        queryParameters: {
          'nom': query,
          'fields': _fields,
          'boost': 'population',
          'limit': 10,
        },
      );
      return (response.data as List)
          .map((e) => CommuneGeo.fromJson(e as Map<String, dynamic>))
          .whereType<CommuneGeo>()
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
