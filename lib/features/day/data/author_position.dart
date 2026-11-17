import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

/// Position d'un event publié, pour la recherche par distance des « À la
/// une » / « Top » (visibles jusqu'à `app_config.boosted_radius_km`). Sans
/// elle, la base placerait l'event au centre de sa ville hub, qui n'est pas
/// forcément la commune du lieu (auteur à Paris, event à Arbonne).
///
/// Ordre : géocodage de l'adresse + code postal (Géoplateforme IGN, service
/// public gratuit), sinon commune du code postal, sinon position GPS récente
/// de l'auteur, sinon rien (la base fait son propre calcul).
class AuthorPosition {
  AuthorPosition._();

  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://data.geopf.fr/geocodage/',
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
  ),);

  static final _cpRe = RegExp(r'^\d{5}$');
  static final _cpInText = RegExp(r'\b(\d{5})\b');

  /// Position de l'event décrit par [adresse] et [codePostal].
  static Future<({double lat, double lng})?> resolve({
    required String adresse,
    String codePostal = '',
    String pays = 'France',
  }) async {
    if (pays == 'France') {
      var cp = codePostal.trim();
      if (!_cpRe.hasMatch(cp)) cp = _cpInText.firstMatch(adresse)?.group(1) ?? '';
      final pos = await _geocode(adresse.trim(), cp);
      if (pos != null) return pos;
    }
    return _gps();
  }

  static Future<({double lat, double lng})?> _geocode(
    String adresse,
    String cp,
  ) async {
    try {
      if (adresse.length >= 3) {
        final hit = await _search({
          'q': adresse,
          if (cp.isNotEmpty) 'postcode': cp,
        });
        if (hit != null) {
          final props = hit.$3;
          final score = (props['score'] as num?)?.toDouble() ?? 0;
          final city = _fold(props['city'] as String? ?? '');
          // Avec code postal, le filtre `postcode` garantit la zone. Sans
          // lui, la commune trouvée doit être écrite dans l'adresse :
          // « 14 Port de l'Embouchoure » seul n'est pas placé au hasard.
          final trusted = cp.isNotEmpty
              ? score >= 0.3
              : score >= 0.5 && city.isNotEmpty && _fold(adresse).contains(city);
          if (trusted) return (lat: hit.$1, lng: hit.$2);
        }
      }
      if (cp.isNotEmpty) {
        final hit = await _search({'q': cp, 'type': 'municipality'});
        if (hit != null) return (lat: hit.$1, lng: hit.$2);
      }
    } catch (_) {}
    return null;
  }

  static Future<(double, double, Map<String, dynamic>)?> _search(
    Map<String, String> params,
  ) async {
    final r = await _dio.get<Map<String, dynamic>>(
      'search',
      queryParameters: {...params, 'limit': '1'},
    );
    final features = r.data?['features'] as List?;
    if (features == null || features.isEmpty) return null;
    final f = features.first as Map<String, dynamic>;
    final coords = (f['geometry'] as Map<String, dynamic>)['coordinates'] as List;
    return (
      (coords[1] as num).toDouble(),
      (coords[0] as num).toDouble(),
      f['properties'] as Map<String, dynamic>,
    );
  }

  /// Dernière position connue du téléphone si elle a moins de 2 h. Jamais
  /// de demande d'autorisation ni de réveil du GPS ici.
  static Future<({double lat, double lng})?> _gps() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return null;
      }
      final p = await Geolocator.getLastKnownPosition();
      if (p == null ||
          DateTime.now().difference(p.timestamp) > const Duration(hours: 2)) {
        return null;
      }
      return (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Ajoute `latitude` / `longitude` au JSON d'insertion. Renvoie true si la
  /// position a été mise.
  static bool addTo(
    Map<String, dynamic> json,
    ({double lat, double lng})? pos,
  ) {
    if (pos == null) return false;
    json['latitude'] = pos.lat;
    json['longitude'] = pos.lng;
    return true;
  }

  static String _fold(String s) {
    const from = 'àâäáãçéèêëíìîïñóòôöõúùûüÿœ';
    const to = 'aaaaaceeeeiiiinooooouuuuyo';
    final out = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      out.write(i >= 0 ? to[i] : ch);
    }
    return out.toString().replaceAll(RegExp('[^a-z0-9]'), '');
  }
}
