import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

class EventApiService {
  final Dio _dio;

  EventApiService({Dio? dio})
      : _dio = dio ?? DioClient.withBaseUrl(ApiConstants.toulouseBaseUrl);

  /// Fetch events from Toulouse OpenDataSoft API
  Future<List<Event>> fetchEvents({
    String? where,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.toulouseEventsEndpoint,
        queryParameters: {
          if (where != null) 'where': where,
          'order_by': 'date_debut ASC',
          'limit': limit,
          'offset': offset,
        },
      );

      final results = response.data['results'] as List? ?? [];
      return results.map((r) => Event.fromJson(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch events: ${e.message}');
    }
  }

  /// Fetch events for this week
  Future<List<Event>> fetchThisWeek() async {
    final now = DateTime.now();
    final endOfWeek = now.add(const Duration(days: 7));
    final dateFrom = _formatDate(now);
    final dateTo = _formatDate(endOfWeek);

    return fetchEvents(
      where: 'date_debut >= "$dateFrom" AND date_debut <= "$dateTo"',
    );
  }

  /// Fetch events by category/type
  Future<List<Event>> fetchByCategory(String category) async {
    return fetchEvents(
      where:
          'type_de_manifestation LIKE "%$category%" OR categorie_de_la_manifestation LIKE "%$category%"',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
