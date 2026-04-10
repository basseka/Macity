/// Coordonnees centrales (lat, lng) des villes supportees par l'app, utilisees
/// pour filtrer les signalements par bounding box autour de la ville selectionnee.
///
/// Le bounding box est de ~25 km de rayon ce qui couvre la metropole entiere
/// (ex: Toulouse couvre Balma, Montrabe, Colomiers, Tournefeuille, etc.).
class CityCenters {
  CityCenters._();

  /// Mapping ville (lowercase, sans accent) -> (lat, lng).
  static const Map<String, ({double lat, double lng})> _centers = {
    'aix-en-provence': (lat: 43.5297, lng: 5.4474),
    'amiens': (lat: 49.8941, lng: 2.2958),
    'angers': (lat: 47.4784, lng: -0.5632),
    'annecy': (lat: 45.8992, lng: 6.1294),
    'avignon': (lat: 43.9493, lng: 4.8055),
    'bayonne': (lat: 43.4929, lng: -1.4748),
    'besancon': (lat: 47.2380, lng: 6.0244),
    'blois': (lat: 47.5860, lng: 1.3359),
    'bordeaux': (lat: 44.8378, lng: -0.5792),
    'brest': (lat: 48.3904, lng: -4.4861),
    'carcassonne': (lat: 43.2130, lng: 2.3491),
    'chartres': (lat: 48.4439, lng: 1.4895),
    'clermont-ferrand': (lat: 45.7772, lng: 3.0870),
    'colmar': (lat: 48.0794, lng: 7.3585),
    'dijon': (lat: 47.3220, lng: 5.0415),
    'geneve': (lat: 46.2044, lng: 6.1432),
    'grenoble': (lat: 45.1885, lng: 5.7245),
    'le havre': (lat: 49.4944, lng: 0.1079),
    'le mans': (lat: 48.0061, lng: 0.1996),
    'lille': (lat: 50.6292, lng: 3.0573),
    'lyon': (lat: 45.7640, lng: 4.8357),
    'marseille': (lat: 43.2965, lng: 5.3698),
    'metz': (lat: 49.1193, lng: 6.1757),
    'montpellier': (lat: 43.6108, lng: 3.8767),
    'nancy': (lat: 48.6921, lng: 6.1844),
    'nantes': (lat: 47.2184, lng: -1.5536),
    'nice': (lat: 43.7102, lng: 7.2620),
    'nimes': (lat: 43.8367, lng: 4.3601),
    'paris': (lat: 48.8566, lng: 2.3522),
    'reims': (lat: 49.2583, lng: 4.0317),
    'rennes': (lat: 48.1173, lng: -1.6778),
    'rouen': (lat: 49.4432, lng: 1.0993),
    'saint-etienne': (lat: 45.4397, lng: 4.3872),
    'strasbourg': (lat: 48.5734, lng: 7.7521),
    'toulon': (lat: 43.1242, lng: 5.9280),
    'toulouse': (lat: 43.6047, lng: 1.4442),
  };

  /// Rayon de filtrage autour du centre ville (degres).
  /// 0.25 lat = ~27 km. 0.35 lng = ~26-28 km selon la latitude.
  /// Couvre toute la metropole / agglo de la ville.
  static const double _deltaLat = 0.25;
  static const double _deltaLng = 0.35;

  /// Retourne le centre d'une ville, ou null si inconnue.
  static ({double lat, double lng})? center(String city) {
    final key = _normalize(city);
    return _centers[key];
  }

  /// Retourne la bounding box (min/max lat et lng) pour filtrer les
  /// signalements autour d'une ville. Renvoie null si la ville est inconnue.
  static ({double minLat, double maxLat, double minLng, double maxLng})? boundingBox(
    String city,
  ) {
    final c = center(city);
    if (c == null) return null;
    return (
      minLat: c.lat - _deltaLat,
      maxLat: c.lat + _deltaLat,
      minLng: c.lng - _deltaLng,
      maxLng: c.lng + _deltaLng,
    );
  }

  static String _normalize(String city) {
    return city
        .toLowerCase()
        .trim()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c');
  }
}
