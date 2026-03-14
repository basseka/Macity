import 'package:pulz_app/features/mode/domain/models/app_mode.dart';

class VideoConstants {
  VideoConstants._();

  static const String _baseUrl =
      'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/videos/banners';

  /// Videos par mode et ville. Clé = 'mode_ville' en minuscules.
  /// Fallback : si pas de vidéo pour la ville, on utilise la vidéo par défaut du mode.
  static const Map<String, String> _cityVideos = {
    // Toulouse
    'day_toulouse': '$_baseUrl/day.mp4',
    'sport_toulouse': '$_baseUrl/sport.mp4',
    'culture_toulouse': '$_baseUrl/culture.mp4',
    'family_toulouse': '$_baseUrl/family.mp4',
    'food_toulouse': '$_baseUrl/food.mp4',
    'gaming_toulouse': '$_baseUrl/gaming.mp4',
    'night_toulouse': '$_baseUrl/night.mp4',
    'tourisme_toulouse': '$_baseUrl/tourisme_toulouse.mp4',
    // Montpellier
    'tourisme_montpellier': '$_baseUrl/tourisme_montpellier.mp4',
  };

  /// Vidéos par défaut (fallback quand pas de vidéo ville-spécifique).
  static const Map<AppMode, String> _defaultVideos = {
    AppMode.day: '$_baseUrl/day.mp4',
    AppMode.sport: '$_baseUrl/sport.mp4',
    AppMode.culture: '$_baseUrl/culture.mp4',
    AppMode.family: '$_baseUrl/family.mp4',
    AppMode.food: '$_baseUrl/food.mp4',
    AppMode.gaming: '$_baseUrl/gaming.mp4',
    AppMode.night: '$_baseUrl/night.mp4',
    AppMode.tourisme: '$_baseUrl/tourisme_toulouse.mp4',
  };

  /// Retourne l'URL de la vidéo banner pour un mode et une ville.
  static String? bannerVideoUrl(AppMode mode, String ville) {
    final key = '${mode.name}_${ville.toLowerCase()}';
    return _cityVideos[key] ?? _defaultVideos[mode];
  }
}
