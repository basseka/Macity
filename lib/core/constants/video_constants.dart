import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

/// Donnees du banner video par mode/ville.
class ModeBannerData {
  /// URL de la vidéo en streaming (mp4).
  final String videoUrl;

  /// URL externe optionnelle. Si non null, un bouton "En savoir plus"
  /// s'affiche sur le banner et le tap ouvre l'URL.
  final String? linkUrl;

  const ModeBannerData({required this.videoUrl, this.linkUrl});
}

/// Provider qui charge le banner pour le mode et la ville actuels.
/// Retourne null si aucune vidéo n'est configurée pour cette combinaison.
final modeBannerVideoProvider = FutureProvider<ModeBannerData?>((ref) async {
  final mode = ref.watch(currentModeProvider);
  final ville = ref.watch(selectedCityProvider);

  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());

    // Cherche d'abord la ligne specifique a la ville (ville ILIKE ...),
    // sinon retombe sur la ligne par defaut (ville = '*').
    // ORDER BY ville DESC = ville-specifique en premier (lettres > '*' en ASCII),
    // '*' apres. LIMIT 1 retourne la prio attendue.
    final response = await dio.get('mode_banners', queryParameters: {
      'select': 'video_url,link_url,ville',
      'mode': 'eq.$mode',
      'or': '(ville.ilike.$ville,ville.eq.*)',
      'is_active': 'eq.true',
      'order': 'ville.desc',
      'limit': '1',
    });

    final data = response.data as List;
    if (data.isNotEmpty) {
      final row = data.first as Map<String, dynamic>;
      final video = row['video_url'] as String?;
      if (video == null || video.isEmpty) return null;
      final link = row['link_url'] as String?;
      return ModeBannerData(
        videoUrl: video,
        linkUrl: (link != null && link.isNotEmpty) ? link : null,
      );
    }
    return null;
  } catch (_) {
    // Fallback hardcodé si Supabase inaccessible (pas de link_url côté fallback)
    final fallback = _fallbackUrl(mode, ville);
    if (fallback == null) return null;
    return ModeBannerData(videoUrl: fallback);
  }
});

/// Fallback statique en cas d'erreur réseau.
String? _fallbackUrl(String modeName, String ville) {
  const base = 'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/videos/banners';
  final key = '${modeName}_${ville.toLowerCase()}';
  const cityVideos = {
    'day_toulouse': '$base/day.mp4',
    'sport_toulouse': '$base/sport.mp4',
    'culture_toulouse': '$base/culture.mp4',
    'family_toulouse': '$base/family.mp4',
    'food_toulouse': '$base/food.mp4',
    'gaming_toulouse': '$base/gaming.mp4',
    'night_toulouse': '$base/night.mp4',
    'tourisme_toulouse': '$base/tourisme_toulouse.mp4',
    'tourisme_montpellier': '$base/tourisme_montpellier.mp4',
  };
  return cityVideos[key];
}

// Gardé pour compatibilité si utilisé ailleurs
class VideoConstants {
  VideoConstants._();

  static String? bannerVideoUrl(AppMode mode, String ville) {
    return _fallbackUrl(mode.name, ville);
  }
}
