/// Coordonnees geographiques approximatives (centre-ville) des villes
/// supportees par l'app. Sert de fallback pour le centrage des cartes
/// quand aucun point/venue n'a encore de coordonnees pour la ville.
///
/// Inclut metropole + DOM-TOM (Martinique, Guadeloupe, Guyane, Reunion,
/// Mayotte). Toulouse en fallback ultime si la ville n'est pas connue.
class CityCoordinates {
  CityCoordinates._();

  static const Map<String, ({double lat, double lng})> _coords = {
    // Metropole
    'Aix-en-Provence': (lat: 43.5297, lng: 5.4474),
    'Amiens': (lat: 49.8941, lng: 2.2958),
    'Angers': (lat: 47.4784, lng: -0.5632),
    'Annecy': (lat: 45.8992, lng: 6.1294),
    'Avignon': (lat: 43.9493, lng: 4.8055),
    'Bayonne': (lat: 43.4929, lng: -1.4748),
    'Besancon': (lat: 47.2378, lng: 6.0241),
    'Blois': (lat: 47.5862, lng: 1.3359),
    'Bordeaux': (lat: 44.8378, lng: -0.5792),
    'Brest': (lat: 48.3905, lng: -4.4860),
    'Carcassonne': (lat: 43.2130, lng: 2.3491),
    'Chartres': (lat: 48.4467, lng: 1.4894),
    'Clermont-Ferrand': (lat: 45.7772, lng: 3.0870),
    'Colmar': (lat: 48.0793, lng: 7.3589),
    'Dijon': (lat: 47.3220, lng: 5.0415),
    'Geneve': (lat: 46.2044, lng: 6.1432),
    'Grenoble': (lat: 45.1885, lng: 5.7245),
    'Le Havre': (lat: 49.4944, lng: 0.1079),
    'Le Mans': (lat: 48.0061, lng: 0.1996),
    'Lille': (lat: 50.6293, lng: 3.0573),
    'Lyon': (lat: 45.7640, lng: 4.8357),
    'Marseille': (lat: 43.2965, lng: 5.3698),
    'Metz': (lat: 49.1193, lng: 6.1757),
    'Montpellier': (lat: 43.6109, lng: 3.8767),
    'Nancy': (lat: 48.6921, lng: 6.1844),
    'Nantes': (lat: 47.2184, lng: -1.5536),
    'Nice': (lat: 43.7102, lng: 7.2620),
    'Nimes': (lat: 43.8367, lng: 4.3601),
    'Paris': (lat: 48.8566, lng: 2.3522),
    'Reims': (lat: 49.2583, lng: 4.0317),
    'Rennes': (lat: 48.1173, lng: -1.6778),
    'Rouen': (lat: 49.4432, lng: 1.0993),
    'Saint-Etienne': (lat: 45.4397, lng: 4.3872),
    'Strasbourg': (lat: 48.5734, lng: 7.7521),
    'Toulon': (lat: 43.1242, lng: 5.9282),
    'Toulouse': (lat: 43.6047, lng: 1.4442),
    // DOM-TOM
    'Fort-de-France': (lat: 14.6037, lng: -61.0594),
    'Pointe-a-Pitre': (lat: 16.2410, lng: -61.5341),
    'Cayenne': (lat: 4.9344, lng: -52.3358),
    'Saint-Denis': (lat: -20.8789, lng: 55.4481),
    'Mamoudzou': (lat: -12.7806, lng: 45.2272),
  };

  /// Retourne les coordonnees du centre-ville, ou Toulouse en fallback.
  static ({double lat, double lng}) of(String city) =>
      _coords[city] ?? _coords['Toulouse']!;
}
