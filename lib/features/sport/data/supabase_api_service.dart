import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

class SupabaseApiService {
  final Dio _dio;

  SupabaseApiService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch matches from Supabase PostgREST
  Future<List<SupabaseMatch>> fetchMatches({
    String? sport,
    String? ville,
    String? dateGte,
    String? dateLt,
  }) async {
    try {
      final queryParams = <String, String>{
        'select': '*',
      };
      if (sport != null) queryParams['sport'] = 'eq.$sport';
      if (ville != null) queryParams['ville'] = 'eq.$ville';
      if (dateGte != null && dateLt != null) {
        // Range filter: date >= start AND date < end
        queryParams['and'] = '(date.gte.$dateGte,date.lt.$dateLt)';
      } else if (dateGte != null) {
        queryParams['date'] = 'gte.$dateGte';
      }

      final response = await _dio.get('matchs', queryParameters: queryParams);
      final data = response.data as List;
      return data
          .map((e) => SupabaseMatch.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch Supabase matches: ${e.message}');
    }
  }
}
