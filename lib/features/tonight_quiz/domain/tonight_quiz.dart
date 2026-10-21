import 'package:pulz_app/core/l10n/locale_provider.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Avec qui on sort : masque les choix inadaptés (pas de bar ni de soirée
/// en famille) et oriente l'ordre des balades.
enum TonightGroup { solo, couple, amis, famille }

/// Envies proposées à la 2e question (plusieurs possibles).
enum TonightWish { concert, soiree, cocktail, balade, activite, spectacle }

/// Créneau souhaité : filtre les events par heure de début.
enum TonightWhen { now, afterDinner, late }

class TonightAnswers {
  final TonightGroup group;
  final Set<TonightWish> wishes;
  final TonightWhen when;

  const TonightAnswers({
    required this.group,
    required this.wishes,
    required this.when,
  });
}

/// Balade du soir (table `night_walks`, trouvée par l'IA via l'edge function
/// generate-night-walks, éditable dans admin.html).
class NightWalk {
  final int id;
  final String titre;
  final String description;
  final String depart;
  final double latitude;
  final double longitude;
  final int dureeMin;
  final double distanceKm;
  final String ambiance;
  final String photo;

  const NightWalk({
    required this.id,
    required this.titre,
    required this.description,
    required this.depart,
    required this.latitude,
    required this.longitude,
    required this.dureeMin,
    required this.distanceKm,
    required this.ambiance,
    required this.photo,
  });

  /// Titre et description dans la langue de l'app (fr par défaut).
  factory NightWalk.fromJson(Map<String, dynamic> j) {
    String tr(String key) {
      final fr = (j[key] as String?) ?? '';
      if (currentContentLanguage == 'fr') return fr;
      final t = j['${key}_$currentContentLanguage'] as String?;
      return (t != null && t.trim().isNotEmpty) ? t : fr;
    }

    return NightWalk(
      id: (j['id'] as num?)?.toInt() ?? 0,
      titre: tr('titre'),
      description: tr('description'),
      depart: (j['depart'] as String?) ?? '',
      latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
      dureeMin: (j['duree_min'] as num?)?.toInt() ?? 0,
      distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
      ambiance: (j['ambiance'] as String?) ?? '',
      photo: (j['photo'] as String?) ?? '',
    );
  }
}

/// Propositions pour une envie : events de ce soir, lieux, balades.
/// [eventsOtherTime] : aucun event au créneau choisi, on montre ceux de
/// la soirée à d'autres heures (l'écran le signale).
class TonightSection {
  final TonightWish wish;
  final List<Event> events;
  final bool eventsOtherTime;
  final List<CommerceModel> places;
  final List<NightWalk> walks;

  const TonightSection({
    required this.wish,
    this.events = const [],
    this.eventsOtherTime = false,
    this.places = const [],
    this.walks = const [],
  });

  bool get isEmpty => events.isEmpty && places.isEmpty && walks.isEmpty;
}
