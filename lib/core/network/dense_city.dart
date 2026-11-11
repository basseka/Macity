import 'package:dio/dio.dart';
import 'package:pulz_app/core/utils/haversine.dart';
import 'package:pulz_app/features/city/data/city_coordinates.dart';

/// Villes trop fournies pour être chargées en entier : PostgREST coupe les
/// réponses à 1 000 lignes, et Paris compte plusieurs milliers de lieux.
/// Les listes de lieux y sont limitées à un rayon autour de la zone courante
/// (position GPS, sinon centre de la ville choisie).
class DenseCity {
  DenseCity._();

  static const _cities = {'paris'};

  /// Rayon (km) par table : la Food est la plus dense.
  static const _radiusKm = {
    'etablissements': 1.5,
    'venues': 2.5,
    'family_venues': 3.0,
    'sport_venues': 2.5,
  };

  static final _villeRe = RegExp(r'^(?:ilike|eq)\.([^*]+)\*?$');

  static bool isDense(String ville) => _cities.contains(ville.toLowerCase());

  /// Ajoute le filtre de rayon aux requêtes de liste (ou de compte) d'une
  /// ville dense. Les recherches par nom (`or`), les requêtes déjà bornées
  /// (`and`) et les fiches par id ne sont pas touchées.
  static void apply(RequestOptions o) {
    if (o.method != 'GET') return;
    final segs = Uri.parse(o.path).pathSegments;
    if (segs.isEmpty) return;
    final radius = _radiusKm[segs.last];
    if (radius == null) return;
    final qp = o.queryParameters;
    final ville = qp['ville'];
    if (ville is! String) return;
    if (qp.containsKey('and') || qp.containsKey('or') || qp.containsKey('id')) {
      return;
    }
    final m = _villeRe.firstMatch(ville);
    if (m == null || !isDense(m.group(1)!)) return;
    final c = CityCoordinates.maybeOf(m.group(1)!);
    if (c == null) return;
    o.queryParameters = {
      ...qp,
      'and': Haversine.bboxFilter(c.lat, c.lng, radius),
    };
  }
}
