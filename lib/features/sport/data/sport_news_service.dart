import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

/// Un mini-article d'actu sport, alimenté par la table `sport_news`
/// (reformulé par IA depuis des sources locales, ou édité depuis /admin.html).
class SportNews {
  final int id;
  final String ville;
  final String title;
  final String summary;
  final String sport; // rugby | football | basket | hand | autre
  final String sourceName;
  final String sourceUrl;
  final String imageUrl;

  const SportNews({
    required this.id,
    required this.ville,
    required this.title,
    required this.summary,
    required this.sport,
    required this.sourceName,
    required this.sourceUrl,
    required this.imageUrl,
  });

  /// Emoji par discipline, pour le badge.
  String get sportEmoji => switch (sport.toLowerCase()) {
        'rugby' => '🏉',
        'football' || 'foot' => '⚽',
        'basket' || 'basketball' => '🏀',
        'hand' || 'handball' => '🤾',
        _ => '🏅',
      };

  factory SportNews.fromJson(Map<String, dynamic> json) {
    return SportNews(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ville: json['ville'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      sport: json['sport'] as String? ?? '',
      sourceName: json['source_name'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}

/// Lit les mini-articles actifs pour une ville. Convention `ville = '*'` =
/// visible partout (comme `inspirations`).
class SportNewsService {
  final Dio _dio;

  SportNewsService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  Future<List<SportNews>> fetchSportNews({required String ville}) async {
    final response = await _dio.get(
      'sport_news',
      queryParameters: {
        'select': '*',
        'is_active': 'eq.true',
        'order': 'sort_order.asc,created_at.desc',
      },
    );
    final data = response.data as List;
    final v = ville.trim().toLowerCase();
    final result = <SportNews>[];
    for (final raw in data) {
      final json = raw as Map<String, dynamic>;
      final rowVille = (json['ville'] as String? ?? '*').trim();
      if (rowVille == '*' || rowVille.toLowerCase() == v) {
        result.add(SportNews.fromJson(json));
      }
    }
    return result;
  }
}

/// Mini-articles d'actu sport actifs dans la ville sélectionnée.
final sportNewsProvider = FutureProvider<List<SportNews>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return SportNewsService().fetchSportNews(ville: city);
});
