import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/mode/domain/models/app_mode.dart';
import 'package:pulz_app/features/mode/state/mode_provider.dart';

/// Provider qui charge l'URL vidéo banner pour le mode et la ville actuels.
/// Retourne null si aucune vidéo n'est configurée pour cette combinaison.
final modeBannerVideoProvider = FutureProvider<String?>((ref) async {
  final mode = ref.watch(currentModeProvider);
  final ville = ref.watch(selectedCityProvider);

  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());

    final response = await dio.get('mode_banners', queryParameters: {
      'select': 'video_url',
      'mode': 'eq.$mode',
      'ville': 'ilike.$ville',
      'is_active': 'eq.true',
      'limit': '1',
    });

    final data = response.data as List;
    if (data.isNotEmpty) {
      return data.first['video_url'] as String?;
    }
    return null;
  } catch (_) {
    // Fallback hardcodé si Supabase inaccessible
    return _fallbackUrl(mode, ville);
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
