import 'package:pulz_app/features/mode/domain/models/app_mode.dart';

class VideoConstants {
  VideoConstants._();

  static const String _baseUrl =
      'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/videos/banners';

  static const Map<AppMode, String> bannerVideos = {
    AppMode.day: '$_baseUrl/day.mp4',
    AppMode.sport: '$_baseUrl/sport.mp4',
    AppMode.culture: '$_baseUrl/culture.mp4',
    AppMode.family: '$_baseUrl/family.mp4',
    AppMode.food: '$_baseUrl/food.mp4',
    AppMode.gaming: '$_baseUrl/gaming.mp4',
    AppMode.night: '$_baseUrl/night.mp4',
  };
}
