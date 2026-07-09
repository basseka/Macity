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
import 'package:video_compress/video_compress.dart';
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

/// Levee quand aucun media n'a pu etre uploade (reseau/compression/timeout).
/// On refuse alors de creer une story vide : l'UI invite a reessayer.
class NoMediaUploadedException implements Exception {
  const NoMediaUploadedException();
  @override
  String toString() => 'NoMediaUploadedException';
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

      // Compression JPEG 1440px / quality 90 : preset "qualite elevee equilibree".
      // Convertit aussi le HEIC iOS et garantit un payload < 1.5 MB meme sur
      // photo plein cadre.
      Uint8List? bytes = await FlutterImageCompress.compressWithFile(
        localPath,
        minWidth: 1440,
        minHeight: 1440,
        quality: 90,
        format: CompressFormat.jpeg,
      );
      bytes ??= await file.readAsBytes();
      debugPrint('[ReportedEvents] photo compressed: ${bytes.length ~/ 1024} KB');

      if (bytes.isEmpty) {
        debugPrint('[ReportedEvents] photo empty, skipping');
        return null;
      }
      // Garde-fou : refuse > 8 MB (ne devrait jamais arriver apres compression)
      if (bytes.length > 8 * 1024 * 1024) {
        debugPrint('[ReportedEvents] photo too large after compression: ${bytes.length} bytes');
        return null;
      }

      // Yield avant l'upload
      await Future<void>.delayed(Duration.zero);

      // Upload avec retry : 2 tentatives, timeout 20s/essai, backoff 2s. Un
      // nouveau fileName est genere a chaque essai pour eviter un 409. Si tout
      // echoue, on continue sans photo plutot que de bloquer la modal.
      const maxAttempts = 2;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${ts}_report.jpg';
        try {
          await _storageDio
              .post(
                'object/user-events/$fileName',
                data: bytes,
                options: Options(
                  headers: {'Content-Type': 'image/jpeg'},
                  sendTimeout: const Duration(seconds: 20),
                  receiveTimeout: const Duration(seconds: 20),
                ),
              )
              .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Upload timeout');
            },
          );
          return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/user-events/$fileName';
        } catch (e) {
          debugPrint('[ReportedEvents] photo upload attempt '
              '$attempt/$maxAttempts failed: $e');
          if (attempt == maxAttempts) return null;
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        }
      }
      return null;
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

      // Compression AVANT lecture des bytes : une video camera brute
      // (ResolutionPreset.veryHigh, 10s) pese souvent 25-50 MB.
      // Res1280x720Quality ramene a ~4-8 MB tout en gardant une qualite
      // visuelle "Snapchat moderne".
      // Duree d'origine (avant compression) pour detecter le bug VFR.
      double? originalDurationMs;
      try {
        originalDurationMs = (await VideoCompress.getMediaInfo(localPath)).duration;
      } catch (_) {
        // getMediaInfo indispo : on ne pourra pas detecter le VFR, tant pis.
      }

      Uint8List bytes;
      try {
        final info = await VideoCompress.compressVideo(
          localPath,
          quality: VideoQuality.Res1280x720Quality,
          deleteOrigin: false,
        );
        final compressedFile = info?.file;
        final compressedDurationMs = info?.duration;

        // Detection VFR (Variable Frame Rate) : sur les cameras Xiaomi/MIUI,
        // le transcodeur de video_compress contracte la duree (frames VFR
        // ree-crites a 30 fps constant sans preserver les PTS) -> la video
        // parait acceleree. Si la duree compressee a retreci de >10%, on jette
        // la version compressee et on uploade le brut : ExoPlayer (video_player)
        // joue le VFR a la bonne vitesse. La detection est par symptome (duree),
        // donc valable pour TOUS les appareils VFR, pas seulement Xiaomi.
        final shrunk = originalDurationMs != null &&
            compressedDurationMs != null &&
            originalDurationMs > 0 &&
            compressedDurationMs < originalDurationMs * 0.9;

        if (compressedFile != null && !shrunk) {
          bytes = await compressedFile.readAsBytes();
          debugPrint('[ReportedEvents] video compressed: ${bytes.length ~/ 1024} KB');
        } else {
          if (shrunk) {
            debugPrint('[ReportedEvents] VFR detecte '
                '(compressee ${compressedDurationMs.toInt()}ms < '
                'origine ${originalDurationMs.toInt()}ms) -> upload brut');
          }
          bytes = await file.readAsBytes();
        }
      } catch (e) {
        debugPrint('[ReportedEvents] video compress failed, fallback raw: $e');
        bytes = await file.readAsBytes();
      }
      if (bytes.isEmpty) return null;
      // Garde-fou taille : 50 MB. Plafond eleve car le fallback brut VFR n'est
      // pas compresse (720p/10s ~ 10-25 MB, marge pour les bitrates eleves).
      if (bytes.length > 50 * 1024 * 1024) {
        debugPrint('[ReportedEvents] video too large: ${bytes.length} bytes');
        return null;
      }

      await Future<void>.delayed(Duration.zero);

      // Upload avec retry : reseau mobile instable -> jusqu'a 3 tentatives,
      // timeout 120s/essai, backoff 2s puis 4s. Un nouveau fileName est genere
      // a chaque tentative pour eviter un 409 (l'objet d'un essai precedent
      // partiellement uploade ne bloque pas le suivant).
      const maxAttempts = 3;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${ts}_report.mp4';
        try {
          await _storageDio
              .post(
                'object/user-events/$fileName',
                data: bytes,
                options: Options(
                  headers: {'Content-Type': 'video/mp4'},
                  sendTimeout: const Duration(seconds: 120),
                  receiveTimeout: const Duration(seconds: 120),
                ),
              )
              .timeout(
            const Duration(seconds: 120),
            onTimeout: () {
              throw TimeoutException('Video upload timeout');
            },
          );
          return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/user-events/$fileName';
        } catch (e) {
          debugPrint('[ReportedEvents] video upload attempt '
              '$attempt/$maxAttempts failed: $e');
          if (attempt == maxAttempts) return null;
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
        }
      }
      return null;
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
    bool isPrivate = false,
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
    String? coverUrl;
    if (localVideoPath != null && localVideoPath.isNotEmpty) {
      videoUrl = await _uploadVideoLight(localVideoPath);
      if (videoUrl == null) {
        debugPrint('[ReportedEvents] video upload returned null, continuing without video');
      }

      // Pas de photo postee -> on extrait une miniature de la video pour
      // servir de pochette aux bulles du carrousel/strip. Cette miniature
      // est stockee dans `cover_url` cote DB, PAS dans photos[] -> elle
      // n'apparait donc pas dans le viewer Snap-style (qui itere sur
      // photos + videos).
      if (photoUrls.isEmpty) {
        try {
          final thumbPath = await VideoThumbnail.thumbnailFile(
            video: localVideoPath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 1080,
            quality: 85,
          );
          if (thumbPath != null) {
            coverUrl = await _uploadPhotoLight(thumbPath);
            if (coverUrl != null) {
              debugPrint('[ReportedEvents] cover uploaded from video thumbnail: $coverUrl');
            }
          }
        } catch (e) {
          debugPrint('[ReportedEvents] cover thumbnail extraction failed: $e');
        }
      }
    }

    // Garde-fou : ne JAMAIS creer une story sans aucun media. Si tous les
    // uploads ont echoue (reseau/compression/timeout) on abandonne ici et on
    // remonte l'echec a l'UI au lieu de publier une coquille vide (photos +
    // videos + cover tous null). C'est ce qui generait les stories fantomes.
    if (photoUrls.isEmpty && videoUrl == null) {
      debugPrint('[ReportedEvents] abort: aucun media uploade avec succes');
      throw const NoMediaUploadedException();
    }

    // Yield avant la RPC
    await Future<void>.delayed(Duration.zero);

    // Generation d'un UUID cote client pour le cas "nouvelle row".
    // La RPC l'utilisera si pas de merge, sinon elle ignore ce id.
    final clientId = const Uuid().v4();
    final firstPhotoUrl = photoUrls.isNotEmpty ? photoUrls.first : null;
    // Cover : miniature extraite si video-only, sinon 1ere photo postee.
    final effectiveCoverUrl = coverUrl ?? firstPhotoUrl;

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
      'p_cover_url': effectiveCoverUrl,
      'p_is_private': isPrivate,
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
    final userId = await UserIdentityService.getUserId();
    final query = <String, String>{
      'select': '*',
      'status': 'in.(published,ai_generating)',
      'expires_at': 'gt.$nowIso',
      // Stories privees : visibles uniquement par leur reporter (device UUID).
      // PostgREST `or=(...)` cree un OR : public OU bien la mienne.
      'or': '(is_private.eq.false,reported_by.eq.$userId)',
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

  /// Recupere TOUTES les stories du user courant (device UUID), tous statuts
  /// (expirees incluses), sur 1 mois — pour l'ecran « Mes publications ».
  /// Passe par le RPC get_my_stories (SECURITY DEFINER) qui bypasse la RLS.
  Future<List<ReportedEvent>> fetchMyStories() async {
    final userId = await UserIdentityService.getUserId();
    final res = await _restDio.post(
      'rpc/get_my_stories',
      data: {'p_device_uuid': userId},
    );
    final data = res.data as List;
    return data
        .map((e) => ReportedEvent.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Supprime une story du user courant (row + medias Storage), meme si elle
  /// vient d'etre creee. Le RPC verifie que reported_by = device UUID.
  /// Retourne true si la suppression a eu lieu.
  Future<bool> deleteMyStory(String id) async {
    final userId = await UserIdentityService.getUserId();
    final res = await _restDio.post(
      'rpc/delete_my_story',
      data: {'p_id': id, 'p_device_uuid': userId},
    );
    return res.data == true || res.data.toString() == 'true';
  }
}
