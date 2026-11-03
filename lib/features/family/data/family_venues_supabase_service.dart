import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/features/city/data/city_coordinates.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';

/// Service qui lit les venues famille depuis la table `family_venues` de Supabase.
class FamilyVenuesSupabaseService {
  final Dio _dio;

  FamilyVenuesSupabaseService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch all active venues, optionally filtered by [category] and [ville].
  /// [withNearby] : si la ville a peu de lieux famille, complete par les
  /// plus proches (voir [_rowsWithNearby]).
  Future<List<FamilyVenue>> fetchVenues({
    String? category,
    required String ville,
    bool withNearby = false,
  }) async {
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'ville': 'ilike.$ville',
      'order': 'display_priority.desc,name.asc',
    };
    if (category != null) {
      params['category'] = 'eq.$category';
    }

    final data = withNearby
        ? await _rowsWithNearby(params, ville)
        : (await _dio.get('family_venues', queryParameters: params)).data
            as List;
    return data
        .map((e) => FamilyVenue.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// En dessous de ce nombre de lieux famille dans la ville, ses listes sont
  /// completees par les lieux les plus proches (meme regle que Night et
  /// Culture). Toulouse (85 lieux) n'est pas concernee.
  static const nearbyMinResults = 20;

  /// Rayons successifs (km) autour du centre de la zone, plafond 50 km.
  static const nearbyRadiiKm = [10.0, 25.0, 50.0];

  static final Map<String, Future<bool>> _poorCityCache = {};

  Future<bool> _isPoorCity(String ville) {
    final key = ville.toLowerCase();
    return _poorCityCache.putIfAbsent(key, () async {
      try {
        final response = await _dio.get(
          'family_venues',
          queryParameters: {
            'select': 'id',
            'is_active': 'eq.true',
            'ville': 'ilike.$ville',
          },
          options: Options(headers: {
            'Prefer': 'count=exact',
            'Range-Unit': 'items',
            'Range': '0-0',
          },),
        );
        final total = (response.headers.value('content-range') ?? '')
            .split('/')
            .last;
        return (int.tryParse(total) ?? 0) < nearbyMinResults;
      } catch (_) {
        _poorCityCache.remove(key);
        return false;
      }
    });
  }

  /// Lignes de la ville ; si la ville est pauvre et la requete renvoie moins
  /// de [nearbyMinResults] lignes, ajoute les lieux les plus proches du
  /// centre de la zone (memes filtres, sans la ville), du plus proche au plus
  /// lointain. Commune sans rien a 50 km : lieux de son hub.
  Future<List<dynamic>> _rowsWithNearby(
    Map<String, String> params,
    String ville,
  ) async {
    final local =
        (await _dio.get('family_venues', queryParameters: params)).data
            as List;
    final center = CityCoordinates.maybeOf(ville);
    if (center == null || local.length >= nearbyMinResults) return local;
    if (!await _isPoorCity(ville)) return local;

    double dist(dynamic r) {
      final m = r as Map<String, dynamic>;
      final lat = (m['latitude'] as num?)?.toDouble();
      final lng = (m['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return double.infinity;
      return Haversine.km(center.lat, center.lng, lat, lng);
    }

    final seen = local.map((e) => (e as Map<String, dynamic>)['id']).toSet();
    var extras = <dynamic>[];
    for (final radius in nearbyRadiiKm) {
      final around = Map<String, String>.of(params)
        ..remove('ville')
        ..['and'] = Haversine.bboxFilter(center.lat, center.lng, radius);
      final rows = (await _dio.get('family_venues', queryParameters: around))
          .data as List;
      extras = rows
          .where((r) =>
              !seen.contains((r as Map<String, dynamic>)['id']) &&
              dist(r) <= radius,)
          .toList();
      if (local.length + extras.length >= nearbyMinResults) break;
    }
    extras.sort((a, b) => dist(a).compareTo(dist(b)));
    final result = [...local, ...extras];
    if (result.isNotEmpty) return result;

    final hub = CityCoordinates.hubOf(ville);
    if (hub == null || hub.toLowerCase() == ville.toLowerCase()) return result;
    final hubRows = (await _dio.get('family_venues',
            queryParameters: Map<String, String>.of(params)
              ..['ville'] = 'ilike.$hub',))
        .data as List;
    return [...hubRows]..sort((a, b) => dist(a).compareTo(dist(b)));
  }

  /// Fetch les venues de PLUSIEURS categories (types) d'un coup — utilise pour
  /// afficher une rubrique entiere (ex: "Divertissements" = Cinema + Bowling +
  /// Laser game + …). Filtre `category=in.(...)`.
  Future<List<FamilyVenue>> fetchVenuesByCategories(
    List<String> categories, {
    required String ville,
    bool withNearby = false,
  }) async {
    if (categories.isEmpty) return [];
    // PostgREST in.() : valeurs entre guillemets (espaces/apostrophes).
    final list = categories.map((c) => '"${c.replaceAll('"', '')}"').join(',');
    final params = <String, String>{
      'select': '*',
      'is_active': 'eq.true',
      'ville': 'ilike.$ville',
      'category': 'in.($list)',
      'order': 'display_priority.desc,name.asc',
    };
    final data = withNearby
        ? await _rowsWithNearby(params, ville)
        : (await _dio.get('family_venues', queryParameters: params)).data
            as List;
    return data
        .map((e) => FamilyVenue.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Count active venues per category, filtered by [ville].
  Future<int> countByCategory(
    String category, {
    required String ville,
    bool withNearby = false,
  }) async {
    // Ville pauvre : le compte inclut les lieux proches ajoutes aux listes.
    if (withNearby &&
        CityCoordinates.maybeOf(ville) != null &&
        await _isPoorCity(ville)) {
      final list = await fetchVenues(
        category: category, ville: ville, withNearby: true,
      );
      return list.length;
    }
    final response = await _dio.get(
      'family_venues',
      queryParameters: {
        'select': 'id',
        'is_active': 'eq.true',
        'category': 'eq.$category',
        'ville': 'ilike.$ville',
      },
      options: Options(headers: {'Prefer': 'count=exact'}),
    );
    final count = response.headers.value('content-range');
    if (count != null) {
      final parts = count.split('/');
      if (parts.length == 2 && parts[1] != '*') {
        return int.tryParse(parts[1]) ?? 0;
      }
    }
    return (response.data as List).length;
  }

  /// Get distinct group names for a category (for section headers).
  Future<List<String>> fetchGroupsForCategory(String category, {required String ville}) async {
    final venues = await fetchVenues(category: category, ville: ville);
    final groups = <String>[];
    for (final v in venues) {
      if (v.groupe.isNotEmpty && !groups.contains(v.groupe)) {
        groups.add(v.groupe);
      }
    }
    return groups;
  }
}
