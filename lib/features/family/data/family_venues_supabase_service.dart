import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/data/nearby_rows.dart';
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

  static String _villeFilter(String ville) => 'ilike.$ville';

  /// Lignes de la ville, completees par les lieux proches si la ville a peu
  /// de lieux famille (voir [NearbyRows]). Toulouse (85 lieux) n'est pas
  /// concernee.
  Future<List<dynamic>> _rowsWithNearby(
    Map<String, String> params,
    String ville,
  ) =>
      NearbyRows.fetch(_dio,
          table: 'family_venues',
          params: params,
          ville: ville,
          villeFilter: _villeFilter,);

  Future<bool> _isPoorCity(String ville) => NearbyRows.isPoorCity(_dio,
      table: 'family_venues', ville: ville, villeFilter: _villeFilter,);

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
