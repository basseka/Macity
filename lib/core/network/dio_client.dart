import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';

class DioClient {
  DioClient._();

  static final Dio _instance = _createDio();

  static Dio get instance => _instance;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('[DIO] $obj'),
    ),);

    return dio;
  }

  /// Create a Dio instance with a specific base URL
  static Dio withBaseUrl(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => debugPrint('[DIO] $obj'),
    ),);

    return dio;
  }
}
