import 'package:dio/dio.dart';
import 'package:pulz_app/core/config/supabase_config.dart';
import 'package:pulz_app/core/network/dense_city.dart';

class SupabaseInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['apikey'] = SupabaseConfig.supabaseAnonKey;
    // Ne pas ecraser un Authorization deja defini (ex: JWT pro).
    if (!options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] =
          'Bearer ${SupabaseConfig.supabaseAnonKey}';
    }
    // Paris : listes de lieux limitées à un rayon autour de l'utilisateur.
    DenseCity.apply(options);
    super.onRequest(options, handler);
  }
}
