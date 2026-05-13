import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/pro_auth/data/pro_session_service.dart';

/// Acces a la fiche venue/etablissement claimee par le pro courant.
/// Permet de la modifier (video teaser + 6 photos) depuis l'app mobile.
class ProVenueService {
  final Dio _restDio;
  final Dio _storageDio;
  final ProSessionService _proSession;

  ProVenueService({
    Dio? restDio,
    Dio? storageDio,
    ProSessionService? proSession,
  })  : _restDio = restDio ?? _createRestDio(),
        _storageDio = storageDio ?? _createStorageDio(),
        _proSession = proSession ?? ProSessionService();

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

  Future<String?> _token() async {
    final t = await _proSession.getAccessToken();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// Recupere la fiche claimee par le pro (RPC server-side qui resoud
  /// venue_claims approved → venues|etablissements).
  /// Retourne null si pas de claim approuve.
  Future<ProVenueRecord?> fetchMyVenue() async {
    final token = await _token();
    if (token == null) return null;
    try {
      final res = await _restDio.post(
        'rpc/get_my_pro_venue',
        data: const <String, dynamic>{},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data;
      if (data is! List || data.isEmpty) return null;
      return ProVenueRecord.fromJson(data.first as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[ProVenueService] fetchMyVenue error: $e');
      return null;
    }
  }

  /// Met a jour photo (pochette liste), photos[] (carrousel detail) et/ou
  /// video_url sur la fiche du pro courant.
  /// La RLS valide cote BDD que le pro est bien proprio (is_pro_owner_*).
  /// `photo` columname differe entre venues (`photo`) et etablissements
  /// (`photo` aussi en realite, mais on garde un seul mapping ici car les
  /// deux tables ont le meme nom de colonne).
  Future<void> updateMyVenue({
    required String tableName,
    required int rowId,
    String? coverPhoto,
    List<String>? photos,
    String? videoUrl,
  }) async {
    final token = await _token();
    if (token == null) {
      throw StateError('Pas de session pro');
    }
    final body = <String, dynamic>{};
    if (coverPhoto != null) body['photo'] = coverPhoto;
    if (photos != null) body['photos'] = photos;
    if (videoUrl != null) body['video_url'] = videoUrl;
    if (body.isEmpty) return;

    await _restDio.patch(
      '$tableName?id=eq.$rowId',
      data: body,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Prefer': 'return=minimal',
        },
      ),
    );
  }

  /// Upload la pochette (image principale visible dans les listes) dans
  /// `venue-photos/{tableName}_{rowId}/cover_<ts>.jpg`. Memes compression
  /// et limites que [uploadPhoto].
  Future<String> uploadCover({
    required String tableName,
    required int rowId,
    required String localPath,
  }) async {
    final token = await _token();
    if (token == null) {
      throw StateError('Pas de session pro');
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${tableName}_$rowId/cover_$ts.jpg';

    final bytes = await _compressImage(localPath);
    debugPrint('[ProVenueService] cover $fileName ${bytes.length ~/ 1024} KB');

    await _storageDio.post(
      'object/venue-photos/$fileName',
      data: bytes,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'image/jpeg',
        },
      ),
    );

    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/venue-photos/$fileName';
  }

  /// Revendique une fiche via un code unique fourni par MaCity. Cree un
  /// venue_claims status=approved lie au pro courant et consomme le code.
  /// Throw [ProClaimCodeError] avec un message UI parlant si le code est
  /// invalide, deja consomme, ou si le pro n'est pas authentifie.
  Future<String> claimWithMacityCode({
    required String sourceTable,
    required int sourceId,
    required String code,
  }) async {
    final token = await _token();
    if (token == null) {
      throw const ProClaimCodeError(
        'Connectez-vous a votre compte pro avant d\'utiliser un code.',
      );
    }
    try {
      final res = await _restDio.post(
        'rpc/claim_with_macity_code',
        data: {
          'p_source_table': sourceTable,
          'p_source_id': sourceId,
          'p_code': code.trim(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data;
      if (data is String) return data;
      throw const ProClaimCodeError('Reponse serveur inattendue.');
    } on DioException catch (e) {
      throw ProClaimCodeError(_mapClaimError(e));
    }
  }

  String _mapClaimError(DioException e) {
    final body = e.response?.data;
    String msg = '';
    if (body is Map) {
      msg = (body['message'] ?? body['hint'] ?? body['details'] ?? '').toString();
    } else if (body is String) {
      msg = body;
    }
    final lower = msg.toLowerCase();
    if (lower.contains('invalid_code')) return 'Code incorrect.';
    if (lower.contains('no_active_code')) {
      return 'Aucun code actif pour cette fiche. Contactez MaCity.';
    }
    if (lower.contains('not_authenticated')) {
      return 'Session pro expiree. Reconnectez-vous.';
    }
    if (lower.contains('pro_profile_missing')) {
      return 'Aucun profil pro associe a votre compte.';
    }
    if (lower.contains('invalid_source_table')) {
      return 'Fiche non eligible.';
    }
    return msg.isEmpty ? 'Erreur reseau, reessaie.' : msg;
  }

  /// Compresse JPEG 75% / max 1280px.
  Future<Uint8List> _compressImage(String path) async {
    final result = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: 1280,
      minHeight: 1280,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    if (result != null) return result;
    throw StateError('Compression image echouee');
  }

  /// Upload une photo dans le bucket `venue-photos/{tableName}_{rowId}/N.jpg`.
  /// Retourne l'URL publique.
  Future<String> uploadPhoto({
    required String tableName,
    required int rowId,
    required int slotIndex,
    required String localPath,
  }) async {
    final token = await _token();
    if (token == null) {
      throw StateError('Pas de session pro');
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${tableName}_$rowId/${slotIndex}_$ts.jpg';

    final bytes = await _compressImage(localPath);
    debugPrint('[ProVenueService] photo $fileName ${bytes.length ~/ 1024} KB');

    await _storageDio.post(
      'object/venue-photos/$fileName',
      data: bytes,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'image/jpeg',
        },
      ),
    );

    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/venue-photos/$fileName';
  }

  /// Limite cote bucket `venue-photos` (cf. migration). On valide ici aussi
  /// pour donner un message clair avant l'upload reseau.
  static const int kVideoMaxBytes = 50 * 1024 * 1024;

  /// Upload une video dans le bucket `venue-photos/{tableName}_{rowId}/video_<ts>.mp4`.
  /// Compresse via VideoCompress (LowQuality). Levee `ProVenueUploadError` si
  /// la video compressee depasse [kVideoMaxBytes] (50 MB).
  ///
  /// [onCompressed] est appele apres compression avec la taille en KB.
  /// [onProgress] est appele pendant l'upload avec un pourcentage [0..1].
  Future<String> uploadVideo({
    required String tableName,
    required int rowId,
    required String localPath,
    void Function(int compressedKb)? onCompressed,
    void Function(double percent)? onProgress,
  }) async {
    final token = await _token();
    if (token == null) {
      throw StateError('Pas de session pro');
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${tableName}_$rowId/video_$ts.mp4';

    Uint8List bytes;
    try {
      final info = await VideoCompress.compressVideo(
        localPath,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
      );
      if (info?.file != null) {
        bytes = await info!.file!.readAsBytes();
      } else {
        bytes = await File(localPath).readAsBytes();
      }
    } catch (e) {
      debugPrint('[ProVenueService] video compress failed: $e — using raw');
      bytes = await File(localPath).readAsBytes();
    }

    final kb = bytes.length ~/ 1024;
    debugPrint('[ProVenueService] video $fileName compressed: $kb KB');
    onCompressed?.call(kb);

    if (bytes.length > kVideoMaxBytes) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      throw ProVenueUploadError(
        'Video trop lourde apres compression ($mb MB). Limite : 50 MB. '
        'Reessayez avec une video plus courte.',
      );
    }

    try {
      await _storageDio.post(
        'object/venue-photos/$fileName',
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'video/mp4',
            'Content-Length': bytes.length.toString(),
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 413) {
        throw const ProVenueUploadError(
          'Video refusee par le serveur (trop lourde). Limite : 50 MB.',
        );
      }
      rethrow;
    }

    return '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/venue-photos/$fileName';
  }
}

/// Erreur d'upload pro avec message UI parlant.
class ProVenueUploadError implements Exception {
  final String message;
  const ProVenueUploadError(this.message);
  @override
  String toString() => message;
}

/// Erreur typee pour la revendication via code MaCity. Le `message` est
/// directement affichable a l'utilisateur.
class ProClaimCodeError implements Exception {
  final String message;
  const ProClaimCodeError(this.message);
  @override
  String toString() => message;
}

/// Snapshot de la fiche claimee par le pro courant.
class ProVenueRecord {
  final String tableName; // 'venues' | 'etablissements'
  final int rowId;
  final String name;
  final String ville;
  final String category;
  final String? mainPhoto;
  final List<String> photos;
  final String? videoUrl;

  const ProVenueRecord({
    required this.tableName,
    required this.rowId,
    required this.name,
    required this.ville,
    required this.category,
    required this.mainPhoto,
    required this.photos,
    required this.videoUrl,
  });

  factory ProVenueRecord.fromJson(Map<String, dynamic> j) {
    final raw = j['photos'];
    final list = (raw is List)
        ? raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : <String>[];
    return ProVenueRecord(
      tableName: j['table_name'] as String? ?? '',
      rowId: (j['row_id'] as num?)?.toInt() ?? 0,
      name: j['name'] as String? ?? '',
      ville: j['ville'] as String? ?? '',
      category: j['category'] as String? ?? '',
      mainPhoto: j['photo'] as String?,
      photos: list,
      videoUrl: j['video_url'] as String?,
    );
  }

  ProVenueRecord copyWith({
    String? mainPhoto,
    List<String>? photos,
    String? videoUrl,
  }) {
    return ProVenueRecord(
      tableName: tableName,
      rowId: rowId,
      name: name,
      ville: ville,
      category: category,
      mainPhoto: mainPhoto ?? this.mainPhoto,
      photos: photos ?? this.photos,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}
