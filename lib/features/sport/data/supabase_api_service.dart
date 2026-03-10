import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/sport/domain/models/league.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';
import 'package:pulz_app/features/sport/domain/models/team.dart';

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

  /// Fetch leagues for a sport.
  Future<List<League>> fetchLeagues({required String sport}) async {
    try {
      final response = await _dio.get('leagues', queryParameters: {
        'select': '*,sports!inner(name)',
        'sports.name': 'eq.$sport',
        'is_active': 'eq.true',
        'order': 'level.asc',
      });
      final data = response.data as List;
      return data.map((e) => League.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch leagues: ${e.message}');
    }
  }

  /// Fetch teams, optionally filtered by league.
  Future<List<Team>> fetchTeams({int? leagueId}) async {
    try {
      final params = <String, String>{
        'select': '*',
        'is_active': 'eq.true',
        'order': 'name.asc',
      };
      if (leagueId != null) params['league_id'] = 'eq.$leagueId';
      final response = await _dio.get('teams', queryParameters: params);
      final data = response.data as List;
      return data.map((e) => Team.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch teams: ${e.message}');
    }
  }

  /// Search matches by team name, sport, competition, or venue.
  Future<List<SupabaseMatch>> searchMatches(String query,
      {int limit = 15}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    try {
      final response = await _dio.get(
        'matchs',
        queryParameters: <String, String>{
          'select': '*',
          'or':
              '(equipe_dom.ilike.*$query*,equipe_ext.ilike.*$query*,sport.ilike.*$query*,competition.ilike.*$query*,lieu.ilike.*$query*)',
          'date': 'gte.$today',
          'order': 'date.asc',
          'limit': '$limit',
        },
      );
      final data = response.data as List;
      return data
          .map((e) => SupabaseMatch.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to search Supabase matches: ${e.message}');
    }
  }
}
