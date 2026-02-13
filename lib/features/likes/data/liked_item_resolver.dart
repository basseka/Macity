import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/night/data/night_bars_data.dart';
import 'package:pulz_app/features/day/data/concert_toulouse_service.dart';
import 'package:pulz_app/features/day/data/festival_toulouse_service.dart';
import 'package:pulz_app/features/day/data/spectacle_toulouse_service.dart';
import 'package:pulz_app/features/day/data/showcase_toulouse_service.dart';
import 'package:pulz_app/features/day/data/opera_toulouse_service.dart';
import 'package:pulz_app/features/day/data/djset_toulouse_service.dart';

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

  /// Cherche l'event correspondant au likeId (= identifiant) dans toutes
  /// les sources curatees.
  static Event? resolveEvent(String likeId) {
    // Ne pas chercher si c'est un commerce
    if (isCommerce(likeId)) return null;

    final allCurated = <List<Event>>[
      ConcertToulouseService.curatedConcerts,
      FestivalToulouseService.curatedFestivals,
      SpectacleToulouseService.curatedSpectacles,
      ShowcaseToulouseService.curatedShowcases,
      OperaToulouseService.curatedOperas,
      DjSetToulouseService.curatedDjSets,
    ];

    for (final list in allCurated) {
      for (final event in list) {
        if (event.identifiant == likeId) return event;
      }
    }
    return null;
  }
}
