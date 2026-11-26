import 'dart:math';

import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/night/data/closing_hour.dart';
import 'package:pulz_app/features/night/presentation/night_find_party.dart';

/// Questionnaire « Trouver ma soirée » (rubrique Night, 2026-11-26) :
/// avec qui, quelle ambiance, quelle musique, quand, jusqu'à quelle heure,
/// puis des propositions par ambiance : soirées et concerts de la période
/// choisie, et surtout des établissements de nuit (bars, clubs, salles).

/// Avec qui on sort : oriente le classement (cocktails en couple, clubs et
/// bars animés en bande, concerts en solo).
enum NightGroup { solo, couple, amis, bande }

/// Ambiances proposées (plusieurs possibles), une section de résultats
/// chacune.
enum NightVibe { verre, bar, danser, concert, theme }

/// Styles musicaux : mêmes clés que `venues.music_genres` (discothèques).
enum NightMusic { electro, hiphop, latino, generaliste, rock }

/// Période : ce soir, demain soir, ou le prochain week-end (ven. à dim.).
enum NightWhen { tonight, tomorrow, weekend }

/// Heure de fin souhaitée : favorise les lieux qui ferment à cette heure.
enum NightLate { early, two, allNight }

class NightPartyAnswers {
  final NightGroup group;
  final Set<NightVibe> vibes;

  /// Vide = peu importe.
  final Set<NightMusic> music;
  final NightWhen when;
  final NightLate late;

  const NightPartyAnswers({
    required this.group,
    required this.vibes,
    this.music = const {},
    required this.when,
    required this.late,
  });

  /// La question musique n'a de sens que pour danser, un concert ou une
  /// soirée à thème.
  static bool asksMusic(Set<NightVibe> vibes) => vibes.any(
        (v) =>
            v == NightVibe.danser ||
            v == NightVibe.concert ||
            v == NightVibe.theme,
      );
}

class NightPartySection {
  final NightVibe vibe;
  final List<Event> events;
  final List<CommerceModel> places;

  const NightPartySection({
    required this.vibe,
    this.events = const [],
    this.places = const [],
  });

  bool get isEmpty => events.isEmpty && places.isEmpty;
}

class NightPartyQuiz {
  /// Établissements de nuit de la ville (`venues` mode night).
  final List<CommerceModel> venues;

  /// Soirées et concerts à venir (même source que la liste « Trouver ma
  /// soirée »).
  final List<Event> events;

  /// Styles des discothèques : id venue -> clés de [NightMusic].
  final Map<int, List<String>> clubGenres;

  const NightPartyQuiz({
    required this.venues,
    required this.events,
    this.clubGenres = const {},
  });

  static const maxEvents = 6;
  static const maxPlaces = 5;

  /// Catégories jamais proposées (pas une sortie, ou pas grand public).
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
  static const _clubWords = ['club', 'disco', 'boite', 'boîte'];
  static const _calmBarWords = ['cocktail', 'pub', 'lounge', 'rooftop', 'vin'];

  /// Mots qui rangent une soirée côté « danser » (sinon « soirée à thème »).
  static final _danceEvent = RegExp(
    r'(?<![a-zà-ÿ])(club(bing)?|dj|disco|techno|house|electro|[ée]lectro|rave|dnb|drum|bass|dancefloor|danse|dance|salsa|bachata|kizomba|zouk|reggaeton|latin[oa]?|afro|dancehall|shatta|amapiano)(?![a-zà-ÿ])',
    caseSensitive: false,
  );

  /// Repérage du style musical d'un event dans son titre et sa catégorie.
  static final Map<NightMusic, RegExp> _musicWords = {
    NightMusic.electro: RegExp(
        r'techno|house|[ée]lectro|trance|dnb|drum|bass|rave|shranz|acid|minimal',
        caseSensitive: false),
    NightMusic.hiphop: RegExp(
        r'hip.?hop|rap|r&b|rnb|trap|afro|dancehall|drill|amapiano',
        caseSensitive: false),
    NightMusic.latino: RegExp(
        r'latin|salsa|bachata|reggaeton|kizomba|zouk|cara[iï]b|cuba|tango|cumbia',
        caseSensitive: false),
    NightMusic.generaliste: RegExp(
        r'ann[ée]es|80|90|2000|hits?|vari[ée]t[ée]|disco|karaok|blind.?test|g[ée]n[ée]raliste|tubes?',
        caseSensitive: false),
    NightMusic.rock: RegExp(r'rock|metal|punk|indie|blues|grunge|garage|psych',
        caseSensitive: false),
  };

  static bool _has(String text, List<String> words) {
    final t = text.toLowerCase();
    return words.any(t.contains);
  }

  /// Jours couverts par la période, à partir d'aujourd'hui.
  static Set<DateTime> daysFor(NightWhen when, DateTime today) {
    final d0 = DateTime(today.year, today.month, today.day);
    switch (when) {
      case NightWhen.tonight:
        return {d0};
      case NightWhen.tomorrow:
        return {d0.add(const Duration(days: 1))};
      case NightWhen.weekend:
        // Vendredi = 5 ... dimanche = 7. En semaine : le week-end qui vient ;
        // pendant le week-end : de ce soir à dimanche.
        final wd = d0.weekday;
        final start = wd >= DateTime.friday
            ? d0
            : d0.add(Duration(days: DateTime.friday - wd));
        final end = d0.add(Duration(days: DateTime.sunday - wd));
        return {
          for (var d = start;
              !d.isAfter(end);
              d = d.add(const Duration(days: 1)))
            d,
        };
    }
  }

  /// Minutes depuis 0h de la 1re heure lue dans les horaires (après minuit
  /// = suite de la soirée, +24 h). Null si aucune heure.
  static int? _startMinutes(String horaires) {
    final m = RegExp(r'(\d{1,2})h(\d{0,2})').firstMatch(horaires);
    if (m == null) return null;
    final h = int.tryParse(m.group(1)!) ?? 0;
    final min = int.tryParse(m.group(2)!.isEmpty ? '0' : m.group(2)!) ?? 0;
    return (h < 6 ? h + 24 : h) * 60 + min;
  }

  static bool _eventMatchesMusic(Event e, Set<NightMusic> music) {
    final text = '${e.titre} ${e.categorie} ${e.type}';
    return music.any((m) => _musicWords[m]!.hasMatch(text));
  }

  /// Toutes les soirées et tous les concerts de la période, triés par jour
  /// puis par heure de début (sans heure : en fin de journée).
  List<Event> eventsInPeriod(NightWhen when, DateTime today) {
    final days = daysFor(when, today);
    final d0 = DateTime(today.year, today.month, today.day);
    final list =
        events.where((e) => days.contains(nightPartyDay(e, d0))).toList()
          ..sort((x, y) {
            final c = nightPartyDay(x, d0).compareTo(nightPartyDay(y, d0));
            if (c != 0) return c;
            return (_startMinutes(x.horaires) ?? 9999)
                .compareTo(_startMinutes(y.horaires) ?? 9999);
          });
    return list;
  }

  /// Une section par ambiance choisie, dans l'ordre de [NightVibe]. Un même
  /// lieu n'apparaît qu'une fois (dans la 1re section où il a sa place).
  List<NightPartySection> build(
    NightPartyAnswers a, {
    required DateTime today,
    int seed = 0,
  }) {
    final days = daysFor(a.when, today);
    final d0 = DateTime(today.year, today.month, today.day);
    final inPeriod =
        events.where((e) => days.contains(nightPartyDay(e, d0))).toList();
    final places = venues.where((c) => !_has(c.categorie, _notOuting)).toList();
    final used = <String>{};

    List<Event> pickEvents(bool Function(Event) keep, int s) {
      final rnd = Random(s);
      final scored = inPeriod.where(keep).map((e) {
        var score = rnd.nextInt(40);
        if (a.music.isNotEmpty && _eventMatchesMusic(e, a.music)) score += 60;
        final start = _startMinutes(e.horaires);
        if (start != null) {
          score += switch (a.late) {
            NightLate.early => start < 22 * 60 ? 25 : 0,
            NightLate.two => start >= 20 * 60 && start < 24 * 60 ? 15 : 0,
            NightLate.allNight => start >= 22 * 60 ? 30 : 0,
          };
        }
        if ((e.photoPath ?? '').startsWith('http')) score += 10;
        return (e, score);
      }).toList()
        ..sort((x, y) => y.$2.compareTo(x.$2));
      return scored.map((s) => s.$1).take(maxEvents).toList();
    }

    int lateScore(CommerceModel c) {
      final close = closingHour(c.horaires);
      if (close == null) return 0;
      return switch (a.late) {
        NightLate.early => closesUpTo(c.horaires, 1) ? 40 : -30,
        NightLate.two =>
          closesAfter(c.horaires, 2) && closesUpTo(c.horaires, 3) ? 35 : 0,
        NightLate.allNight => closesAfter(c.horaires, 5) ? 60 : -20,
      };
    }

    int musicScore(CommerceModel c) {
      if (a.music.isEmpty) return 0;
      final genres = clubGenres[c.sourceId] ?? const <String>[];
      if (genres.isEmpty) return 5;
      return genres.any(a.music.map((m) => m.name).contains) ? 80 : -10;
    }

    int groupScore(CommerceModel c) {
      final cat = c.categorie.toLowerCase();
      return switch (a.group) {
        NightGroup.couple => cat.contains('cocktail') ? 40 : 0,
        NightGroup.bande =>
          _has(cat, _clubWords) || cat.contains('bar de nuit') ? 25 : 0,
        NightGroup.amis => cat.contains('bar de nuit') ? 15 : 0,
        NightGroup.solo => cat.contains('concert') ? 20 : 0,
      };
    }

    List<CommerceModel> pickPlaces(
      bool Function(CommerceModel) keep,
      int s, {
      bool music = false,
    }) {
      final rnd = Random(s);
      final scored = places.where(keep).map((c) {
        final score = (c.isPartner ? 100 : 0) +
            (c.photo.startsWith('http') ? 20 : 0) +
            lateScore(c) +
            groupScore(c) +
            (music ? musicScore(c) : 0) +
            rnd.nextInt(40);
        return (c, score);
      }).toList()
        ..sort((x, y) => y.$2.compareTo(x.$2));
      final out = <CommerceModel>[];
      for (final (c, _) in scored) {
        final key = '${c.sourceId ?? ''}_${c.nom.toLowerCase()}';
        if (used.contains(key)) continue;
        used.add(key);
        out.add(c);
        if (out.length == maxPlaces) break;
      }
      return out;
    }

    bool isSoiree(Event e) => nightPartyKindOf(e) == NightPartyKind.soiree;
    bool isDance(Event e) =>
        _danceEvent.hasMatch('${e.titre} ${e.categorie} ${e.type}');
    bool isClub(CommerceModel c) => _has(c.categorie, _clubWords);
    bool isSoireeVenue(CommerceModel c) =>
        c.categorie.toLowerCase().startsWith('soir');

    final sections = <NightPartySection>[];
    for (final v in NightVibe.values.where(a.vibes.contains)) {
      final s = seed + v.index * 7;
      sections.add(switch (v) {
        NightVibe.verre => NightPartySection(
            vibe: v,
            places: pickPlaces(
              (c) => _has(c.categorie, _calmBarWords) && !isClub(c),
              s,
            ),
          ),
        NightVibe.bar => NightPartySection(
            vibe: v,
            places: pickPlaces(
              (c) =>
                  c.categorie.toLowerCase().contains('bar') &&
                  !c.categorie.toLowerCase().contains('cocktail') &&
                  !isClub(c),
              s,
            ),
          ),
        NightVibe.danser => NightPartySection(
            vibe: v,
            events: pickEvents((e) => isSoiree(e) && isDance(e), s),
            places: pickPlaces(
              (c) => isClub(c) || isSoireeVenue(c),
              s,
              music: true,
            ),
          ),
        NightVibe.concert => NightPartySection(
            vibe: v,
            events: pickEvents(
              (e) => nightPartyKindOf(e) == NightPartyKind.concert,
              s,
            ),
            places: pickPlaces(
              (c) => c.categorie.toLowerCase().contains('concert'),
              s,
            ),
          ),
        NightVibe.theme => NightPartySection(
            vibe: v,
            events: () {
              final themed = pickEvents((e) => isSoiree(e) && !isDance(e), s);
              return themed.isNotEmpty ? themed : pickEvents(isSoiree, s);
            }(),
            places: pickPlaces(isSoireeVenue, s, music: true),
          ),
      });
    }
    return sections;
  }
}
