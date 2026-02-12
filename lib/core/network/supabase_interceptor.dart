import 'package:dio/dio.dart';
import 'package:pulz_app/core/config/supabase_config.dart';

class SupabaseInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['apikey'] = SupabaseConfig.supabaseAnonKey;
    options.headers['Authorization'] =
        'Bearer ${SupabaseConfig.supabaseAnonKey}';
    super.onRequest(options, handler);
  }
}
