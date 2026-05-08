import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/engagement/domain/models/device_pseudonym.dart';
import 'package:pulz_app/features/engagement/domain/models/event_comment.dart';
import 'package:pulz_app/features/engagement/domain/models/event_engagement_totals.dart';

/// Lecture / écriture des compteurs et commentaires d'engagement (likes,
/// shares, comments) sur un event boosté. Mix de seed (fake) + real.
///
/// Tables/vues PostgREST :
///   - event_engagement_totals (vue agrégat)
///   - event_comments_unified  (vue fake + real)
///   - event_real_likes / event_real_shares / event_real_comments
///   - device_pseudonyms (via RPC assign_device_pseudonym)
class EventEngagementService {
  final Dio _dio;

  EventEngagementService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  // ---------------------------------------------------------------------------
  // Totaux (likes/shares/comments) — null si event pas boosté
  // ---------------------------------------------------------------------------
  /// Query par `event_identifiant` SEUL (sans filtrer event_source) — résistant
  /// au mismatch entre `admin_pins.event_source` (hint historique) et la vraie
  /// source de l'event en DB. Aggrège côté client si plusieurs sources matchent.
  Future<EventEngagementTotals?> getTotals({
    required String eventSource,
    required String eventIdentifiant,
  }) async {
    try {
      final response = await _dio.get(
        'event_engagement_totals',
        queryParameters: {
          'select': '*',
          'event_identifiant': 'eq.$eventIdentifiant',
        },
      );
      final data = response.data as List;
      if (data.isEmpty) return null;
      return _aggregate(eventSource, eventIdentifiant, data);
    } catch (e) {
      debugPrint('[Engagement] getTotals failed: $e');
      return null;
    }
  }

  /// Batch fetch pour une liste d'events (carrousels). Indexé par `<source>:<id>`
  /// avec la source attendue par l'appelant (clés détectées via UUID régex).
  Future<Map<String, EventEngagementTotals>> getTotalsBatch({
    required String eventSource,
    required List<String> eventIdentifiants,
  }) async {
    if (eventIdentifiants.isEmpty) return {};
    try {
      final ids = eventIdentifiants.map((e) => '"$e"').join(',');
      final response = await _dio.get(
        'event_engagement_totals',
        queryParameters: {
          'select': '*',
          'event_identifiant': 'in.($ids)',
        },
      );
      final data = response.data as List;
      // Group by event_identifiant (peut avoir plusieurs sources)
      final byId = <String, List<Map<String, dynamic>>>{};
      for (final raw in data) {
        final id = (raw as Map<String, dynamic>)['event_identifiant'] as String;
        byId.putIfAbsent(id, () => []).add(raw);
      }
      final map = <String, EventEngagementTotals>{};
      for (final id in eventIdentifiants) {
        final rows = byId[id];
        if (rows == null || rows.isEmpty) continue;
        final agg = _aggregate(eventSource, id, rows);
        if (agg != null) map['$eventSource:$id'] = agg;
      }
      return map;
    } catch (e) {
      debugPrint('[Engagement] getTotalsBatch failed: $e');
      return {};
    }
  }

  EventEngagementTotals? _aggregate(
    String expectedSource,
    String identifiant,
    List<dynamic> rows,
  ) {
    if (rows.isEmpty) return null;
    if (rows.length == 1) {
      final t = EventEngagementTotals.fromJson(rows.first as Map<String, dynamic>);
      // Force la source attendue (alignée avec le state map du provider)
      return EventEngagementTotals(
        eventSource: expectedSource,
        eventIdentifiant: t.eventIdentifiant,
        likesCount: t.likesCount,
        sharesCount: t.sharesCount,
        commentsCount: t.commentsCount,
        boostType: t.boostType,
        seededAt: t.seededAt,
      );
    }
    int likes = 0, shares = 0, comments = 0;
    String boostType = '';
    DateTime? seededAt;
    for (final r in rows) {
      final t = EventEngagementTotals.fromJson(r as Map<String, dynamic>);
      likes += t.likesCount;
      shares += t.sharesCount;
      comments += t.commentsCount;
      if (boostType.isEmpty) boostType = t.boostType;
      seededAt ??= t.seededAt;
    }
    return EventEngagementTotals(
      eventSource: expectedSource,
      eventIdentifiant: identifiant,
      likesCount: likes,
      sharesCount: shares,
      commentsCount: comments,
      boostType: boostType,
      seededAt: seededAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Commentaires (fake + real mergés) triés par date desc
  // ---------------------------------------------------------------------------
  Future<List<EventComment>> listComments({
    required String eventSource,
    required String eventIdentifiant,
  }) async {
    try {
      // Query par identifiant SEUL (résistant au mismatch source admin_pins).
      final response = await _dio.get(
        'event_comments_unified',
        queryParameters: {
          'select': '*',
          'event_identifiant': 'eq.$eventIdentifiant',
          'order': 'created_at.desc',
        },
      );
      final data = response.data as List;
      return data
          .map((e) => EventComment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Engagement] listComments failed: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Real likes (toggle 1 par device)
  // ---------------------------------------------------------------------------
  Future<bool> hasUserLiked({
    required String eventSource,
    required String eventIdentifiant,
    required String deviceUuid,
  }) async {
    try {
      final response = await _dio.get(
        'event_real_likes',
        queryParameters: {
          'select': 'event_source',
          'event_source': 'eq.$eventSource',
          'event_identifiant': 'eq.$eventIdentifiant',
          'device_uuid': 'eq.$deviceUuid',
          'limit': '1',
        },
      );
      return (response.data as List).isNotEmpty;
    } catch (e) {
      debugPrint('[Engagement] hasUserLiked failed: $e');
      return false;
    }
  }

  Future<void> addLike({
    required String eventSource,
    required String eventIdentifiant,
    required String deviceUuid,
  }) async {
    await _dio.post(
      'event_real_likes',
      data: {
        'event_source': eventSource,
        'event_identifiant': eventIdentifiant,
        'device_uuid': deviceUuid,
      },
      options: Options(
        headers: const {
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
      ),
    );
  }

  Future<void> removeLike({
    required String eventSource,
    required String eventIdentifiant,
    required String deviceUuid,
  }) async {
    await _dio.delete(
      'event_real_likes',
      queryParameters: {
        'event_source': 'eq.$eventSource',
        'event_identifiant': 'eq.$eventIdentifiant',
        'device_uuid': 'eq.$deviceUuid',
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Real shares (append-only)
  // ---------------------------------------------------------------------------
  Future<void> recordShare({
    required String eventSource,
    required String eventIdentifiant,
    required String deviceUuid,
  }) async {
    await _dio.post(
      'event_real_shares',
      data: {
        'event_source': eventSource,
        'event_identifiant': eventIdentifiant,
        'device_uuid': deviceUuid,
      },
      options: Options(
        headers: const {'Prefer': 'return=minimal'},
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Real comments (avec pseudo dénormalisé)
  // ---------------------------------------------------------------------------
  Future<EventComment?> postComment({
    required String eventSource,
    required String eventIdentifiant,
    required String deviceUuid,
    required String displayName,
    required String gender,
    String? avatarUrl,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      final response = await _dio.post(
        'event_real_comments',
        data: {
          'event_source': eventSource,
          'event_identifiant': eventIdentifiant,
          'device_uuid': deviceUuid,
          'display_name': displayName,
          'gender': gender,
          'avatar_url': avatarUrl,
          'comment_text': trimmed,
        },
        options: Options(
          headers: const {'Prefer': 'return=representation'},
        ),
      );
      final data = response.data as List;
      if (data.isEmpty) return null;
      // Adapter la réponse au shape de event_comments_unified
      final raw = data.first as Map<String, dynamic>;
      return EventComment(
        id: raw['id'] as String,
        eventSource: raw['event_source'] as String,
        eventIdentifiant: raw['event_identifiant'] as String,
        displayName: raw['display_name'] as String,
        gender: raw['gender'] as String,
        avatarUrl: raw['avatar_url'] as String?,
        text: raw['comment_text'] as String,
        createdAt: DateTime.parse(raw['created_at'] as String),
        isReal: true,
        deviceUuid: raw['device_uuid'] as String?,
      );
    } catch (e) {
      debugPrint('[Engagement] postComment failed: $e');
      return null;
    }
  }

  Future<void> deleteComment({
    required String commentId,
    required String deviceUuid,
  }) async {
    await _dio.delete(
      'event_real_comments',
      queryParameters: {
        'id': 'eq.$commentId',
        'device_uuid': 'eq.$deviceUuid',
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Pseudo du device courant (RPC assign_device_pseudonym, idempotent)
  // ---------------------------------------------------------------------------
  /// Propage le nouveau pseudo aux anciens commentaires du device (display
  /// dénormalisé dans event_real_comments).
  Future<void> updatePastCommentsPseudonym({
    required String deviceUuid,
    required String displayName,
    required String gender,
    String? avatarUrl,
  }) async {
    try {
      await _dio.patch(
        'event_real_comments',
        queryParameters: {'device_uuid': 'eq.$deviceUuid'},
        data: {
          'display_name': displayName,
          'gender': gender,
          'avatar_url': avatarUrl,
        },
        options: Options(
          headers: const {'Prefer': 'return=minimal'},
        ),
      );
    } catch (e) {
      debugPrint('[Engagement] updatePastCommentsPseudonym failed: $e');
    }
  }

  /// Met à jour le pseudo / genre / avatar d'un device existant.
  /// Idempotent : si la row n'existe pas encore, fait un upsert.
  Future<void> updatePseudonym({
    required String deviceUuid,
    required String displayName,
    required String gender,
    String? avatarUrl,
  }) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;
    await _dio.post(
      'device_pseudonyms',
      data: {
        'device_uuid': deviceUuid,
        'display_name': trimmed,
        'gender': gender,
        'avatar_url': avatarUrl,
      },
      options: Options(
        headers: const {
          'Prefer': 'resolution=merge-duplicates,return=minimal',
        },
      ),
    );
  }

  Future<DevicePseudonym?> getOrAssignPseudonym(String deviceUuid) async {
    try {
      final response = await _dio.post(
        'rpc/assign_device_pseudonym',
        data: {'p_device_uuid': deviceUuid},
      );
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        return DevicePseudonym.fromJson(raw);
      }
      if (raw is List && raw.isNotEmpty) {
        return DevicePseudonym.fromJson(raw.first as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[Engagement] getOrAssignPseudonym failed: $e');
      return null;
    }
  }
}
