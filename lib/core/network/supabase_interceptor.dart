import 'package:dio/dio.dart';
import 'package:pulz_app/core/config/supabase_config.dart';

class SupabaseInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['apikey'] = SupabaseConfig.supabaseAnonKey;
    // Ne pas ecraser un Authorization deja defini (ex: JWT pro).
    if (!options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] =
          'Bearer ${SupabaseConfig.supabaseAnonKey}';
    }
    super.onRequest(options, handler);
  }
}
