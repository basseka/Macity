import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/evasion/domain/evasion_venue.dart';

/// Lit les lieux d'évasion depuis la table `evasion_venues` de Supabase.
class EvasionVenuesService {
  final Dio _dio;

  EvasionVenuesService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Domaines rattachés à la ville hub [ville] (colonne `hub_ville`).
  Future<List<EvasionVenue>> fetchVenues({required String ville}) async {
    final response = await _dio.get(
      'evasion_venues',
      queryParameters: {
        'select': '*',
        'is_active': 'eq.true',
        'hub_ville': 'ilike.$ville',
        'order': 'display_priority.desc,nom.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => EvasionVenue.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
