import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/private_events/domain/models/private_event.dart';

/// Erreurs metier remontees par les RPC `private_events`. Le code matche le
/// `RAISE EXCEPTION 'xxx'` cote SQL pour permettre un branch UI propre.
enum PrivateEventError {
  notFound,
  wrongPasscode,
  expired,
  quotaExceeded,
  invalidInput,
  network,
}

class PrivateEventException implements Exception {
  final PrivateEventError code;
  final String? message;
  PrivateEventException(this.code, [this.message]);

  @override
  String toString() => 'PrivateEventException($code, $message)';
}

/// Wrapper sur les 4 RPC SECURITY DEFINER (cf. migration
/// 20260504150000_private_events.sql). Pas d'acces direct a la table
/// (RLS deny-all).
class PrivateEventService {
  final Dio _dio;

  PrivateEventService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Cree un event prive et renvoie la row complete (avec access_token + passcode).
  Future<PrivateEvent> createPrivateEvent({
    required String hostDeviceUuid,
    required String title,
    required String passcode,
    required DateTime date,
    String heure = '',
    String lieu = '',
    String adresse = '',
    String description = '',
    String? photoUrl,
    int maxOpens = 50,
  }) async {
    try {
      final response = await _dio.post(
        'rpc/create_private_event',
        data: {
          'p_host_device_uuid': hostDeviceUuid,
          'p_title': title,
          'p_passcode': passcode,
          'p_date': _formatDate(date),
          'p_heure': heure,
          'p_lieu': lieu,
          'p_adresse': adresse,
          'p_description': description,
          'p_photo_url': photoUrl,
          'p_max_opens': maxOpens,
        },
      );
      return PrivateEvent.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Tente d'ouvrir un coffre. Throw [PrivateEventException] si token/passcode
  /// invalide, expire, ou quota depasse.
  Future<PrivateEventReveal> openPrivateEvent({
    required String token,
    required String passcode,
  }) async {
    try {
      final response = await _dio.post(
        'rpc/open_private_event',
        data: {'p_token': token, 'p_passcode': passcode},
      );
      final data = response.data as List;
      if (data.isEmpty) {
        throw PrivateEventException(PrivateEventError.notFound);
      }
      return PrivateEventReveal.fromJson(
        data.first as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Liste les events crees par ce device (avec leur token + passcode pour
  /// re-partage).
  Future<List<PrivateEvent>> listMyPrivateEvents({
    required String hostDeviceUuid,
  }) async {
    try {
      final response = await _dio.post(
        'rpc/list_my_private_events',
        data: {'p_host_device_uuid': hostDeviceUuid},
      );
      final data = response.data as List;
      return data
          .map((e) => PrivateEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[PrivateEvents] list failed: $e');
      return [];
    }
  }

  /// L'invite indique sa presence. Idempotent : appeler 2x ne cree pas de
  /// doublon. Retourne la liste mise a jour des acceptants.
  Future<List<PrivateEventRsvp>> rsvpToPrivateEvent({
    required String token,
    required String passcode,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        'rpc/rsvp_to_private_event',
        data: {
          'p_token': token,
          'p_passcode': passcode,
          'p_user_id': userId,
        },
      );
      final data = response.data as List;
      return data
          .map((e) => PrivateEventRsvp.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Retire la presence d'un invite. Retourne la liste mise a jour.
  Future<List<PrivateEventRsvp>> cancelMyRsvp({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        'rpc/cancel_my_rsvp',
        data: {'p_token': token, 'p_user_id': userId},
      );
      final data = response.data as List;
      return data
          .map((e) => PrivateEventRsvp.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Liste les soirees privees auxquelles ce device a confirme sa venue
  /// (RSVP "going") et qui ne sont pas passees. La RPC renvoie aussi
  /// l'access_token pour permettre [cancelMyRsvp] depuis cette vue.
  Future<List<PrivateEventReveal>> listMyInvitations({
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        'rpc/list_my_invitations',
        data: {'p_user_id': userId},
      );
      final data = response.data as List;
      return data
          .map((e) => PrivateEventReveal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[PrivateEvents] listMyInvitations failed: $e');
      return [];
    }
  }

  /// Liste les RSVP d'un event pour son hote (filtre serveur sur device UUID).
  Future<List<PrivateEventRsvp>> hostListEventRsvps({
    required String token,
    required String hostDeviceUuid,
  }) async {
    try {
      final response = await _dio.post(
        'rpc/host_list_event_rsvps',
        data: {'p_token': token, 'p_host_device_uuid': hostDeviceUuid},
      );
      final data = response.data as List;
      return data
          .map((e) => PrivateEventRsvp.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('[PrivateEvents] hostListEventRsvps failed: $e');
      return [];
    }
  }

  /// Supprime un event si appartient au device caller. Renvoie true si delete OK.
  Future<bool> deleteMyPrivateEvent({
    required String token,
    required String hostDeviceUuid,
  }) async {
    try {
      final response = await _dio.post(
        'rpc/delete_my_private_event',
        data: {'p_token': token, 'p_host_device_uuid': hostDeviceUuid},
      );
      return response.data == true;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Mappe les RAISE EXCEPTION SQL ou erreurs reseau en [PrivateEventException].
  PrivateEventException _mapError(DioException e) {
    final body = e.response?.data;
    String? message;
    if (body is Map) {
      message = body['message'] as String?;
    }
    switch (message) {
      case 'not_found':
        return PrivateEventException(PrivateEventError.notFound, message);
      case 'wrong_passcode':
        return PrivateEventException(
          PrivateEventError.wrongPasscode,
          message,
        );
      case 'expired':
        return PrivateEventException(PrivateEventError.expired, message);
      case 'quota_exceeded':
        return PrivateEventException(
          PrivateEventError.quotaExceeded,
          message,
        );
      default:
        if (message != null &&
            (message.contains('passcode must') ||
                message.contains('title required') ||
                message.contains('date must'))) {
          return PrivateEventException(
            PrivateEventError.invalidInput,
            message,
          );
        }
        debugPrint('[PrivateEvents] dio error: $e');
        return PrivateEventException(PrivateEventError.network, message);
    }
  }
}
