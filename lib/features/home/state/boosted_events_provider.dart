import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

Future<int> _getConfigInt(String key, int defaultValue) async {
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    final response = await dio.get('app_config', queryParameters: {
      'select': 'value',
      'key': 'eq.$key',
      'limit': '1',
    });
    final data = response.data as List;
    if (data.isNotEmpty) {
      return int.tryParse(data.first['value'] as String) ?? defaultValue;
    }
  } catch (_) {}
  return defaultValue;
}

Future<List<UserEvent>> _fetchByPriority(String city, String priority, int limit) async {
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());

    final response = await dio.get(
      'user_events',
      queryParameters: {
        'select': '*',
        'priority': 'eq.$priority',
        'date': 'gte.${_today()}',
        'ville': 'ilike.$city',
        'order': 'date.asc',
        'limit': '$limit',
      },
    );

    final data = response.data as List;
    return data.map((e) => UserEvent.fromSupabaseJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint('[BoostedEvents] error fetching $priority: $e');
    return [];
  }
}

/// Events boostés P1 pour la ville sélectionnée (max depuis app_config).
final boostedEventsProvider = FutureProvider<List<UserEvent>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final max = await _getConfigInt('boosted_p1_max', 4);
  return _fetchByPriority(city, 'P1', max);
});

/// Events boostés P2 pour la ville sélectionnée (max depuis app_config).
final boostedP2EventsProvider = FutureProvider<List<UserEvent>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final max = await _getConfigInt('boosted_p2_max', 6);
  return _fetchByPriority(city, 'P2', max);
});
