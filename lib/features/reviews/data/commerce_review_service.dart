import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/reviews/domain/models/commerce_review.dart';

/// CRUD avis commerces sur la table `commerce_reviews` (PostgREST).
///
/// MVP permissif : INSERT / UPDATE / DELETE en anon, le client filtre lui-meme
/// sur device_uuid en WHERE. Voir migration pour les details du trade-off.
class CommerceReviewService {
  final Dio _dio;

  CommerceReviewService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Liste des avis pour une cible (real + fake mélangés via la vue
  /// `commerce_reviews_unified`), du plus récent au plus ancien.
  Future<List<UnifiedCommerceReview>> listForTarget({
    required String targetKind,
    required int targetId,
  }) async {
    try {
      final response = await _dio.get(
        'commerce_reviews_unified',
        queryParameters: {
          'select': '*',
          'target_kind': 'eq.$targetKind',
          'target_id': 'eq.$targetId',
          'order': 'created_at.desc',
        },
      );
      final data = response.data as List;
      return data
          .map((e) => UnifiedCommerceReview.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[CommerceReview] listForTarget failed: $e');
      return [];
    }
  }

  /// Aggregat (count + moyenne) pour une cible. Null si pas d'avis.
  Future<CommerceReviewSummary?> summaryForTarget({
    required String targetKind,
    required int targetId,
  }) async {
    try {
      final response = await _dio.get(
        'commerce_review_summary',
        queryParameters: {
          'select': '*',
          'target_kind': 'eq.$targetKind',
          'target_id': 'eq.$targetId',
          'limit': '1',
        },
      );
      final data = response.data as List;
      if (data.isEmpty) return null;
      return CommerceReviewSummary.fromJson(data.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[CommerceReview] summaryForTarget failed: $e');
      return null;
    }
  }

  /// Fetch batch summaries pour une liste de cibles (pour la pastille card).
  /// Indexe par "<kind>:<id>" pour lookup O(1) cote caller.
  Future<Map<String, CommerceReviewSummary>> summariesBatch({
    required String targetKind,
    required List<int> targetIds,
  }) async {
    if (targetIds.isEmpty) return {};
    try {
      // PostgREST : `target_id=in.(1,2,3)` filter
      final idsList = targetIds.join(',');
      final response = await _dio.get(
        'commerce_review_summary',
        queryParameters: {
          'select': '*',
          'target_kind': 'eq.$targetKind',
          'target_id': 'in.($idsList)',
        },
      );
      final data = response.data as List;
      final map = <String, CommerceReviewSummary>{};
      for (final raw in data) {
        final s = CommerceReviewSummary.fromJson(raw as Map<String, dynamic>);
        map['${s.targetKind}:${s.targetId}'] = s;
      }
      return map;
    } catch (e) {
      debugPrint('[CommerceReview] summariesBatch failed: $e');
      return {};
    }
  }

  /// Recupere l'avis du device courant pour une cible (s'il existe).
  Future<CommerceReview?> getMyReview({
    required String targetKind,
    required int targetId,
    required String deviceUuid,
  }) async {
    try {
      final response = await _dio.get(
        'commerce_reviews',
        queryParameters: {
          'select': '*',
          'target_kind': 'eq.$targetKind',
          'target_id': 'eq.$targetId',
          'device_uuid': 'eq.$deviceUuid',
          'limit': '1',
        },
      );
      final data = response.data as List;
      if (data.isEmpty) return null;
      return CommerceReview.fromJson(data.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[CommerceReview] getMyReview failed: $e');
      return null;
    }
  }

  /// Cree ou met a jour l'avis du device pour une cible (upsert sur la
  /// contrainte UNIQUE target_kind+target_id+device_uuid).
  Future<void> upsertReview({
    required String targetKind,
    required int targetId,
    required String deviceUuid,
    required int rating,
    required String comment,
  }) async {
    assert(rating >= 1 && rating <= 5, 'rating must be 1..5');
    await _dio.post(
      'commerce_reviews',
      data: {
        'target_kind': targetKind,
        'target_id': targetId,
        'device_uuid': deviceUuid,
        'rating': rating,
        'comment': comment,
      },
      options: Options(
        headers: const {
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
      ),
    );
  }

  /// Supprime l'avis du device pour une cible.
  Future<void> deleteMyReview({
    required String targetKind,
    required int targetId,
    required String deviceUuid,
  }) async {
    await _dio.delete(
      'commerce_reviews',
      queryParameters: {
        'target_kind': 'eq.$targetKind',
        'target_id': 'eq.$targetId',
        'device_uuid': 'eq.$deviceUuid',
      },
    );
  }
}
