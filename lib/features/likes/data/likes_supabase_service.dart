import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';

/// Synchronise les likes avec Supabase (table establishment_likes).
/// Les triggers Postgres se chargent de creer/annuler les notifications.
class LikesSupabaseService {
  final Dio _dio;

  LikesSupabaseService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Recupere les IDs liked depuis Supabase.
  Future<Set<String>> fetchLikedIds() async {
    final userId = await UserIdentityService.getUserId();
    final response = await _dio.get(
      'establishment_likes',
      queryParameters: {
        'user_id': 'eq.$userId',
        'select': 'establishment_id',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => (e as Map<String, dynamic>)['establishment_id'] as String)
        .toSet();
  }

  /// Ajoute un like.
  Future<void> addLike(String establishmentId) async {
    final userId = await UserIdentityService.getUserId();
    await _dio.post(
      'establishment_likes',
      data: {
        'user_id': userId,
        'establishment_id': establishmentId,
      },
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );
  }

  /// Supprime un like.
  Future<void> removeLike(String establishmentId) async {
    final userId = await UserIdentityService.getUserId();
    await _dio.delete(
      'establishment_likes',
      queryParameters: {
        'user_id': 'eq.$userId',
        'establishment_id': 'eq.$establishmentId',
      },
    );
  }

  /// Sync un ensemble de likes locaux vers Supabase (migration initiale).
  Future<void> syncLocalLikes(Set<String> localIds) async {
    final remoteIds = await fetchLikedIds();

    // Ajouter ceux qui manquent cote serveur
    final toAdd = localIds.difference(remoteIds);
    for (final id in toAdd) {
      try {
        await addLike(id);
      } catch (e) {
        debugPrint('[Likes] sync addLike failed for $id: $e');
      }
    }
  }
}
