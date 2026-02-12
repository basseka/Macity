import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/features/sport/domain/models/espn_rugby_event.dart';

class EspnRugbyApiService {
  final Dio _dio;

  EspnRugbyApiService({Dio? dio})
      : _dio = dio ?? DioClient.withBaseUrl(ApiConstants.espnBaseUrl);

  /// Fetch rugby events from ESPN
  Future<List<EspnRugbyEvent>> fetchLeagueEvents({
    required int leagueId,
    String? dates,
  }) async {
    try {
      final response = await _dio.get(
        'apis/site/v2/sports/rugby/leagues/$leagueId/events',
        queryParameters: {
          if (dates != null) 'dates': dates,
        },
      );

      final events = response.data['events'] as List? ?? [];
      return events
          .map((e) => EspnRugbyEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch ESPN rugby events: ${e.message}');
    }
  }

  /// Fetch matches for a specific team
  Future<List<EspnRugbyEvent>> fetchTeamEvents({
    required int teamId,
  }) async {
    try {
      final response = await _dio.get(
        'apis/site/v2/sports/rugby/teams/$teamId/schedule',
      );

      final events = response.data['events'] as List? ?? [];
      return events
          .map((e) => EspnRugbyEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch ESPN team events: ${e.message}');
    }
  }
}
