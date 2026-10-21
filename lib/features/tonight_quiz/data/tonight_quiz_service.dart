import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/family/data/family_venues_supabase_service.dart';
import 'package:pulz_app/features/family/presentation/widgets/family_venue_row_card.dart';
import 'package:pulz_app/features/reported_events/presentation/screens/tonight_bons_plans_page.dart';
import 'package:pulz_app/features/tonight_quiz/domain/tonight_quiz.dart';

/// Lieux de la ville utiles au questionnaire « Quoi faire ce soir » :
/// bars et clubs (`venues` night), salles de spectacle (`venues` culture),
/// activités (`family_venues`) et balades du soir (`night_walks`).
class TonightQuizService {
  final _venues = VenuesSupabaseService();
  final _family = FamilyVenuesSupabaseService();

  /// Une source en erreur donne une liste vide : les propositions se font
  /// sans elle.
  Future<TonightPools> loadPools(String ville) async {
    Future<List<T>> safe<T>(Future<List<T>> f) => f.catchError((Object e) {
          debugPrint('[TonightQuiz] source KO: $e');
          return <T>[];
        });
    final results = await Future.wait([
      safe<CommerceModel>(_venues.fetchVenues(mode: 'night', ville: ville)),
      safe<CommerceModel>(_venues.fetchVenues(mode: 'culture', ville: ville)),
      safe<CommerceModel>(
        _family
            .fetchVenues(ville: ville)
            .then((l) => l.map(FamilyVenueRowCard.toCommerce).toList()),
      ),
      safe<NightWalk>(_fetchWalks(ville)),
    ]);
    return TonightPools(
      night: results[0] as List<CommerceModel>,
      culture: results[1] as List<CommerceModel>,
      activities: results[2] as List<CommerceModel>,
      walks: results[3] as List<NightWalk>,
    );
  }

  Future<List<NightWalk>> _fetchWalks(String ville) async {
    final cityBase = ville.split('(').first.trim();
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl)
      ..interceptors.add(SupabaseInterceptor());
    try {
      final res = await dio.get<dynamic>(
        'night_walks',
        queryParameters: {
          'select': '*',
          'is_active': 'eq.true',
          'ville': 'ilike.*$cityBase*',
          'order': 'ordre.asc',
        },
      );
      final data = res.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => NightWalk.fromJson(e.cast<String, dynamic>()))
          .where((w) => w.titre.isNotEmpty)
          .toList();
    } on DioException {
      // Table absente (migration non appliquée) ou réseau : pas de balade.
      return const [];
    }
  }
}

class TonightPools {
  final List<CommerceModel> night;
  final List<CommerceModel> culture;
  final List<CommerceModel> activities;
  final List<NightWalk> walks;

  const TonightPools({
    required this.night,
    required this.culture,
    required this.activities,
    required this.walks,
  });

  static const maxEvents = 6;
  static const maxPlaces = 4;
  static const maxWalks = 4;

  /// Envies proposées selon le groupe : pas de bar ni de soirée en famille.
  static List<TonightWish> wishesFor(TonightGroup group) => [
        TonightWish.concert,
        if (group != TonightGroup.famille) TonightWish.soiree,
        if (group != TonightGroup.famille) TonightWish.cocktail,
        TonightWish.balade,
        TonightWish.activite,
        TonightWish.spectacle,
      ];

  static bool _has(String text, List<String> needles) {
    final t = text.toLowerCase();
    return needles.any(t.contains);
  }

  static const _clubWords = [
    'club',
    'disco',
    'boite',
    'boîte',
    'soirée',
    'soiree'
  ];
  static const _barWords = ['bar', 'pub', 'cocktail', 'rooftop', 'lounge'];

  /// Catégories Night jamais proposées (pas une sortie, ou pas grand public).
  static const _notOuting = [
    'epicerie',
    'épicerie',
    'tabac',
    'hotel',
    'hôtel',
    'coquin',
    'strip',
    'sos apero',
    'chicha',
    'restaurant',
  ];

  /// Activités faisables le soir (family_venues) ; piscines, aires de jeux,
  /// fermes et parcs animaliers ferment avant.
  static const _eveningActivities = [
    'escape',
    'laser',
    'bowling',
    'cinema',
    'cinéma',
    'patinoire',
    'billard',
    'karting',
    'quiz',
    'realite virtuelle',
    'réalité virtuelle',
    'vr',
    'mini golf',
    'trampoline',
    'blind test',
    'karaoke',
    'karaoké',
  ];

  /// Minutes depuis minuit de chaque séance (« 14h30, 20h00 »). Une séance
  /// après minuit compte pour la nuit (+24 h).
  static List<int> _showTimes(String horaires) =>
      RegExp(r'(\d{1,2})h(\d{0,2})').allMatches(horaires).map((m) {
        final h = int.tryParse(m.group(1)!) ?? 0;
        final min = int.tryParse(m.group(2)!.isEmpty ? '0' : m.group(2)!) ?? 0;
        return (h < 6 ? h + 24 : h) * 60 + min;
      }).toList();

  static bool _matchesWhen(Event e, TonightWhen when, DateTime now) {
    final times = _showTimes(e.horaires);
    final nowMin = now.hour * 60 + now.minute;
    return times.any(
      (t) => switch (when) {
        // Déjà commencé depuis peu, ou qui commence dans les 2 h.
        TonightWhen.now => t >= nowMin - 30 && t <= nowMin + 120,
        TonightWhen.afterDinner => t >= 20 * 60 && t < 22 * 60 + 30,
        TonightWhen.late => t >= 22 * 60,
      },
    );
  }

  /// Partenaires d'abord, puis lieux avec photo, avec une part d'aléatoire
  /// ([seed]) pour varier les propositions.
  static List<CommerceModel> _rank(
    List<CommerceModel> list,
    int seed, {
    int Function(CommerceModel)? bonus,
  }) {
    final rnd = Random(seed);
    final scored = list
        .map(
          (c) => (
            c,
            (c.isPartner ? 100 : 0) +
                (c.photo.startsWith('http') ? 20 : 0) +
                (bonus?.call(c) ?? 0) +
                rnd.nextInt(40),
          ),
        )
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return scored.map((s) => s.$1).take(maxPlaces).toList();
  }

  /// Une section par envie, dans l'ordre des envies proposées.
  List<TonightSection> build(
    TonightAnswers a,
    List<Event> tonightEvents, {
    int seed = 0,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final night =
        this.night.where((c) => !_has(c.categorie, _notOuting)).toList();

    TonightSection eventsSection(
      TonightWish wish,
      Set<String> eventSections,
      List<CommerceModel> places,
    ) {
      final all = tonightEvents
          .where(
            (e) =>
                eventSections.contains(TonightBonsPlansPage.nightSectionFor(e)),
          )
          .toList();
      final atTime = all.where((e) => _matchesWhen(e, a.when, at)).toList();
      final picked = (atTime.isNotEmpty ? atTime : all)
        ..shuffle(Random(seed + wish.index));
      return TonightSection(
        wish: wish,
        events: picked.take(maxEvents).toList(),
        eventsOtherTime: atTime.isEmpty && all.isNotEmpty,
        places: places,
      );
    }

    final sections = <TonightSection>[];
    for (final wish in wishesFor(a.group).where(a.wishes.contains)) {
      final s = seed + wish.index * 7;
      sections.add(
        switch (wish) {
          TonightWish.concert => eventsSection(
              wish,
              {'Concerts'},
              _rank(night.where((c) => _has(c.categorie, ['concert'])).toList(),
                  s),
            ),
          TonightWish.soiree => eventsSection(
              wish,
              {'Soirées'},
              _rank(night.where((c) => _has(c.categorie, _clubWords)).toList(),
                  s),
            ),
          TonightWish.cocktail => TonightSection(
              wish: wish,
              places: _rank(
                night
                    .where(
                      (c) =>
                          _has(c.categorie, _barWords) &&
                          !_has(c.categorie, _clubWords),
                    )
                    .toList(),
                s,
                // Bars à cocktails devant les bars de nuit et pubs.
                bonus: (c) => _has(c.categorie, ['cocktail']) ? 60 : 0,
              ),
            ),
          TonightWish.balade => TonightSection(
              wish: wish,
              walks: _rankWalks(a.group, s),
            ),
          TonightWish.activite => eventsSection(
              wish,
              {'Cinéma'},
              _rank(
                activities
                    .where((c) =>
                        _has('${c.categorie} ${c.nom}', _eveningActivities))
                    .toList(),
                s,
              ),
            ),
          TonightWish.spectacle => eventsSection(
              wish,
              {'Spectacles'},
              _rank(
                  culture
                      .where((c) => _has(c.categorie, ['theatre', 'théâtre']))
                      .toList(),
                  s),
            ),
        },
      );
    }
    return sections;
  }

  /// Ambiance favorisée : romantique en couple, animée entre amis.
  List<NightWalk> _rankWalks(TonightGroup group, int seed) {
    final preferred = switch (group) {
      TonightGroup.couple => 'romantique',
      TonightGroup.amis => 'animee',
      TonightGroup.famille => 'calme',
      TonightGroup.solo => 'panorama',
    };
    final rnd = Random(seed);
    final scored = walks
        .map((w) => (w, (w.ambiance == preferred ? 50 : 0) + rnd.nextInt(40)))
        .toList()
      ..sort((x, y) => y.$2.compareTo(x.$2));
    return scored.map((s) => s.$1).take(maxWalks).toList();
  }
}
