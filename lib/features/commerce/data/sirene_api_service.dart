import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/features/commerce/data/sirene_token_manager.dart';

class SireneApiService {
  final Dio _dio;
  final SireneTokenManager _tokenManager;

  SireneApiService({
    Dio? dio,
    SireneTokenManager? tokenManager,
  })  : _dio = dio ?? DioClient.withBaseUrl(ApiConstants.sireneBaseUrl),
        _tokenManager = tokenManager ?? SireneTokenManager();

  /// Search SIRENE by query
  Future<List<Map<String, dynamic>>> searchEtablissements({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await _tokenManager.getAccessToken();
    if (token == null) throw Exception('No SIRENE token available');

    try {
      final response = await _dio.get(
        ApiConstants.sireneEndpoint,
        queryParameters: {
          'q': query,
          'nombre': limit,
          'debut': offset,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final etablissements =
          response.data['etablissements'] as List? ?? [];
      return etablissements.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception('Failed to search SIRENE: ${e.message}');
    }
  }
}
