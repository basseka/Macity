import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/features/sport/domain/models/football_match.dart';

class FootballApiService {
  final Dio _dio;

  FootballApiService({Dio? dio})
      : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.footballBaseUrl);
    dio.options.headers['X-Auth-Token'] = ApiConstants.footballApiToken;
    return dio;
  }

  /// Fetch matches for a team
  Future<List<FootballMatch>> fetchTeamMatches({
    required int teamId,
    String? status,
    String? dateFrom,
    String? dateTo,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        'v4/teams/$teamId/matches',
        queryParameters: {
          if (status != null) 'status': status,
          if (dateFrom != null) 'dateFrom': dateFrom,
          if (dateTo != null) 'dateTo': dateTo,
          'limit': limit,
        },
      );

      final matches = response.data['matches'] as List? ?? [];
      return matches
          .map((m) => FootballMatch.fromJson(m as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch football matches: ${e.message}');
    }
  }
}
