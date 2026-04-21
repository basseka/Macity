import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/onboarding/data/user_profile_service.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';

/// Resultat de la soumission d'un signalement.
/// [photoFailures] = nombre de photos qui n'ont pas pu etre uploadees
/// (remonte a l'utilisateur via un toast).
class ReportSubmitResult {
  final String id;
  final int photoFailures;
  const ReportSubmitResult({required this.id, this.photoFailures = 0});
}

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

      // Compression JPEG 1024px / quality 80 : garantit un payload leger
      // meme quand ImagePicker n'a pas applique ses contraintes (HEIC iOS,
      // certains chemins gallery). Sans ca, des photos plein cadre (~3-8 MB)
      // peuvent timeout en upload sur reseau lent et silencieusement disparaitre.
      Uint8List? bytes = await FlutterImageCompress.compressWithFile(
        localPath,
        minWidth: 1024,
        minHeight: 1024,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      bytes ??= await file.readAsBytes();
      debugPrint('[ReportedEvents] photo compressed: ${bytes.length ~/ 1024} KB');

      if (bytes.isEmpty) {
        debugPrint('[ReportedEvents] photo empty, skipping');
        return null;
      }
      // Garde-fou : refuse > 5 MB (ne devrait jamais arriver apres compression)
      if (bytes.length > 5 * 1024 * 1024) {
        debugPrint('[ReportedEvents] photo too large after compression: ${bytes.length} bytes');
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
  /// Multi-photos : on uploade les photos en serie, puis on appelle la RPC
  /// une fois avec la premiere URL. Pour chaque URL supplementaire, on rappelle
  /// la RPC (le merge detecte qu'on est le meme reporter sur la meme row et
  /// se contente d'appender l'URL dans le tableau `photos`).
  Future<ReportSubmitResult> reportEvent({
    required String category,
    required String rawTitle,
    required double lat,
    required double lng,
    List<String> localPhotoPaths = const [],
    String? localVideoPath,
    String locationName = '',
    String? osmId,
  }) async {
    // Yield au scheduler avant les operations lourdes pour eviter ANR
    await Future<void>.delayed(Duration.zero);

    final userId = await UserIdentityService.getUserId();

    // Recupere le profil pour denormaliser prenom/avatar dans le signalement.
    String? reporterPrenom;
    String? reporterAvatarUrl;
    try {
      final profile = await UserProfileService().fetchProfile();
      if (profile != null) {
        final p = (profile['prenom'] as String?)?.trim();
        if (p != null && p.isNotEmpty) reporterPrenom = p;
        final a = profile['avatar_url'] as String?;
        if (a != null && a.isNotEmpty) reporterAvatarUrl = a;
      }
    } catch (_) {
      // Pas bloquant : on signale en anonyme.
    }

    // Boucle upload des photos : on garde les URLs reussies et on compte
    // les echecs pour les remonter a l'UI (toast utilisateur).
    final photoUrls = <String>[];
    int photoFailures = 0;
    for (final path in localPhotoPaths) {
      if (path.isEmpty) continue;
      final url = await _uploadPhotoLight(path);
      if (url == null) {
        photoFailures++;
        debugPrint('[ReportedEvents] photo upload failed: $path');
      } else {
        photoUrls.add(url);
      }
    }

    String? videoUrl;
    if (localVideoPath != null && localVideoPath.isNotEmpty) {
      videoUrl = await _uploadVideoLight(localVideoPath);
      if (videoUrl == null) {
        debugPrint('[ReportedEvents] video upload returned null, continuing without video');
      }

      // Si pas de photo, extraire un thumbnail de la video comme photo
      if (photoUrls.isEmpty) {
        try {
          final thumbPath = await VideoThumbnail.thumbnailFile(
            video: localVideoPath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 800,
            quality: 70,
          );
          if (thumbPath != null) {
            final thumbUrl = await _uploadPhotoLight(thumbPath);
            if (thumbUrl != null) {
              photoUrls.add(thumbUrl);
              debugPrint('[ReportedEvents] video thumbnail uploaded: $thumbUrl');
            }
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
    final firstPhotoUrl = photoUrls.isNotEmpty ? photoUrls.first : null;

    final payload = {
      'p_id': clientId,
      'p_reported_by': userId,
      'p_raw_title': rawTitle,
      'p_category': category,
      'p_lat': lat,
      'p_lng': lng,
      'p_photo_url': firstPhotoUrl,
      'p_video_url': videoUrl,
      'p_osm_id': (osmId != null && osmId.isNotEmpty) ? osmId : null,
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

    // Appende les photos supplementaires via des appels RPC suivants.
    // Le merge detecte qu'on est le meme reporter sur la meme row
    // (osm_id ou bbox + category + 6h) et se contente d'ajouter l'URL
    // au tableau `photos` (report_count pas incremente, reporter_ids pas
    // duplique). Ca evite une migration du schema pour un flow peu frequent.
    for (int i = 1; i < photoUrls.length; i++) {
      final extraPayload = {...payload, 'p_photo_url': photoUrls[i]};
      try {
        await _restDio.post(
          'rpc/upsert_reported_event',
          data: extraPayload,
          options: Options(
            sendTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
      } catch (e) {
        debugPrint('[ReportedEvents] extra photo append failed (${photoUrls[i]}): $e');
        photoFailures++;
      }
    }

    // Ne trigger l'IA que pour les NOUVELLES rows
    // (les merges gardent l'affiche IA originale).
    if (!wasMerged) {
      unawaited(_triggerPosterGeneration(id));
    }

    // Append le user comme contributor (idempotent cote DB via user_id).
    if (reporterPrenom != null) {
      try {
        await _restDio.post(
          'rpc/add_reporter_contributor',
          data: {
            'p_event_id': id,
            'p_user_id': userId,
            'p_prenom': reporterPrenom,
            'p_avatar_url': reporterAvatarUrl,
          },
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
      } catch (e) {
        debugPrint('[ReportedEvents] add_reporter_contributor failed: $e');
      }
    }

    // PATCH les champs extra (pas dans la RPC pour eviter de la modifier)
    final patchData = <String, dynamic>{};
    if (locationName.isNotEmpty) patchData['location_name'] = locationName;
    // Identite du reporter : SEULEMENT si nouvelle row (on garde le 1er reporter).
    if (!wasMerged) {
      if (reporterPrenom != null) patchData['reporter_prenom'] = reporterPrenom;
      if (reporterAvatarUrl != null) {
        patchData['reporter_avatar_url'] = reporterAvatarUrl;
      }
    }
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

    return ReportSubmitResult(id: id, photoFailures: photoFailures);
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
