import 'package:pulz_app/features/commerce/domain/models/commerce.dart';

/// Composition du groupe : oriente le choix des restaurants et activites.
enum TripGroup { couple, famille, amis }

/// Repas pris a l'exterieur.
enum TripMeal { matin, midi, soir }

/// Sortie du soir apres le diner.
enum TripNight { none, bar, barClub }

/// Style musical souhaite pour la discotheque. Le nom de chaque valeur
/// (sauf [any]) est la cle stockee dans `venues.music_genres`.
enum TripMusic { any, electro, hiphop, latino, generaliste, rock }

/// Type d'etape de la feuille de route.
enum TripStopKind { breakfast, lunch, dinner, activity, drink, club }

/// Reponses au questionnaire « Organiser mon trip ».
class TripAnswers {
  final TripGroup group;
  final int people;
  final int days;
  final Set<TripMeal> meals;
  final bool activities;
  final TripNight night;
  /// Styles voulus (plusieurs possibles). Vide = peu importe.
  final Set<TripMusic> music;

  const TripAnswers({
    required this.group,
    required this.people,
    required this.days,
    required this.meals,
    required this.activities,
    this.night = TripNight.none,
    this.music = const {},
  });
}

/// Lieu candidat pour une etape, deja converti pour la fiche detail.
class TripCandidate {
  /// Cle unique toutes tables confondues (evite les doublons sur le sejour).
  final String key;
  final CommerceModel commerce;
  final bool isPartner;
  final int priority;

  /// 1 si le lieu correspond bien au groupe (theme, type d'activite).
  final int affinity;

  const TripCandidate({
    required this.key,
    required this.commerce,
    required this.isPartner,
    required this.priority,
    required this.affinity,
  });
}

class TripStop {
  final TripStopKind kind;
  final String slot;
  final TripCandidate candidate;

  const TripStop({required this.kind, required this.slot, required this.candidate});

  TripStop withCandidate(TripCandidate c) =>
      TripStop(kind: kind, slot: slot, candidate: c);
}

class TripDay {
  final int index;
  final List<TripStop> stops;

  const TripDay({required this.index, required this.stops});
}

class TripPlan {
  final TripAnswers answers;
  final List<TripDay> days;
  final int seed;

  /// Lieux deja refuses via « Changer », par etape ('jour:etape').
  final Map<String, Set<String>> rejected = {};

  TripPlan({required this.answers, required this.days, required this.seed});

  bool get isEmpty => days.every((d) => d.stops.isEmpty);
}
