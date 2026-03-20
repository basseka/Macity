import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/likes/data/likes_repository.dart';

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

  /// Recupere les likes depuis Supabase (IDs + metadata).
  Future<Map<String, LikeMetadata>> fetchLikes() async {
    final userId = await UserIdentityService.getUserId();
    final response = await _dio.get(
      'establishment_likes',
      queryParameters: {
        'user_id': 'eq.$userId',
        'select': 'establishment_id,metadata',
      },
    );
    final data = response.data as List;
    final result = <String, LikeMetadata>{};
    for (final row in data) {
      final map = row as Map<String, dynamic>;
      final id = map['establishment_id'] as String;
      final meta = map['metadata'] as Map<String, dynamic>?;
      result[id] = meta != null && meta.isNotEmpty
          ? LikeMetadata.fromJson(meta)
          : const LikeMetadata(title: '');
    }
    return result;
  }

  /// Recupere uniquement les IDs liked depuis Supabase.
  Future<Set<String>> fetchLikedIds() async {
    final likes = await fetchLikes();
    return likes.keys.toSet();
  }

  /// Ajoute un like avec metadata optionnelle.
  Future<void> addLike(String establishmentId, {LikeMetadata? meta}) async {
    final userId = await UserIdentityService.getUserId();
    await _dio.post(
      'establishment_likes',
      data: {
        'user_id': userId,
        'establishment_id': establishmentId,
        if (meta != null) 'metadata': meta.toJson(),
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

  /// Sync bidirectionnel : merge local + remote.
  /// Retourne l'ensemble fusionne (IDs + metadata).
  Future<Map<String, LikeMetadata>> syncBidirectional({
    required Set<String> localIds,
    required Map<String, LikeMetadata> localMeta,
  }) async {
    final remoteLikes = await fetchLikes();
    final remoteIds = remoteLikes.keys.toSet();

    // Likes presents en local mais pas sur Supabase → push
    final toAdd = localIds.difference(remoteIds);
    for (final id in toAdd) {
      try {
        await addLike(id, meta: localMeta[id]);
      } catch (e) {
        debugPrint('[Likes] sync push failed for $id: $e');
      }
    }

    // Fusionner : local + remote
    final merged = <String, LikeMetadata>{};
    // Remote d'abord
    for (final entry in remoteLikes.entries) {
      merged[entry.key] = entry.value;
    }
    // Local ecrase si metadata plus riche
    for (final id in localIds) {
      final local = localMeta[id];
      if (local != null && local.title.isNotEmpty) {
        merged[id] = local;
      } else if (!merged.containsKey(id)) {
        merged[id] = local ?? const LikeMetadata(title: '');
      }
    }

    return merged;
  }

  /// Ancien sync unidirectionnel (conserve pour compatibilite).
  Future<void> syncLocalLikes(Set<String> localIds) async {
    final remoteIds = await fetchLikedIds();
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
