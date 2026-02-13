import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';

/// Service Supabase pour les événements utilisateur.
///
/// Table PostgREST : `user_events`
/// Bucket Storage  : `user-events`
class UserEventSupabaseService {
  final Dio _restDio;
  final Dio _storageDio;

  UserEventSupabaseService({Dio? restDio, Dio? storageDio})
      : _restDio = restDio ?? _createRestDio(),
        _storageDio = storageDio ?? _createStorageDio();

  static Dio _createRestDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  static Dio _createStorageDio() {
    final dio = DioClient.withBaseUrl(
      '${SupabaseConfig.supabaseUrl}/storage/v1/',
    );
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  // ───────────────────────────────────────────
  // Storage : upload photo
  // ───────────────────────────────────────────

  /// Upload une photo locale vers Supabase Storage.
  /// Retourne l'URL publique de l'image.
  Future<String> uploadPhoto(String localPath) async {
    final file = File(localPath);
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${localPath.split('/').last}';

    final bytes = await file.readAsBytes();

    // Déterminer le content-type
    final ext = localPath.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    await _storageDio.post(
      'object/user-events/$fileName',
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': contentType,
        },
      ),
    );

    // URL publique
    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/user-events/$fileName';
  }

  // ───────────────────────────────────────────
  // CRUD PostgREST : table `user_events`
  // ───────────────────────────────────────────

  /// Insère un événement utilisateur (avec user_id pour les notifications).
  Future<void> insertEvent(UserEvent event) async {
    final userId = await UserIdentityService.getUserId();
    await _restDio.post(
      'user_events',
      data: event.toSupabaseJson(userId: userId),
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );
  }

  /// Récupère tous les événements utilisateur.
  Future<List<UserEvent>> fetchEvents() async {
    final response = await _restDio.get(
      'user_events',
      queryParameters: {
        'select': '*',
        'order': 'date.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => UserEvent.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les événements d'une ville.
  Future<List<UserEvent>> fetchEventsByCity(String ville) async {
    final response = await _restDio.get(
      'user_events',
      queryParameters: {
        'select': '*',
        'ville': 'eq.$ville',
        'order': 'date.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => UserEvent.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Supprime un événement par son id.
  Future<void> deleteEvent(String id) async {
    await _restDio.delete(
      'user_events',
      queryParameters: {'id': 'eq.$id'},
    );
  }

  /// Supprime tous les événements dont la date est passée.
  Future<void> deleteExpiredEvents() async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _restDio.delete(
      'user_events',
      queryParameters: {'date': 'lt.$today'},
    );
  }
}
