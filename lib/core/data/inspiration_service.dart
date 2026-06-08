import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

/// Carte unique du carrousel "Inspirations du moment" d'une rubrique.
/// Alimentee par la table `inspirations` (editee depuis /admin.html).
class Inspiration {
  final int id;
  final String rubrique; // food | family | sport | culture | night
  final String title;
  final String description;
  final String photoUrl;
  final String siteUrl;

  /// Thème filtrable au tap (matche une chip de la rubrique si possible).
  /// Vide => le tap ouvre directement le site s'il y en a un.
  final String theme;

  const Inspiration({
    required this.id,
    required this.rubrique,
    required this.title,
    required this.description,
    required this.photoUrl,
    required this.siteUrl,
    required this.theme,
  });

  factory Inspiration.fromJson(Map<String, dynamic> json) {
    return Inspiration(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rubrique: json['rubrique'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      siteUrl: json['site_url'] as String? ?? '',
      theme: json['theme'] as String? ?? '',
    );
  }
}

/// Recupere les cartes actives pour une rubrique et une ville donnees.
/// Les lignes en `ville = '*'` s'affichent dans toutes les villes
/// (meme convention que `mode_banners`).
class InspirationService {
  final Dio _dio;

  InspirationService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  Future<List<Inspiration>> fetchInspirations({
    required String ville,
    required String rubrique,
  }) async {
    final response = await _dio.get(
      'inspirations',
      queryParameters: {
        'select': '*',
        'is_active': 'eq.true',
        'rubrique': 'eq.$rubrique',
        'order': 'sort_order.asc,id.asc',
      },
    );
    final data = response.data as List;
    final v = ville.trim().toLowerCase();
    final result = <Inspiration>[];
    for (final raw in data) {
      final json = raw as Map<String, dynamic>;
      final rowVille = (json['ville'] as String? ?? '*').trim();
      if (rowVille == '*' || rowVille.toLowerCase() == v) {
        result.add(Inspiration.fromJson(json));
      }
    }
    return result;
  }
}

/// Cartes Inspirations actives pour une rubrique donnee, dans la ville
/// selectionnee. Usage : `ref.watch(inspirationsProvider('food'))`.
final inspirationsProvider =
    FutureProvider.family<List<Inspiration>, String>((ref, rubrique) async {
  final city = ref.watch(selectedCityProvider);
  return InspirationService().fetchInspirations(ville: city, rubrique: rubrique);
});
