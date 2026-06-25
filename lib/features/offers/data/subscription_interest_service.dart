import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/core/services/user_identity_service.dart';

/// Tracking de l'intérêt pour l'abonnement BeThere Premium (5,90€/mois).
///
/// Insère un row dans `subscription_interest` à chaque clic sur :
///   • "J'en profite"  (offer_detail)        → action 'en_profite'
///   • "S'abonner ..."  (subscription_screen) → action 'abonner'
///
/// Fire-and-forget : on n'attend jamais le résultat côté UI, et toute erreur
/// est avalée (le tracking ne doit jamais bloquer ni faire échouer un tap).
/// UUID généré client-side + return=minimal (cf. RLS : INSERT autorisé mais
/// pas de SELECT pour anon — un return=representation provoquerait un faux 401).
class SubscriptionInterestService {
  final Dio _restDio;

  SubscriptionInterestService({Dio? restDio})
      : _restDio = restDio ?? _createRestDio();

  static Dio _createRestDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Clic sur "J'en profite" depuis une offre.
  Future<void> trackEnProfite({
    String? offerId,
    String? offerTitle,
    String? ville,
  }) =>
      _track('en_profite', offerId: offerId, offerTitle: offerTitle, ville: ville);

  /// Clic sur "S'abonner pour 5,90€/mois".
  Future<void> trackAbonner({String? ville}) => _track('abonner', ville: ville);

  Future<void> _track(
    String action, {
    String? offerId,
    String? offerTitle,
    String? ville,
  }) async {
    try {
      final userId = await UserIdentityService.getUserId();
      await _restDio.post(
        'subscription_interest',
        data: {
          'id': const Uuid().v4(),
          'user_id': userId,
          'action': action,
          if (offerId != null && offerId.isNotEmpty) 'offer_id': offerId,
          if (offerTitle != null && offerTitle.isNotEmpty) 'offer_title': offerTitle,
          if (ville != null && ville.isNotEmpty) 'ville': ville,
        },
        options: Options(headers: {'Prefer': 'return=minimal'}),
      );
    } catch (e) {
      debugPrint('[SubscriptionInterest] track $action failed (ignored): $e');
    }
  }
}
