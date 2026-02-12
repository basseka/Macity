import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/features/city/domain/models/geo_commune.dart';

class CityApiService {
  final Dio _dio;

  CityApiService({Dio? dio})
      : _dio = dio ?? DioClient.withBaseUrl(ApiConstants.geoBaseUrl);

  /// Search communes from geo.api.gouv.fr
  Future<List<GeoCommune>> searchCommunes(String query) async {
    try {
      final response = await _dio.get(
        ApiConstants.geoCommunesEndpoint,
        queryParameters: {
          'nom': query,
          'fields': 'nom,code,codesPostaux,codeDepartement,codeRegion,population',
          'boost': 'population',
          'limit': 10,
        },
      );

      final data = response.data as List;
      return data
          .map((e) => GeoCommune.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to search communes: ${e.message}');
    }
  }
}
