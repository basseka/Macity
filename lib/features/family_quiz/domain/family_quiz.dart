import 'dart:math';

import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';

/// « Trouver mon activité » (rubrique Famille, 2026-11-22) : 4 questions
/// (âge des enfants, envies, dedans ou dehors, quand) puis des propositions
/// par envie : events famille de la période et lieux `family_venues`.

/// Tranches d'âge. [maxAge] = âge le plus élevé de la tranche ; le plus
/// petit des enfants sélectionnés fixe l'âge minimum accepté d'un lieu.
enum FamilyAge {
  baby(3),
  small(6),
  kids(10),
  teens(99);

  final int maxAge;
  const FamilyAge(this.maxAge);
}

enum FamilyWish { move, animals, discover, show, water, creative }

enum FamilyWhere { indoor, outdoor, any }

enum FamilyWhen { today, weekend, week }

class FamilyAnswers {
  final Set<FamilyAge> ages;
  final Set<FamilyWish> wishes;
  final FamilyWhere where;
  final FamilyWhen when;

  const FamilyAnswers({
    required this.ages,
    required this.wishes,
    required this.where,
    required this.when,
  });

  /// Âge du plus jeune : un lieu « dès 8 ans » n'est pas proposé avec un
  /// enfant de 3-6 ans.
  int get youngestMax =>
      ages.isEmpty ? 99 : ages.map((a) => a.maxAge).reduce(min);

  bool get onlyTeens => ages.length == 1 && ages.first == FamilyAge.teens;
}

class FamilySection {
  final FamilyWish wish;
  final List<Event> events;
  final List<FamilyVenue> places;

  const FamilySection({
    required this.wish,
    this.events = const [],
    this.places = const [],
  });

  bool get isEmpty => events.isEmpty && places.isEmpty;
}

class FamilyQuizEngine {
  static const maxEvents = 5;
  static const maxPlaces = 4;

  /// Types de lieux (`family_venues.category`) par envie.
  static const _wishCategories = <FamilyWish, List<String>>{
    FamilyWish.move: [
      'Laser game',
      'Escape game',
      'Bowling',
      'Patinoire',
      'Aire de jeux',
      'Parc de loisirs',
      'Accrobranche',
      'Mini golf',
      "Parc d'attractions",
    ],
    FamilyWish.animals: [
      'Parc animalier',
      'Ferme pedagogique',
      'Zoo',
      'Aquarium',
      'Jardin botanique',
      'Parcs',
      'Balade familiale',
    ],
    FamilyWish.discover: ['Musee pour enfants', 'Planetarium', 'Aquarium'],
    FamilyWish.show: ['Cinema'],
    FamilyWish.water: [
      'Centre aquatique',
      'Piscine',
      'Aquarium',
      'Base de loisirs'
    ],
    FamilyWish.creative: ['Atelier creatif'],
  };

  /// Mots-clés cherchés dans le titre, la catégorie et le type des events.
  static const _wishEventWords = <FamilyWish, List<String>>{
    FamilyWish.move: [
      'sport',
      'jeu',
      'olympiade',
      'trampoline',
      'escalade',
      'laser',
      'patin',
      'kermesse',
      'chasse au',
    ],
    FamilyWish.animals: [
      'animal',
      'animaux',
      'ferme',
      'nature',
      'balade',
      'jardin',
      'zoo',
      'oiseau',
      'forêt',
      'foret',
    ],
    FamilyWish.discover: [
      'musée',
      'musee',
      'expo',
      'visite',
      'patrimoine',
      'science',
      'découverte',
      'decouverte',
      'planétarium',
    ],
    FamilyWish.show: [
      'spectacle',
      'théâtre',
      'theatre',
      'conte',
      'marionnette',
      'cirque',
      'cinéma',
      'cinema',
      'concert',
      'magie',
      'ventriloqu',
      'impro',
    ],
    FamilyWish.water: ['piscine', 'aqua', 'nautique', 'baignade'],
    FamilyWish.creative: [
      'atelier',
      'stage',
      'créati',
      'creati',
      'bricolage',
      'diy',
      'cuisine',
      'peinture',
      'dessin',
      'poterie',
    ],
  };

  /// Lieux en intérieur ; les autres types sont considérés en plein air.
  static const _indoor = {
    'Laser game',
    'Escape game',
    'Bowling',
    'Cinema',
    'Patinoire',
    'Aquarium',
    'Centre aquatique',
    'Piscine',
    'Musee pour enfants',
    'Planetarium',
    'Atelier creatif',
    'Parc de loisirs',
  };

  /// Jamais proposés avec un enfant de moins de 3 ans.
  static const _notForBabies = {'Laser game', 'Escape game', 'Accrobranche'};

  /// Plus de l'âge des ados.
  static const _notForTeens = {'Aire de jeux'};

  /// Âge minimum lu dans le texte d'un event (« dès 8 ans », « Âge : 6 ans »).
  static final _ageRe = RegExp(
    r'(?:dès|des|à partir de|a partir de|âge\s*:|age\s*:)\s*(\d{1,2})\s*ans',
    caseSensitive: false,
  );

  static int? eventMinAge(Event e) {
    final m = _ageRe.firstMatch('${e.titre} ${e.descriptifCourt}');
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  /// Période couverte par [when] (bornes incluses, dates sans heure).
  static (DateTime, DateTime) period(FamilyWhen when, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (when) {
      case FamilyWhen.today:
        return (today, today);
      case FamilyWhen.weekend:
        // Samedi = 6, dimanche = 7. Le week-end en cours si on y est déjà.
        final wd = today.weekday;
        final start =
            wd >= DateTime.saturday ? today : today.add(Duration(days: 6 - wd));
        final end = start.add(Duration(days: 7 - start.weekday));
        return (start, end);
      case FamilyWhen.week:
        return (today, today.add(const Duration(days: 6)));
    }
  }

  static DateTime? _day(String s) {
    final d = DateTime.tryParse(s);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  static bool _inPeriod(Event e, DateTime start, DateTime end) {
    final debut = _day(e.dateDebut);
    if (debut == null) return false;
    final fin = _day(e.dateFin) ?? debut;
    return !debut.isAfter(end) && !fin.isBefore(start);
  }

  static bool _has(String text, List<String> words) {
    final t = text.toLowerCase();
    return words.any(t.contains);
  }

  bool _placeFits(FamilyVenue v, FamilyAnswers a) {
    if (a.where == FamilyWhere.indoor && !_indoor.contains(v.category)) {
      return false;
    }
    if (a.where == FamilyWhere.outdoor && _indoor.contains(v.category)) {
      return false;
    }
    if (v.ageMin != null && v.ageMin! > a.youngestMax) return false;
    if (a.ages.contains(FamilyAge.baby) &&
        _notForBabies.contains(v.category)) {
      return false;
    }
    if (a.onlyTeens && _notForTeens.contains(v.category)) return false;
    return true;
  }

  /// Partenaires d'abord, puis lieux avec photo, avec une part d'aléatoire
  /// ([seed]) pour varier les propositions.
  List<FamilyVenue> _rank(List<FamilyVenue> list, int seed) {
    final rnd = Random(seed);
    final scored = list
        .map(
          (v) => (
            v,
            (v.isPartner ? 100 : 0) +
                (v.photo.startsWith('http') ? 20 : 0) +
                rnd.nextInt(40),
          ),
        )
        .toList()
      ..sort((x, y) => y.$2.compareTo(x.$2));
    return scored.map((s) => s.$1).take(maxPlaces).toList();
  }

  /// Une section par envie choisie. Un lieu ou un event n'apparaît qu'une
  /// fois (dans la première envie qui le propose).
  List<FamilySection> build(
    FamilyAnswers a, {
    required List<FamilyVenue> venues,
    required List<Event> events,
    int seed = 0,
    DateTime? now,
  }) {
    final (start, end) = period(a.when, now ?? DateTime.now());
    final periodEvents = events.where((e) {
      if (!_inPeriod(e, start, end)) return false;
      final minAge = eventMinAge(e);
      return minAge == null || minAge <= a.youngestMax;
    }).toList();

    final usedEvents = <String>{};
    final usedPlaces = <int>{};
    final sections = <FamilySection>[];
    for (final wish in FamilyWish.values.where(a.wishes.contains)) {
      final s = seed + wish.index * 7;
      final words = _wishEventWords[wish]!;
      final evs = periodEvents
          .where((e) =>
              !usedEvents.contains(e.identifiant) &&
              _has('${e.titre} ${e.categorie} ${e.type}', words))
          .toList()
        ..shuffle(Random(s));
      final pickedEvents = evs.take(maxEvents).toList();
      usedEvents.addAll(pickedEvents.map((e) => e.identifiant));

      final cats = _wishCategories[wish]!;
      final places = _rank(
        venues
            .where((v) =>
                cats.contains(v.category) &&
                !usedPlaces.contains(v.id) &&
                _placeFits(v, a))
            .toList(),
        s,
      );
      usedPlaces.addAll(places.map((v) => v.id));

      sections.add(
          FamilySection(wish: wish, events: pickedEvents, places: places));
    }
    return sections;
  }
}
