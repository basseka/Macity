import 'package:dio/dio.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';

/// Vérification d'email à l'inscription (code à 6 chiffres).
/// - [requestCode] : déclenche l'envoi du mail (edge function).
/// - [verifyCode]  : valide le code saisi (RPC SECURITY DEFINER).
class EmailVerificationService {
  final Dio _restDio;
  final Dio _fnDio;

  EmailVerificationService({Dio? restDio, Dio? fnDio})
      : _restDio = restDio ?? _createRestDio(),
        _fnDio = fnDio ?? _createFnDio();

  static Dio _createRestDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  static Dio _createFnDio() {
    final dio = DioClient.withBaseUrl(
      '${SupabaseConfig.supabaseUrl}/functions/v1/',
    );
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Envoie un code de confirmation à [email]. Lève une exception si l'envoi
  /// échoue (à présenter à l'utilisateur).
  Future<void> requestCode({required String email, String? prenom}) async {
    await _fnDio.post(
      'request-email-verification',
      data: {
        'email': email.trim(),
        if (prenom != null && prenom.trim().isNotEmpty) 'prenom': prenom.trim(),
      },
    );
  }

  /// Vérifie le [code] saisi pour [email]. Retourne true si valide.
  Future<bool> verifyCode({required String email, required String code}) async {
    final res = await _restDio.post(
      'rpc/verify_email_code',
      data: {'p_email': email.trim(), 'p_code': code.trim()},
    );
    return res.data == true;
  }
}
