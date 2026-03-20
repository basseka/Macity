import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';

/// Service de logging d'activite utilisateur.
/// Chaque appel insere une ligne dans `appli_activity`.
/// Toutes les methodes sont fire-and-forget (non-bloquantes).
class ActivityService {
  ActivityService._();
  static final instance = ActivityService._();

  late final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Log generique — ne jamais await dans le code appelant.
  Future<void> _log(String action, [Map<String, dynamic>? metadata]) async {
    try {
      final userId = await UserIdentityService.getUserId();
      await _dio.post(
        'appli_activity',
        data: {
          'user_id': userId,
          'action': action,
          if (metadata != null) 'metadata': metadata,
        },
        options: Options(headers: {'Prefer': 'return=minimal'}),
      );
    } catch (e) {
      debugPrint('[Activity] log($action) failed: $e');
    }
  }

  // ─────────────────────────────────────────
  // Actions predefinies
  // ─────────────────────────────────────────

  /// App ouverte (splash screen).
  void appOpen() => _log('app_open');

  /// Onboarding termine.
  void onboardingComplete({String? ville}) =>
      _log('onboarding_complete', {'ville': ville});

  /// Event cree par l'utilisateur.
  void eventCreated({
    required String eventId,
    required String titre,
    required String categorie,
    required String rubrique,
    String? ville,
  }) =>
      _log('event_created', {
        'event_id': eventId,
        'titre': titre,
        'categorie': categorie,
        'rubrique': rubrique,
        if (ville != null) 'ville': ville,
      });

  /// Event partage in-app avec d'autres utilisateurs.
  void eventShared({
    required String eventId,
    required int nbDestinataires,
  }) =>
      _log('event_shared', {
        'event_id': eventId,
        'nb_destinataires': nbDestinataires,
      });

  /// Event partage via share_plus (SMS, WhatsApp, etc.).
  void eventSharedExternal({required String eventId}) =>
      _log('event_shared_external', {'event_id': eventId});

  /// Like / unlike.
  void like({required String itemId, required bool isLike}) =>
      _log('like', {'item_id': itemId, 'is_like': isLike});

  /// Vue d'un mode (day, sport, culture, etc.).
  void modeView({required String mode}) =>
      _log('mode_view', {'mode': mode});

  /// Recherche effectuee.
  void search({required String query}) =>
      _log('search', {'query': query});

  /// Notification mairie consultee.
  void mairieNotifView() => _log('mairie_notif_view');

  /// Partage avec moi consulte.
  void sharedWithMeView() => _log('shared_with_me_view');
}
