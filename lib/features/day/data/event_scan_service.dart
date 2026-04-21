import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/pro_auth/data/pro_auth_service.dart';
import 'package:pulz_app/features/pro_auth/data/pro_session_service.dart';

/// Resultat d'un scan de flyer. [data] est le JSON extrait par Claude Haiku,
/// mappable sur le state du wizard CreateEvent.
@immutable
class ScanEventResult {
  final Map<String, dynamic> data;
  final String photoUrl;
  final int used;
  final int max;
  final int remaining;
  const ScanEventResult({
    required this.data,
    required this.photoUrl,
    required this.used,
    required this.max,
    required this.remaining,
  });
}

class ScanEventException implements Exception {
  final String message;
  final int? statusCode;
  ScanEventException(this.message, {this.statusCode});
  @override
  String toString() => 'ScanEventException($statusCode): $message';
}

/// Service qui orchestre : upload de la photo -> appel edge function
/// `scan-event-flyer` avec le JWT du pro -> parsing du resultat.
///
/// Protege cote serveur par auth pro + rate limit 20/jour.
class EventScanService {
  final UserEventSupabaseService _uploader;
  final ProSessionService _session;
  final ProAuthService _authService;
  final Dio _functionsDio;

  EventScanService({
    UserEventSupabaseService? uploader,
    ProSessionService? session,
    ProAuthService? authService,
    Dio? functionsDio,
  })  : _uploader = uploader ?? UserEventSupabaseService(),
        _session = session ?? ProSessionService(),
        _authService = authService ?? ProAuthService(),
        _functionsDio = functionsDio ?? _createFunctionsDio();

  static Dio _createFunctionsDio() {
    final dio = DioClient.withBaseUrl(
      '${SupabaseConfig.supabaseUrl}/functions/v1/',
    );
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Upload la photo locale puis appelle l'edge function. L'URL uploadee est
  /// reutilisee comme `photoPath` initial du wizard (on evite un re-upload
  /// apres la soumission).
  Future<ScanEventResult> scanFlyer(String localPhotoPath) async {
    // Refresh le token en amont : le JWT Supabase Auth dure ~1h, si l'user
    // est connecte depuis longtemps le token stocke est peut-etre expire.
    final accessToken = await _getFreshAccessToken();
    if (accessToken == null) {
      throw ScanEventException(
        'Session pro expiree, reconnecte-toi',
        statusCode: 401,
      );
    }

    // 1. Upload la photo vers le bucket user-events (meme chemin que les
    // photos d'evenements ordinaires).
    final photoUrl = await _uploader.uploadPhoto(localPhotoPath);
    debugPrint('[EventScan] uploaded -> $photoUrl');

    // 2. Appel edge function. Le JWT pro va dans Authorization ; l'anon key
    // est ajoutee par SupabaseInterceptor mais ne remplace PAS l'Authorization.
    Response res;
    try {
      res = await _functionsDio.post(
        'scan-event-flyer',
        data: {'photo_url': photoUrl},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw ScanEventException(
        'Reseau : ${e.message ?? e.type.name}',
        statusCode: e.response?.statusCode,
      );
    }

    debugPrint(
      '[EventScan] edge function ${res.statusCode} body=${res.data.toString().substring(0, (res.data.toString().length).clamp(0, 400))}',
    );

    final status = res.statusCode ?? 0;
    final body = res.data;

    if (status == 429) {
      final detail = (body is Map && body['detail'] is String)
          ? body['detail'] as String
          : 'Limite quotidienne de scans atteinte (20/jour)';
      throw ScanEventException(detail, statusCode: 429);
    }
    if (status == 403) {
      throw ScanEventException(
        'Scan reserve aux pros approuves',
        statusCode: 403,
      );
    }
    if (status < 200 || status >= 300 || body is! Map) {
      final msg = (body is Map && body['error'] is String)
          ? body['error'] as String
          : 'Echec du scan (code $status)';
      throw ScanEventException(msg, statusCode: status);
    }

    final data = body['data'];
    if (data is! Map) {
      throw ScanEventException(
        'Reponse IA invalide',
        statusCode: 502,
      );
    }

    final rl = body['rate_limit'] as Map?;
    return ScanEventResult(
      data: Map<String, dynamic>.from(data),
      photoUrl: photoUrl,
      used: (rl?['used'] as num?)?.toInt() ?? 0,
      max: (rl?['max'] as num?)?.toInt() ?? 20,
      remaining: (rl?['remaining'] as num?)?.toInt() ?? 0,
    );
  }

  /// Rafraichit l'access_token en amont pour eviter les 401 quand la session
  /// est vieille. Si le refresh echoue, on tente avec le token existant
  /// (meme expire) : la function renverra 401 avec un message clair.
  Future<String?> _getFreshAccessToken() async {
    final refreshTok = await _session.getRefreshToken();
    if (refreshTok != null) {
      try {
        final fresh = await _authService.refreshToken(refreshTok);
        if (fresh != null) {
          await _session.updateTokens(
            accessToken: fresh.accessToken,
            refreshToken: fresh.refreshToken,
          );
          return fresh.accessToken;
        }
      } catch (e) {
        debugPrint('[EventScan] refreshToken failed, fallback: $e');
      }
    }
    return _session.getAccessToken();
  }
}
