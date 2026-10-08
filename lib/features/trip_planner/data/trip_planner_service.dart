import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/family/data/family_venues_supabase_service.dart';
import 'package:pulz_app/features/family/domain/models/family_venue.dart';
import 'package:pulz_app/features/family/presentation/widgets/family_venue_row_card.dart';
import 'package:pulz_app/features/food/data/restaurant_supabase_service.dart';
import 'package:pulz_app/features/food/data/restaurant_venues_data.dart';
import 'package:pulz_app/features/food/presentation/restaurant_detail_sheet.dart';
import 'package:pulz_app/features/trip_planner/domain/trip_plan.dart';

/// Compose une feuille de route a partir des lieux en base de la ville :
/// restaurants (`etablissements`), activites (`family_venues`, `venues`
/// culture) et bars (`venues` night). Aucun lieu n'est repete sur le sejour.
///
/// Classement : partenaire d'abord, puis affinite avec le groupe (themes
/// adaptes aux familles, couples, amis), puis display_priority, avec une part
/// d'aleatoire (graine [TripPools.build]) pour varier les propositions.
class TripPlannerService {
  final _restaurants = RestaurantSupabaseService();
  final _family = FamilyVenuesSupabaseService();
  final _venues = VenuesSupabaseService();

  /// Charge en parallele tous les lieux utiles a la ville. Une source en
  /// erreur donne une liste vide : la feuille de route se fait sans elle.
  Future<TripPools> loadPools(String ville) async {
    Future<List<T>> safe<T>(Future<List<T>> f) =>
        f.catchError((Object e) {
          debugPrint('[TripPlanner] source KO: $e');
          return <T>[];
        });
    final results = await Future.wait([
      safe<RestaurantVenue>(_restaurants.fetchRestaurants(ville: ville)),
      safe<FamilyVenue>(_family.fetchVenues(ville: ville)),
      safe<CommerceModel>(_venues.fetchVenues(mode: 'culture', ville: ville)),
      safe<CommerceModel>(_venues.fetchVenues(mode: 'night', ville: ville)),
    ]);
    // A part : colonne absente (migration non appliquee) = pas de styles.
    final clubGenres = await _venues
        .fetchClubMusicGenres(ville: ville)
        .catchError((Object e) {
      debugPrint('[TripPlanner] styles musicaux KO: $e');
      return <int, List<String>>{};
    });
    return TripPools(
      restaurants: results[0] as List<RestaurantVenue>,
      family: results[1] as List<FamilyVenue>,
      culture: results[2] as List<CommerceModel>,
      night: results[3] as List<CommerceModel>,
      clubGenres: clubGenres,
    );
  }
}

/// Lieux candidats d'une ville, convertis en candidats notes par type d'etape.
class TripPools {
  final List<RestaurantVenue> restaurants;
  final List<FamilyVenue> family;
  final List<CommerceModel> culture;
  final List<CommerceModel> night;

  /// id venue -> styles musicaux de la discotheque (cf. [TripMusic]).
  final Map<int, List<String>> clubGenres;

  const TripPools({
    required this.restaurants,
    required this.family,
    required this.culture,
    required this.night,
    this.clubGenres = const {},
  });

  bool get isEmpty => restaurants.isEmpty && family.isEmpty && culture.isEmpty;

  static const _breakfastThemes = ['Brunch', 'Salon de the'];

  /// Themes de cuisine favorises selon le groupe (bonus, pas un filtre).
  static const _mealBoost = <TripGroup, List<String>>{
    TripGroup.famille: ['Italien', 'Buffet', 'Guinguette', 'Fusion', 'Mexicain'],
    TripGroup.couple: ['Francais', 'Japonais', 'Mediterraneen', 'Fruits de mer', 'Sud-Ouest'],
    TripGroup.amis: ['Tapas', 'Pintxos', 'Asiatique', 'Mexicain', 'Buffet', 'Guinguette'],
  };

  /// Activites « entre amis / en couple » prises dans family_venues.
  static const _funKeywords = [
    'escape', 'laser', 'bowling', 'karting', 'paintball', 'accrobranche',
    'mini golf', 'patinoire', 'billard', 'quiz', 'realite virtuelle', 'vr',
    'trampoline', 'parc de loisirs', "parc d'attractions",
  ];

  /// Lieux sans interet pour un sejour (exclus) ou a garder en dernier
  /// recours (piscines municipales, cinemas : faisables partout).
  static const _notActivity = ['bibliotheque', 'mediatheque'];
  static const _fallbackActivity = ['piscine', 'cinema'];

  static bool _matchesAny(String text, List<String> needles) {
    final t = text.toLowerCase();
    return needles.any((n) => t.contains(n));
  }

  List<TripCandidate> _restaurantCandidates(TripStopKind kind, TripGroup group) {
    final boost = _mealBoost[group] ?? const [];
    final isBreakfast = kind == TripStopKind.breakfast;
    return restaurants
        .where((r) {
          final breakfastPlace = _breakfastThemes.any(r.matchesTheme);
          return isBreakfast ? breakfastPlace : !breakfastPlace;
        })
        .map((r) => TripCandidate(
              key: 'etab:${r.id}',
              commerce: RestaurantDetailSheet.toCommerce(r),
              isPartner: r.isPartner,
              priority: r.displayPriority,
              affinity: boost.any(r.matchesTheme) ? 1 : 0,
            ))
        .toList();
  }

  List<TripCandidate> _activityCandidates(TripGroup group) {
    TripCandidate fromFamily(FamilyVenue v, {int affinity = 0}) => TripCandidate(
          key: 'family:${v.id}',
          commerce: FamilyVenueRowCard.toCommerce(v),
          isPartner: v.isPartner,
          priority: 0,
          affinity: _matchesAny(v.category, _fallbackActivity) ? -1 : affinity,
        );
    TripCandidate fromVenue(CommerceModel c, {int affinity = 0}) => TripCandidate(
          key: 'venue:${c.sourceId ?? c.nom}',
          commerce: c,
          isPartner: c.isPartner,
          priority: 0,
          affinity: affinity,
        );
    final culture =
        this.culture.where((c) => !_matchesAny(c.categorie, _notActivity));

    switch (group) {
      case TripGroup.famille:
        // Tout family_venues est pense pour les enfants ; un peu de culture
        // (musees) en complement, moins prioritaire.
        return [
          ...family.map((v) => fromFamily(v, affinity: 1)),
          ...culture.map((c) => fromVenue(c)),
        ];
      case TripGroup.amis:
        return [
          ...family
              .where((v) => _matchesAny('${v.category} ${v.name}', _funKeywords))
              .map((v) => fromFamily(v, affinity: 1)),
          ...culture.map((c) => fromVenue(c)),
        ];
      case TripGroup.couple:
        return [
          ...culture.map((c) => fromVenue(c, affinity: 1)),
          ...family
              .where((v) => _matchesAny('${v.category} ${v.name}', _funKeywords))
              .map((v) => fromFamily(v)),
        ];
    }
  }

  TripCandidate _nightCandidate(CommerceModel c) => TripCandidate(
        key: 'venue:${c.sourceId ?? c.nom}',
        commerce: c,
        isPartner: c.isPartner,
        priority: 0,
        affinity: 0,
      );

  static const _clubKeywords = ['club', 'disco', 'boite', 'boîte'];

  List<TripCandidate> _drinkCandidates() => night
      .where((c) =>
          _matchesAny(c.categorie, ['bar', 'pub', 'cocktail', 'rooftop', 'lounge']) &&
          !_matchesAny(c.categorie, _clubKeywords))
      .map(_nightCandidate)
      .toList();

  /// Discotheques, classees selon les styles musicaux demandes : un club
  /// d'un des styles voulus (+150) passe devant un partenaire d'un autre
  /// style (+100). Un club au style inconnu reste proposable, juste devant
  /// ceux d'un autre style, pour ne jamais laisser l'etape vide.
  List<TripCandidate> _clubCandidates(Set<TripMusic> music) => night
      .where((c) => _matchesAny(c.categorie, _clubKeywords))
      .map((c) {
        final genres = clubGenres[c.sourceId] ?? const <String>[];
        final wanted = music.map((m) => m.name).toSet();
        final affinity = wanted.isEmpty
            ? 0
            : genres.any(wanted.contains)
                ? 5
                : (genres.isEmpty ? 1 : 0);
        return TripCandidate(
          key: 'venue:${c.sourceId ?? c.nom}',
          commerce: c,
          isPartner: c.isPartner,
          priority: 0,
          affinity: affinity,
        );
      })
      .toList();

  /// Candidats notes pour une etape (sans notion de zone). [seed] fait varier
  /// l'ordre entre deux propositions sans faire passer un partenaire derriere.
  List<(TripCandidate, int)> _scored(TripStopKind kind, TripGroup group, int seed,
      [Set<TripMusic> music = const {}]) {
    final list = switch (kind) {
      TripStopKind.breakfast ||
      TripStopKind.lunch ||
      TripStopKind.dinner =>
        _restaurantCandidates(kind, group),
      TripStopKind.activity => _activityCandidates(group),
      TripStopKind.drink => _drinkCandidates(),
      TripStopKind.club => _clubCandidates(music),
    };
    final rnd = Random(seed * 31 + kind.index);
    return list
        .map((c) => (c, (c.isPartner ? 100 : 0) +
            c.affinity * 30 +
            c.priority.clamp(0, 50) +
            rnd.nextInt(40)))
        .toList();
  }

  // ─── Zone : une journee se construit autour d'un meme quartier ──────────

  /// Points perdus par km d'eloignement du centre de la journee. A 80 pts/km,
  /// un partenaire (+100) reste devant jusqu'a ~1,2 km de plus qu'un autre.
  /// Simule sur Toulouse (2026-10-08) : journee mediane dans 1,6 km,
  /// partenaires sur 80 % des etapes (40 pts/km : 2 km / 87 %).
  static const _penaltyPerKm = 80.0;

  /// Distance retenue pour un lieu sans coordonnees : il passe derriere les
  /// lieux proches sans etre exclu.
  static const _unknownKm = 5.0;

  static bool _hasGps(CommerceModel c) => c.latitude != 0 && c.longitude != 0;

  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * r * asin(sqrt(h));
  }

  /// Meilleur candidat hors [exclude], penalise par la distance a [anchor].
  static TripCandidate? _pick(
    List<(TripCandidate, int)> scored,
    Set<String> exclude,
    (double, double)? anchor,
  ) {
    TripCandidate? best;
    var bestScore = double.negativeInfinity;
    for (final (c, score) in scored) {
      if (exclude.contains(c.key)) continue;
      var s = score.toDouble();
      if (anchor != null) {
        final km = _hasGps(c.commerce)
            ? distanceKm(anchor.$1, anchor.$2, c.commerce.latitude, c.commerce.longitude)
            : _unknownKm;
        s -= km * _penaltyPerKm;
      }
      if (s > bestScore) {
        bestScore = s;
        best = c;
      }
    }
    return best;
  }

  /// Centre de la journee : la 1re etape geolocalisee (hors [skipKey]).
  static (double, double)? _anchorOf(List<TripStop> stops, {String? skipKey}) {
    for (final s in stops) {
      final c = s.candidate.commerce;
      if (s.candidate.key != skipKey && _hasGps(c)) return (c.latitude, c.longitude);
    }
    return null;
  }

  /// Construit la feuille de route complete. Un lieu n'apparait qu'une fois ;
  /// une etape sans candidat disponible est simplement omise. Chaque journee
  /// part de son meilleur lieu puis prend les etapes suivantes autour.
  TripPlan build(TripAnswers a, {int seed = 0}) {
    final used = <String>{};
    final scored = {
      for (final k in TripStopKind.values) k: _scored(k, a.group, seed, a.music),
    };

    final days = <TripDay>[];
    for (var d = 0; d < a.days; d++) {
      final stops = <TripStop>[];
      void add(TripStopKind kind, String slot) {
        final c = _pick(scored[kind]!, used, _anchorOf(stops));
        if (c == null) return;
        used.add(c.key);
        stops.add(TripStop(kind: kind, slot: slot, candidate: c));
      }

      if (a.meals.contains(TripMeal.matin)) add(TripStopKind.breakfast, 'Petit-déjeuner');
      if (a.activities) add(TripStopKind.activity, 'Activité du matin');
      if (a.meals.contains(TripMeal.midi)) add(TripStopKind.lunch, 'Déjeuner');
      if (a.activities) add(TripStopKind.activity, "Activité de l'après-midi");
      if (a.meals.contains(TripMeal.soir)) add(TripStopKind.dinner, 'Dîner');
      if (a.night != TripNight.none) add(TripStopKind.drink, 'Un verre en bar');
      if (a.night == TripNight.barClub) add(TripStopKind.club, 'Fin de soirée en discothèque');
      days.add(TripDay(index: d + 1, stops: stops));
    }
    return TripPlan(answers: a, days: days, seed: seed);
  }

  /// Autre lieu pour une etape : absent du plan, pas deja refuse pour cette
  /// etape, et proche du reste de la journee.
  TripCandidate? alternativeFor(TripPlan plan, int dayIdx, int stopIdx) {
    final day = plan.days[dayIdx];
    final stop = day.stops[stopIdx];
    final rejected = plan.rejected.putIfAbsent('$dayIdx:$stopIdx', () => {})
      ..add(stop.candidate.key);
    final exclude = {
      for (final dd in plan.days)
        for (final s in dd.stops) s.candidate.key,
      ...rejected,
    };
    var c = _pick(
      _scored(stop.kind, plan.answers.group, plan.seed, plan.answers.music),
      exclude,
      _anchorOf(day.stops, skipKey: stop.candidate.key),
    );
    if (c == null && rejected.length > 1) {
      // Tout a ete propose : on recommence le tour (hors lieu affiche).
      rejected
        ..clear()
        ..add(stop.candidate.key);
      return alternativeFor(plan, dayIdx, stopIdx);
    }
    return c;
  }
}
