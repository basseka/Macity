import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';

/// Service Supabase pour les signalements communautaires (style Waze).
///
/// Table PostgREST  : `reported_events`
/// Edge function    : `generate-event-poster` (Claude Haiku)
class ReportedEventsService {
  final Dio _restDio;
  final Dio _functionsDio;
  final Dio _storageDio;
  // ignore: unused_field
  final UserEventSupabaseService _uploadService;

  ReportedEventsService({
    Dio? restDio,
    Dio? functionsDio,
    Dio? storageDio,
    UserEventSupabaseService? uploadService,
  })  : _restDio = restDio ?? _createRestDio(),
        _functionsDio = functionsDio ?? _createFunctionsDio(),
        _storageDio = storageDio ?? _createStorageDio(),
        _uploadService = uploadService ?? UserEventSupabaseService();

  static Dio _createRestDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  static Dio _createFunctionsDio() {
    final dio = DioClient.withBaseUrl('${SupabaseConfig.supabaseUrl}/functions/v1/');
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

  /// Upload "light" : 100% async, sans bloquer le main thread.
  /// Strategie anti-ANR :
  ///   - aucun call sync (existsSync, readAsBytesSync)
  ///   - hard timeout 12s sur l'upload
  ///   - yields entre les operations pour laisser le UI thread respirer
  ///   - try/catch global, retourne null si echec
  Future<String?> _uploadPhotoLight(String localPath) async {
    try {
      // Yield au scheduler avant de toucher au file system
      await Future<void>.delayed(Duration.zero);

      final file = File(localPath);
      // Async exists, pas existsSync qui bloque
      if (!await file.exists()) {
        debugPrint('[ReportedEvents] photo file does not exist: $localPath');
        return null;
      }

      // Read async sur isolate Dart, non bloquant
      final bytes = await file.readAsBytes();
      debugPrint('[ReportedEvents] photo bytes: ${bytes.length ~/ 1024} KB');

      if (bytes.isEmpty) {
        debugPrint('[ReportedEvents] photo empty, skipping');
        return null;
      }
      // Garde-fou : refuse > 5 MB
      if (bytes.length > 5 * 1024 * 1024) {
        debugPrint('[ReportedEvents] photo too large, skipping: ${bytes.length} bytes');
        return null;
      }

      // Yield avant l'upload
      await Future<void>.delayed(Duration.zero);

      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${ts}_report.jpg';

      // Hard timeout 12s — si le reseau est mort, on abandonne et on continue
      // sans photo plutot que de laisser la modal bloquee.
      await _storageDio
          .post(
            'object/user-events/$fileName',
            data: bytes,
            options: Options(
              headers: {'Content-Type': 'image/jpeg'},
              sendTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            ),
          )
          .timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          debugPrint('[ReportedEvents] upload timeout after 12s');
          throw TimeoutException('Upload timeout');
        },
      );

      return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/user-events/$fileName';
    } catch (e, st) {
      debugPrint('[ReportedEvents] _uploadPhotoLight failed: $e\n$st');
      return null;
    }
  }

  /// Upload video courte (10s max). Meme strategie que _uploadPhotoLight.
  Future<String?> _uploadVideoLight(String localPath) async {
    try {
      await Future<void>.delayed(Duration.zero);
      final file = File(localPath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      // Garde-fou : refuse > 20 MB
      if (bytes.length > 20 * 1024 * 1024) {
        debugPrint('[ReportedEvents] video too large: ${bytes.length} bytes');
        return null;
      }

      await Future<void>.delayed(Duration.zero);

      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${ts}_report.mp4';

      await _storageDio
          .post(
            'object/user-events/$fileName',
            data: bytes,
            options: Options(
              headers: {'Content-Type': 'video/mp4'},
              sendTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('[ReportedEvents] video upload timeout');
          throw TimeoutException('Video upload timeout');
        },
      );

      return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/user-events/$fileName';
    } catch (e, st) {
      debugPrint('[ReportedEvents] _uploadVideoLight failed: $e\n$st');
      return null;
    }
  }

  /// Signale un evenement communautaire (style Waze).
  ///
  /// Utilise la fonction RPC `upsert_reported_event` qui :
  ///   - cherche un signalement existant proche (< 20m, meme categorie, < 6h)
  ///   - si trouve : MERGE (append photo + increment report_count)
  ///   - si pas trouve : INSERT nouvelle row
  ///
  /// Le declenchement de l'edge function `generate-event-poster` ne se fait
  /// que pour les NOUVELLES rows (pas de regeneration d'affiche quand on merge).
  ///
  /// Retourne l'id de la row (existante ou nouvelle).
  Future<String> reportEvent({
    required String category,
    required String rawTitle,
    required double lat,
    required double lng,
    String? localPhotoPath,
    String? localVideoPath,
    String locationName = '',
  }) async {
    // Yield au scheduler avant les operations lourdes pour eviter ANR
    await Future<void>.delayed(Duration.zero);

    final userId = await UserIdentityService.getUserId();

    String? photoUrl;
    String? videoUrl;
    if (localPhotoPath != null && localPhotoPath.isNotEmpty) {
      photoUrl = await _uploadPhotoLight(localPhotoPath);
      if (photoUrl == null) {
        debugPrint('[ReportedEvents] photo upload returned null, continuing without photo');
      }
    }

    // Upload video si presente
    if (localVideoPath != null && localVideoPath.isNotEmpty) {
      videoUrl = await _uploadVideoLight(localVideoPath);
      if (videoUrl == null) {
        debugPrint('[ReportedEvents] video upload returned null, continuing without video');
      }

      // Si pas de photo, extraire un thumbnail de la video comme photo
      if (photoUrl == null) {
        try {
          final thumbPath = await VideoThumbnail.thumbnailFile(
            video: localVideoPath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 800,
            quality: 70,
          );
          if (thumbPath != null) {
            photoUrl = await _uploadPhotoLight(thumbPath);
            debugPrint('[ReportedEvents] video thumbnail uploaded: $photoUrl');
          }
        } catch (e) {
          debugPrint('[ReportedEvents] thumbnail extraction failed: $e');
        }
      }
    }

    // Yield avant la RPC
    await Future<void>.delayed(Duration.zero);

    // Generation d'un UUID cote client pour le cas "nouvelle row".
    // La RPC l'utilisera si pas de merge, sinon elle ignore ce id.
    final clientId = const Uuid().v4();

    final payload = {
      'p_id': clientId,
      'p_reported_by': userId,
      'p_raw_title': rawTitle,
      'p_category': category,
      'p_lat': lat,
      'p_lng': lng,
      'p_photo_url': photoUrl,
      'p_video_url': videoUrl,
    };
    debugPrint('[ReportedEvents] rpc payload: $payload');

    final Response res;
    try {
      res = await _restDio
          .post(
            'rpc/upsert_reported_event',
            data: payload,
            options: Options(
              validateStatus: (status) => true,
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('RPC upsert_reported_event timeout');
        },
      );
    } catch (e) {
      debugPrint('[ReportedEvents] rpc threw: $e');
      rethrow;
    }

    debugPrint('[ReportedEvents] rpc status: ${res.statusCode}');
    debugPrint('[ReportedEvents] rpc body: ${res.data}');

    if (res.statusCode == null ||
        res.statusCode! < 200 ||
        res.statusCode! >= 300) {
      throw Exception(
        'Supabase RPC failed [${res.statusCode}]: ${res.data}',
      );
    }

    // La fonction RPC retourne un tableau avec 1 row : [{id: ..., was_merged: bool}]
    final data = res.data;
    final row = (data is List && data.isNotEmpty)
        ? data.first as Map<String, dynamic>
        : data as Map<String, dynamic>;
    final id = row['id'] as String;
    final wasMerged = (row['was_merged'] as bool?) ?? false;

    debugPrint('[ReportedEvents] was_merged=$wasMerged id=$id');

    // Ne trigger l'IA que pour les NOUVELLES rows
    // (les merges gardent l'affiche IA originale).
    if (!wasMerged) {
      unawaited(_triggerPosterGeneration(id));
    }

    // PATCH les champs extra (pas dans la RPC pour eviter de la modifier)
    final patchData = <String, dynamic>{};
    if (locationName.isNotEmpty) patchData['location_name'] = locationName;
    if (patchData.isNotEmpty) {
      try {
        await _restDio.patch(
          'reported_events?id=eq.$id',
          data: patchData,
          options: Options(
            headers: {'Prefer': 'return=minimal'},
          ),
        );
      } catch (e) {
        if (e is DioException) {
          debugPrint('[ReportedEvents] PATCH failed: ${e.response?.statusCode} body=${e.response?.data}');
          debugPrint('[ReportedEvents] PATCH data was: $patchData');
        } else {
          debugPrint('[ReportedEvents] extra fields patch failed: $e');
        }
      }
    }

    return id;
  }

  Future<void> _triggerPosterGeneration(String id) async {
    try {
      await _functionsDio.post(
        'generate-event-poster',
        data: {'id': id},
        options: Options(
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );
    } catch (e) {
      debugPrint('[ReportedEvents] generate-event-poster failed for $id: $e');
    }
  }

  /// Recupere les signalements actifs (publies, non expires) dans la zone
  /// geographique de la ville donnee.
  ///
  /// Le filtrage utilise un bounding box (~25-30 km) autour du centre de la
  /// ville pour inclure la metropole entiere : un user qui a selectionne
  /// "Toulouse" verra aussi les signalements de Montrabe, Balma, Colomiers,
  /// Tournefeuille, etc., mais PAS ceux de Paris ou Lyon.
  ///
  /// Si la ville est inconnue (pas dans `CityCenters`) ou non fournie, on
  /// retourne les 50 signalements les plus recents toutes villes confondues.
  Future<List<ReportedEvent>> fetchActive({String? ville}) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final query = <String, String>{
      'select': '*',
      'status': 'in.(published,ai_generating)',
      'expires_at': 'gt.$nowIso',
      'order': 'created_at.desc',
      'limit': '1000',
    };

    // Pas de filtre geo — on charge tous les signalements de France
    // pour que l'utilisateur puisse voir les autres villes en dezoomant.
    // La carte centre sur la ville selectionnee (zoom 12) mais les markers
    // des autres villes sont visibles en naviguant.

    debugPrint('[ReportedEvents] fetchActive query: $query');

    final res = await _restDio.get(
      'reported_events',
      queryParameters: query,
    );
    final data = res.data as List;
    return data
        .map((e) => ReportedEvent.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Recupere une row par id (pour le bottom sheet detail).
  Future<ReportedEvent?> fetchById(String id) async {
    final res = await _restDio.get(
      'reported_events',
      queryParameters: {
        'select': '*',
        'id': 'eq.$id',
        'limit': '1',
      },
    );
    final data = res.data as List;
    if (data.isEmpty) return null;
    return ReportedEvent.fromSupabaseJson(data.first as Map<String, dynamic>);
  }
}
