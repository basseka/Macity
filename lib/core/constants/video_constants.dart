import 'package:pulz_app/features/mode/domain/models/app_mode.dart';

class VideoConstants {
  VideoConstants._();

  // Supabase Storage base URL (replace demo URLs when videos are uploaded)
  // static const String _baseUrl =
  //     'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/videos/banners';

  // Demo videos from Mixkit (free, no watermark, open license)
  static const Map<AppMode, String> bannerVideos = {
    // Concert crowd jumping
    AppMode.day: 'https://assets.mixkit.co/videos/14084/14084-360.mp4',
    // Basketball player training
    AppMode.sport: 'https://assets.mixkit.co/videos/44448/44448-360.mp4',
    // Artist painting close-up
    AppMode.culture: 'https://assets.mixkit.co/videos/40310/40310-360.mp4',
    // Family walking in the park
    AppMode.family: 'https://assets.mixkit.co/videos/33729/33729-360.mp4',
    // Vegetables into the pan
    AppMode.food: 'https://assets.mixkit.co/videos/49231/49231-720.mp4',
    // Hands gaming on keyboard
    AppMode.gaming: 'https://assets.mixkit.co/videos/43527/43527-360.mp4',
    // Girl dancing at nightclub
    AppMode.night: 'https://assets.mixkit.co/videos/348/348-360.mp4',
  };
}
