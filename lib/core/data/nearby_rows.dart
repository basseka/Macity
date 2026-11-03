import 'package:dio/dio.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/features/city/data/city_coordinates.dart';

/// Complète une liste de lieux d'une ville pauvre par les lieux les plus
/// proches, pour les tables `venues`, `family_venues` et `sport_venues`.
///
/// Règle commune : si la ville a moins de [minResults] lieux en tout (pour le
/// périmètre [scope] : un mode, une table) et que la requête en renvoie moins
/// de [minResults], on ajoute les lieux les plus proches du centre de la zone
/// (mêmes filtres, sans la ville) par rayons de 10, 25 puis 50 km, triés du
/// plus proche au plus lointain. Commune sans rien à 50 km : lieux de son hub.
/// Les villes bien fournies ne sont jamais concernées.
class NearbyRows {
  NearbyRows._();

  static const minResults = 20;
  static const radiiKm = [10.0, 25.0, 50.0];

  static final Map<String, Future<bool>> _poorCityCache = {};

  /// [params] contient le filtre ville sous la forme `ville: villeFilter(ville)`.
  /// [scope] : filtres qui définissent « tous les lieux de la ville » pour le
  /// seuil (ex : `{'mode': 'eq.night'}`).
  static Future<List<dynamic>> fetch(
    Dio dio, {
    required String table,
    required Map<String, String> params,
    required String ville,
    required String Function(String ville) villeFilter,
    Map<String, String> scope = const {},
  }) async {
    final local =
        (await dio.get(table, queryParameters: params)).data as List;
    final center = CityCoordinates.maybeOf(ville);
    if (center == null || local.length >= minResults) return local;
    if (!await isPoorCity(dio,
        table: table, ville: ville, villeFilter: villeFilter, scope: scope,)) {
      return local;
    }

    double dist(dynamic r) {
      final m = r as Map<String, dynamic>;
      final lat = (m['latitude'] as num?)?.toDouble();
      final lng = (m['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return double.infinity;
      return Haversine.km(center.lat, center.lng, lat, lng);
    }

    final seen = local.map((e) => (e as Map<String, dynamic>)['id']).toSet();
    var extras = <dynamic>[];
    for (final radius in radiiKm) {
      final around = Map<String, String>.of(params)
        ..remove('ville')
        ..['and'] = Haversine.bboxFilter(center.lat, center.lng, radius);
      final rows = (await dio.get(table, queryParameters: around)).data as List;
      extras = rows
          .where((r) =>
              !seen.contains((r as Map<String, dynamic>)['id']) &&
              dist(r) <= radius,)
          .toList();
      if (local.length + extras.length >= minResults) break;
    }
    extras.sort((a, b) => dist(a).compareTo(dist(b)));
    final result = [...local, ...extras];
    if (result.isNotEmpty) return result;

    final hub = CityCoordinates.hubOf(ville);
    if (hub == null || hub.toLowerCase() == ville.toLowerCase()) return result;
    final hubRows = (await dio.get(table,
            queryParameters: Map<String, String>.of(params)
              ..['ville'] = villeFilter(hub),))
        .data as List;
    return [...hubRows]..sort((a, b) => dist(a).compareTo(dist(b)));
  }

  /// Vrai si la ville a moins de [minResults] lieux pour [scope] (mis en
  /// cache pour la session ; une erreur réseau n'est pas mise en cache).
  static Future<bool> isPoorCity(
    Dio dio, {
    required String table,
    required String ville,
    required String Function(String ville) villeFilter,
    Map<String, String> scope = const {},
  }) {
    final key = '$table|${scope.entries.join(',')}|${ville.toLowerCase()}';
    return _poorCityCache.putIfAbsent(key, () async {
      try {
        final response = await dio.get(
          table,
          queryParameters: {
            'select': 'id',
            'is_active': 'eq.true',
            'ville': villeFilter(ville),
            ...scope,
          },
          options: Options(headers: {
            'Prefer': 'count=exact',
            'Range-Unit': 'items',
            'Range': '0-0',
          },),
        );
        final total =
            (response.headers.value('content-range') ?? '').split('/').last;
        return (int.tryParse(total) ?? 0) < minResults;
      } catch (_) {
        _poorCityCache.remove(key);
        return false;
      }
    });
  }
}
