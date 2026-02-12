import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/features/day/domain/models/open_agenda_event.dart';

class OpenAgendaApiService {
  final Dio _dio;

  OpenAgendaApiService({Dio? dio})
      : _dio = dio ?? DioClient.withBaseUrl(ApiConstants.openAgendaBaseUrl);

  /// Fetch events from OpenAgenda (national, non-Toulouse)
  Future<List<OpenAgendaEvent>> fetchEvents({
    required String city,
    String? keyword,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final now = DateTime.now();
      final dateFrom = _formatDate(now);
      final dateTo = _formatDate(now.add(const Duration(days: 365)));

      String whereClause =
          'location_city="$city" AND firstdate_begin>="$dateFrom" AND lastdate_end<="$dateTo"';
      if (keyword != null && keyword.isNotEmpty) {
        whereClause += ' AND (title_fr LIKE "%$keyword%" OR keywords_fr LIKE "%$keyword%")';
      }

      final response = await _dio.get(
        'api/explore/v2.1/catalog/datasets/evenements-publics-openagenda/records',
        queryParameters: {
          'where': whereClause,
          'order_by': 'firstdate_begin ASC',
          'limit': limit,
          'offset': offset,
        },
      );

      final results = response.data['results'] as List? ?? [];
      return results
          .map((r) => OpenAgendaEvent.fromApiRecord(r as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch OpenAgenda events: ${e.message}');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
