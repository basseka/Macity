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

Future<List<UserEvent>> _fetchByPriority(String city, String priority) async {
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
      },
    );

    final data = response.data as List;
    return data.map((e) => UserEvent.fromSupabaseJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint('[BoostedEvents] error fetching $priority: $e');
    return [];
  }
}

/// Events boostés P1 pour la ville sélectionnée.
final boostedEventsProvider = FutureProvider<List<UserEvent>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return _fetchByPriority(city, 'P1');
});

/// Events boostés P2 pour la ville sélectionnée.
final boostedP2EventsProvider = FutureProvider<List<UserEvent>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return _fetchByPriority(city, 'P2');
});
