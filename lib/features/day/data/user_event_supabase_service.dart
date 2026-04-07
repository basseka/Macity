import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
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

  /// Compresse une image avant upload : JPEG 75%, max 1024px.
  Future<Uint8List> _compressImage(String path) async {
    final result = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: 1024,
      minHeight: 1024,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    if (result != null) return result;
    // Fallback : bytes bruts si compression echoue
    return File(path).readAsBytes();
  }

  /// Upload une photo locale vers Supabase Storage (compressee).
  /// Retourne l'URL publique de l'image.
  Future<String> uploadPhoto(String localPath) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${ts}_photo.jpg';

    // Compresser avant upload
    final bytes = await _compressImage(localPath);
    debugPrint('[Upload] photo compressed: ${bytes.length ~/ 1024} KB');

    await _storageDio.post(
      'object/user-events/$fileName',
      data: bytes,
      options: Options(
        headers: {'Content-Type': 'image/jpeg'},
      ),
    );

    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/user-events/$fileName';
  }

  /// Upload une video locale vers Supabase Storage (compressee, max 3 MB).
  /// Retourne l'URL publique de la video.
  Future<String> uploadVideo(String localPath) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${ts}_video.mp4';

    // Compresser la video (qualite medium)
    Uint8List bytes;
    try {
      final info = await VideoCompress.compressVideo(
        localPath,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
      );
      if (info?.file != null) {
        bytes = await info!.file!.readAsBytes();
        debugPrint('[Upload] video compressed: ${bytes.length ~/ 1024} KB');
      } else {
        bytes = await File(localPath).readAsBytes();
      }
    } catch (e) {
      debugPrint('[Upload] video compress failed: $e');
      bytes = await File(localPath).readAsBytes();
    }

    await _storageDio.post(
      'object/user-events/$fileName',
      data: bytes,
      options: Options(
        headers: {'Content-Type': 'video/mp4'},
      ),
    );

    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/user-events/$fileName';
  }

  /// Genere une thumbnail de la video.
  Future<String?> getVideoThumbnail(String videoPath) async {
    try {
      final thumb = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 60,
        position: 0,
      );
      return thumb.path;
    } catch (_) {
      return null;
    }
  }

  /// Upload multiple photos (gallery). Returns list of public URLs.
  Future<List<String>> uploadGallery(List<String> localPaths) async {
    final urls = <String>[];
    for (final path in localPaths) {
      final url = await uploadPhoto(path);
      urls.add(url);
    }
    return urls;
  }

  // ───────────────────────────────────────────
  // CRUD PostgREST : table `user_events`
  // ───────────────────────────────────────────

  /// Insère un événement utilisateur (avec user_id pour les notifications).
  /// Si [establishmentId] est fourni, insère aussi dans establishment_events
  /// pour déclencher les notifications aux likers.
  Future<void> insertEvent(
    UserEvent event, {
    String? establishmentId,
  }) async {
    final userId = await UserIdentityService.getUserId();
    await _restDio.post(
      'user_events',
      data: event.toSupabaseJson(userId: userId),
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );

    if (establishmentId != null) {
      await insertEstablishmentEvent(
        establishmentId: establishmentId,
        title: event.titre,
        date: event.date,
        heure: event.heure,
        description: event.description,
        city: event.ville,
        photoUrl: event.photoUrl,
      );
    }
  }

  /// Insère dans establishment_events pour notifier les likers du lieu.
  Future<void> insertEstablishmentEvent({
    required String establishmentId,
    required String title,
    required String date,
    required String heure,
    String description = '',
    String? city,
    String? photoUrl,
  }) async {
    final time = heure.isNotEmpty ? heure : '00:00';
    final startsAt = '${date}T$time:00+02:00';

    await _restDio.post(
      'establishment_events',
      data: {
        'establishment_id': establishmentId,
        'title': title,
        'starts_at': startsAt,
        'description': description,
        if (city != null) 'city': city,
        if (photoUrl != null) 'photo_url': photoUrl,
      },
      options: Options(
        headers: {'Prefer': 'return=minimal'},
      ),
    );
  }

  /// Récupère tous les événements utilisateur (futurs uniquement).
  Future<List<UserEvent>> fetchEvents() async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final response = await _restDio.get(
      'user_events',
      queryParameters: {
        'select': '*',
        'date': 'gte.$today',
        'order': 'date.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => UserEvent.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Recupere uniquement les evenements crees par l'utilisateur courant.
  Future<List<UserEvent>> fetchMyEvents() async {
    final userId = await UserIdentityService.getUserId();
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final response = await _restDio.get(
      'user_events',
      queryParameters: {
        'select': '*',
        'user_id': 'eq.$userId',
        'date': 'gte.$today',
        'order': 'date.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => UserEvent.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les événements d'une ville (futurs uniquement).
  Future<List<UserEvent>> fetchEventsByCity(String ville) async {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final response = await _restDio.get(
      'user_events',
      queryParameters: {
        'select': '*',
        'ville': 'eq.$ville',
        'date': 'gte.$today',
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

  /// Search user events by title, description, lieu, category, or city.
  Future<List<UserEvent>> searchEvents(String query, {int limit = 15}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await _restDio.get(
      'user_events',
      queryParameters: <String, String>{
        'select': '*',
        'or':
            '(titre.ilike.*$query*,description.ilike.*$query*,lieu_nom.ilike.*$query*,categorie.ilike.*$query*,ville.ilike.*$query*)',
        'date': 'gte.$today',
        'order': 'date.asc',
        'limit': '$limit',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => UserEvent.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Supprime les événements expirés de l'utilisateur courant uniquement.
  Future<void> deleteExpiredEvents() async {
    final userId = await UserIdentityService.getUserId();
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _restDio.delete(
      'user_events',
      queryParameters: {
        'date': 'lt.$today',
        'user_id': 'eq.$userId',
      },
    );
  }
}
