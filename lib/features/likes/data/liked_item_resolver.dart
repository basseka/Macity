import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/night/data/night_bars_data.dart';

/// Prefixes connus pour les commerces likes.
const _commercePrefixes = [
  'night_',
  'food_',
  'culture_',
  'family_',
  'sport_',
  'gaming_',
];

/// Resout un likeId vers un [CommerceModel] ou un [Event].
class LikedItemResolver {
  LikedItemResolver._();

  /// `true` si le likeId correspond a un commerce (prefixe connu).
  static bool isCommerce(String likeId) {
    return _commercePrefixes.any((p) => likeId.startsWith(p));
  }

  /// Cherche le commerce correspondant au likeId dans NightBarsData.
  static CommerceModel? resolveCommerce(String likeId) {
    // Extraire le nom apres le prefixe
    String? name;
    for (final prefix in _commercePrefixes) {
      if (likeId.startsWith(prefix)) {
        name = likeId.substring(prefix.length);
        break;
      }
    }
    if (name == null) return null;

    // Chercher dans NightBarsData (seule source commerce utilisee dans les likes)
    for (final bar in NightBarsData.toulouseBars) {
      if (bar.nom == name) return bar;
    }
    return null;
  }

  /// Les events likes provenant des scrapers sont maintenant dans la DB.
  /// La resolution se fait au niveau du provider (via ScrapedEventsSupabaseService).
  /// Cette methode retourne null car les curated lists n'existent plus.
  static Event? resolveEvent(String likeId) {
    if (isCommerce(likeId)) return null;
    return null;
  }
}
