import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/home/domain/models/banner.dart';

class BannerSupabaseService {
  final Dio _restDio;

  BannerSupabaseService({Dio? restDio})
      : _restDio = restDio ?? _createRestDio();

  static Dio _createRestDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  Future<List<Banner>> fetchActiveBanners() async {
    final response = await _restDio.get(
      'banners',
      queryParameters: {
        'select': '*',
        'is_active': 'eq.true',
        'order': 'display_order.asc',
      },
    );
    final data = response.data as List;
    return data
        .map((e) => Banner.fromSupabaseJson(e as Map<String, dynamic>))
        .toList();
  }
}
