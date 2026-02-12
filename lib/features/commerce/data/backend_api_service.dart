import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';

class BackendApiService {
  final Dio _dio;

  /// Whether a real backend is configured (not localhost/emulator-only URLs).
  static bool get _hasRealBackend {
    const url = ApiConstants.backendBaseUrl;
    return !url.contains('10.0.2.2') &&
        !url.contains('localhost') &&
        !url.contains('127.0.0.1');
  }

  BackendApiService({Dio? dio})
      : _dio = dio ??
            DioClient.withBaseUrl(
              Platform.isIOS
                  ? ApiConstants.backendIosBaseUrl
                  : ApiConstants.backendBaseUrl,
            );

  /// GET commerces by location
  Future<List<Map<String, dynamic>>> fetchNearby({
    required double lat,
    required double lon,
    required double radius,
    String? query,
  }) async {
    if (!_hasRealBackend) throw Exception('No backend configured');
    try {
      final response = await _dio.get(
        'api/commerces',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'radius': radius,
          if (query != null) 'query': query,
        },
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Backend error: $e');
    }
  }

  /// GET commerces by ville
  Future<List<Map<String, dynamic>>> fetchByVille({
    required String ville,
    String? query,
  }) async {
    if (!_hasRealBackend) throw Exception('No backend configured');
    try {
      final response = await _dio.get(
        'api/commerces',
        queryParameters: {
          'ville': ville,
          if (query != null) 'query': query,
        },
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Backend error: $e');
    }
  }

  /// GET sync (incremental)
  Future<List<Map<String, dynamic>>> fetchSync({required int since}) async {
    if (!_hasRealBackend) throw Exception('No backend configured');
    try {
      final response = await _dio.get(
        'api/commerces/sync',
        queryParameters: {'since': since},
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Backend error: $e');
    }
  }

  /// POST new commerce
  Future<Map<String, dynamic>> addCommerce(Map<String, dynamic> data) async {
    if (!_hasRealBackend) throw Exception('No backend configured');
    try {
      final response = await _dio.post('api/commerces', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Backend error: $e');
    }
  }

  /// PUT update commerce
  Future<Map<String, dynamic>> updateCommerce(
    int id,
    Map<String, dynamic> data,
  ) async {
    if (!_hasRealBackend) throw Exception('No backend configured');
    try {
      final response = await _dio.put('api/commerces/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Backend error: $e');
    }
  }

  /// GET categories
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    if (!_hasRealBackend) throw Exception('No backend configured');
    try {
      final response = await _dio.get('api/categories');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Backend error: $e');
    }
  }

  /// GET villes
  Future<List<Map<String, dynamic>>> fetchVilles() async {
    if (!_hasRealBackend) throw Exception('No backend configured');
    try {
      final response = await _dio.get('api/villes');
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Backend error: $e');
    }
  }
}
