import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';

class OverpassApiService {
  final Dio _dio;
  final Dio _fallbackDio;

  OverpassApiService({Dio? dio, Dio? fallbackDio})
      : _dio = dio ?? DioClient.withBaseUrl(ApiConstants.overpassBaseUrl),
        _fallbackDio =
            fallbackDio ?? DioClient.withBaseUrl(ApiConstants.overpassFallbackBaseUrl);

  /// Execute an Overpass QL query
  Future<List<Map<String, dynamic>>> query(String overpassQl) async {
    try {
      return await _executeQuery(_dio, overpassQl);
    } catch (_) {
      // Fallback to mirror
      return _executeQuery(_fallbackDio, overpassQl);
    }
  }

  Future<List<Map<String, dynamic>>> _executeQuery(
    Dio dio,
    String overpassQl,
  ) async {
    final response = await dio.post(
      ApiConstants.overpassEndpoint,
      data: 'data=$overpassQl',
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
      ),
    );

    final elements = response.data['elements'] as List? ?? [];
    return elements.cast<Map<String, dynamic>>();
  }

  /// Build address from OSM tags
  static String buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    final housenumber = tags['addr:housenumber'];
    final street = tags['addr:street'];
    final postcode = tags['addr:postcode'];
    final city = tags['addr:city'];

    if (housenumber != null) parts.add(housenumber.toString());
    if (street != null) parts.add(street.toString());
    if (postcode != null) parts.add(postcode.toString());
    if (city != null) parts.add(city.toString());

    return parts.join(', ');
  }

  /// Resolve photo URL from OSM tags
  static String? resolvePhoto(Map<String, dynamic> tags) {
    final image = tags['image'];
    if (image != null && (image.startsWith('http://') || image.startsWith('https://'))) {
      return image;
    }

    final wikimedia = tags['wikimedia_commons'];
    if (wikimedia != null) {
      final filename = wikimedia.replaceFirst('File:', '');
      return 'https://commons.wikimedia.org/wiki/Special:FilePath/$filename?width=300';
    }

    return null;
  }
}
