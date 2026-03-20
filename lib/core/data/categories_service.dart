import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/domain/models/app_category.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

/// Service qui lit les catégories depuis la table `categories` de Supabase.
class CategoriesService {
  final Dio _dio;

  CategoriesService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch les catégories actives pour un mode, filtrées par ville.
  /// Retourne les catégories globales (ville=null) + celles de la ville.
  Future<List<AppCategory>> fetchCategories({
    required String mode,
    required String ville,
  }) async {
    final response = await _dio.get(
      'categories',
      queryParameters: {
        'select': '*',
        'mode': 'eq.$mode',
        'is_active': 'eq.true',
        'or': '(ville.is.null,ville.ilike.$ville)',
        'order': 'groupe_ordre.asc,ordre.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => AppCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch toutes les catégories actives (tous modes) pour une ville.
  Future<List<AppCategory>> fetchAllCategories({required String ville}) async {
    final response = await _dio.get(
      'categories',
      queryParameters: {
        'select': '*',
        'is_active': 'eq.true',
        'or': '(ville.is.null,ville.ilike.$ville)',
        'order': 'mode.asc,groupe_ordre.asc,ordre.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => AppCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Groupe les catégories par groupe pour affichage hub.
  static List<AppCategoryGroup> groupCategories(List<AppCategory> categories) {
    final Map<String, List<AppCategory>> grouped = {};
    for (final cat in categories) {
      final key = cat.groupe.isEmpty ? '_root' : cat.groupe;
      grouped.putIfAbsent(key, () => []).add(cat);
    }

    return grouped.entries.map((entry) {
      final cats = entry.value;
      final first = cats.first;
      return AppCategoryGroup(
        name: first.groupe,
        emoji: first.groupeEmoji,
        ordre: first.groupeOrdre,
        categories: cats,
      );
    }).toList()
      ..sort((a, b) => a.ordre.compareTo(b.ordre));
  }
}
