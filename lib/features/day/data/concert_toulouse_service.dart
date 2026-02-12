import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/data/festik_api_service.dart';
import 'package:pulz_app/features/day/data/ticketmaster_api_service.dart';
import 'package:pulz_app/features/day/data/concert_cache_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service dédié aux concerts des salles de Toulouse et agglomération.
///
/// Pipeline multi-source avec cache :
/// 1. Cache local (SharedPreferences, TTL 6h)
/// 2. Ticketmaster Discovery API (source primaire)
/// 3. OpenDataSoft Toulouse (fallback)
/// 4. Festik (billetterie festivals/concerts)
/// 5. Données curatées (fallback ultime)
///
/// Les résultats sont dédupliqués, filtrés et triés par date croissante,
/// puis sauvegardés en cache pour les appels suivants.
class ConcertToulouseService {
  final EventApiService _api;
  final TicketmasterApiService _ticketmaster;
  final ConcertCacheService _cache;
  final FestikApiService _festik;

  ConcertToulouseService({
    EventApiService? api,
    TicketmasterApiService? ticketmaster,
    ConcertCacheService? cache,
    FestikApiService? festik,
  })  : _api = api ?? EventApiService(),
        _ticketmaster = ticketmaster ?? TicketmasterApiService(),
        _cache = cache ?? ConcertCacheService(),
        _festik = festik ?? FestikApiService();

  /// Noms normalisés des salles ciblées, utilisés pour le filtrage API.
  static const venueNames = [
    'Zenith',
    'Metronum',
    'Bikini',
    'Halle aux Grains',
    'Saint-Pierre-des-Cuisines',
    'Nougaro',
    'Taquin',
    'Rex',
    'Interference',
    'Chapelle',
    'Palais Consulaire',
    'Carmelites',
  ];

  /// Construit la clause WHERE pour filtrer l'API OpenDataSoft par salles + type concert.
  String _buildWhereClause() {
    final now = DateTime.now();
    final dateFrom =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final venueFilters =
        venueNames.map((v) => 'lieu_nom LIKE "%$v%"').join(' OR ');

    return '($venueFilters) '
        'AND (type_de_manifestation LIKE "%Concert%" '
        'OR type_de_manifestation LIKE "%Musique%" '
        'OR categorie_de_la_manifestation LIKE "%Concert%" '
        'OR categorie_de_la_manifestation LIKE "%Musique%") '
        'AND date_debut >= "$dateFrom"';
  }

  /// Récupère les concerts à venir via le pipeline multi-source.
  ///
  /// Ordre de priorité :
  /// 1. Cache valide → retour immédiat
  /// 2. Ticketmaster Discovery API (concerts officiels)
  /// 3. OpenDataSoft Toulouse (agenda culturel)
  /// 4. Festik (billetterie)
  /// 5. Données curatées (toujours ajoutées)
  Future<List<Event>> fetchUpcomingConcerts() async {
    // 1. Cache valide → retour immédiat (en filtrant les passés)
    try {
      final cached = await _cache.load();
      if (cached != null && cached.isNotEmpty) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final upcoming = cached.where((e) {
          final d = DateTime.tryParse(e.dateDebut);
          return d != null && !d.isBefore(today);
        }).toList();
        if (upcoming.isNotEmpty) return upcoming;
        // Cache ne contient que des passés → on re-fetch
      }
    } catch (_) {
      // Cache inaccessible, on continue
    }

    final List<Event> allEvents = [];

    // 2. Ticketmaster Discovery API (source primaire)
    try {
      final tmEvents = await _ticketmaster.fetchConcertsToulouse();
      allEvents.addAll(tmEvents);
    } catch (_) {
      // Ticketmaster indisponible, on continue avec le fallback
    }

    // 3. OpenDataSoft Toulouse (fallback)
    try {
      final apiEvents = await _api.fetchEvents(
        where: _buildWhereClause(),
        limit: 100,
      );
      allEvents.addAll(apiEvents);
    } catch (_) {
      // API indisponible, on continue
    }

    // 4. Festik (billetterie)
    try {
      final festikEvents =
          await _festik.fetchToulouseEvents(categorie: 'Concert');
      allEvents.addAll(festikEvents);
    } catch (_) {
      // Festik indisponible, on continue
    }

    // 5. Données curatées (toujours ajoutées)
    final curated = _getCuratedConcerts();
    allEvents.addAll(curated);

    // 5. Dédoublonnage par titre normalisé + date
    final seen = <String>{};
    final deduped = <Event>[];
    for (final e in allEvents) {
      final key = '${_normalize(e.titre)}|${e.dateDebut}';
      if (seen.add(key)) {
        deduped.add(e);
      }
    }

    // 6. Filtrer les événements passés
    final now = DateTime.now();
    final upcoming = deduped.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      return d != null && !d.isBefore(DateTime(now.year, now.month, now.day));
    }).toList();

    // 7. Tri chronologique
    upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    // 8. Sauvegarder en cache pour les prochains appels
    if (upcoming.isNotEmpty) {
      try {
        await _cache.save(upcoming);
      } catch (_) {
        // Echec du cache, pas bloquant
      }
    }

    return upcoming;
  }

  String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  // ─────────────────────────────────────────────
  // Données curatées – concerts à venir 2026
  // ─────────────────────────────────────────────

  static List<Event> _getCuratedConcerts() => [
        // ── Zenith Toulouse Metropole (source: zenith-toulousemetropole.com) ──
        const Event(
          identifiant: 'zenith_goldmen',
          titre: 'Goldmen',
          dateDebut: '2026-02-13',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/GOLDMEN-19296',
        ),
        const Event(
          identifiant: 'zenith_ultra_vomit',
          titre: 'Ultra Vomit',
          dateDebut: '2026-02-14',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/ULTRA%20VOMIT-20375',
        ),
        const Event(
          identifiant: 'zenith_carmina_burana',
          titre: 'Carmina Burana',
          dateDebut: '2026-02-15',
          horaires: '17h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/CARMINA%20BURANA-19639',
        ),
        const Event(
          identifiant: 'zenith_elodie_poux',
          titre: 'Elodie Poux',
          dateDebut: '2026-02-11',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/ELODIE%20POUX-20929',
        ),
        const Event(
          identifiant: 'zenith_fabrice_eboue',
          titre: 'Fabrice Eboue',
          dateDebut: '2026-02-20',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/FABRICE%20EBOUE-19556',
        ),
        const Event(
          identifiant: 'zenith_joe_hisaishi',
          titre: 'Les Musiques de Joe Hisaishi en Concert Symphonique',
          dateDebut: '2026-02-21',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/LES%20MUSIQUES%20DE%20JOE%20HISAISHI%20EN%20CONCERT%20SYMPHONIQUE-20883',
        ),
        const Event(
          identifiant: 'zenith_santa',
          titre: 'Santa',
          dateDebut: '2026-02-27',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/SANTA-20749',
        ),
        const Event(
          identifiant: 'zenith_mika',
          titre: 'Mika',
          dateDebut: '2026-02-28',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/MIKA-21070',
        ),
        const Event(
          identifiant: 'zenith_holiday_on_ice',
          titre: 'Holiday on Ice',
          dateDebut: '2026-03-06',
          dateFin: '2026-03-08',
          horaires: '14h30 / 18h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/HOLIDAY%20ON%20ICE-20446',
        ),
        const Event(
          identifiant: 'zenith_world_of_queen',
          titre: 'The World of Queen',
          dateDebut: '2026-03-11',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/THE%20WORLD%20OF%20QUEEN%20-20165',
        ),
        const Event(
          identifiant: 'zenith_stars_80',
          titre: 'Stars 80 Forever',
          dateDebut: '2026-03-12',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/STARS%2080%20FOREVER-20439',
        ),
        const Event(
          identifiant: 'zenith_diane_segard',
          titre: 'Diane Segard',
          dateDebut: '2026-03-13',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Spectacle',
          type: 'Spectacle',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/DIANE%20SEGARD-20027',
        ),
        const Event(
          identifiant: 'zenith_elena_nagapetyan',
          titre: 'Elena Nagapetyan',
          dateDebut: '2026-03-14',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/ELENA%20NAGAPETYAN-20402',
        ),
        const Event(
          identifiant: 'zenith_rock_symphony',
          titre: 'The Rock Symphony Orchestra',
          dateDebut: '2026-03-15',
          horaires: '17h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/The%20Rock%20Symphony%20Orchestra-21817',
        ),
        const Event(
          identifiant: 'zenith_i_gotta_feeling',
          titre: 'I Gotta Feeling : La Tournee',
          dateDebut: '2026-03-18',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/I%20GOTTA%20FEELING%20:%20LA%20TOURNEE-20973',
        ),
        const Event(
          identifiant: 'zenith_jb_guegan',
          titre: 'Jean Baptiste Guegan',
          dateDebut: '2026-03-19',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/JEAN%20BAPTISTE%20GUEGAN-20733',
        ),
        const Event(
          identifiant: 'zenith_lara_fabian',
          titre: 'Lara Fabian',
          dateDebut: '2026-03-22',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/LARA%20FABIAN-20191',
        ),
        const Event(
          identifiant: 'zenith_australian_pink_floyd',
          titre: 'The Australian Pink Floyd Show',
          dateDebut: '2026-03-23',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/THE%20AUSTRALIAN%20PINK%20FLOYD%20SHOW-21080',
        ),
        const Event(
          identifiant: 'zenith_black_legends',
          titre: 'Black Legends',
          dateDebut: '2026-03-24',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/BLACK%20LEGENDS-20806',
        ),
        const Event(
          identifiant: 'zenith_jeremy_frerot',
          titre: 'Jeremy Frerot',
          dateDebut: '2026-03-25',
          horaires: '20h00',
          lieuNom: 'Zenith Toulouse Metropole',
          lieuAdresse: '11 Avenue Raymond Badiou, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://zenith-toulousemetropole.com/shows/JEREMY%20FREROT-20923',
        ),

        // ── Le Metronum (source: lemetronum.fr) ──
        const Event(
          identifiant: 'metronum_cryptopsy',
          titre: 'Cryptopsy + 200 Stab Wounds + Inferi',
          dateDebut: '2026-02-13',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/evenement/cryptopsy-200-stab-wounds-inferi-corpse-pile/',
        ),
        const Event(
          identifiant: 'metronum_flora_fishbach',
          titre: 'Flora Fishbach + Joye',
          dateDebut: '2026-02-14',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/evenement/flora-fishbach/',
        ),
        const Event(
          identifiant: 'metronum_baboucan',
          titre: 'Baboucan & The Fine Asses',
          dateDebut: '2026-02-18',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/evenement/baboucan-the-fine-asses/',
        ),
        const Event(
          identifiant: 'metronum_gerald_toto',
          titre: 'Gerald Toto + Friends',
          dateDebut: '2026-02-19',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/evenement/gerald-toto-friends/',
        ),
        const Event(
          identifiant: 'metronum_bamby',
          titre: 'Bamby + Sound Brother\'s + Matalhani',
          dateDebut: '2026-02-20',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/evenement/bamby/',
        ),
        const Event(
          identifiant: 'metronum_mist_yao',
          titre: 'Mist + Yao',
          dateDebut: '2026-02-26',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/',
        ),
        const Event(
          identifiant: 'metronum_julii_sharp',
          titre: 'Julii Sharp / Marie Sigal / Damantra',
          dateDebut: '2026-02-27',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/',
        ),
        const Event(
          identifiant: 'metronum_hurlements_leo',
          titre: 'Les Hurlements d\'Leo',
          dateDebut: '2026-03-06',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/',
        ),
        const Event(
          identifiant: 'metronum_pi_ja_ma',
          titre: 'Pi Ja Ma / Gildaa',
          dateDebut: '2026-03-07',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/',
        ),
        const Event(
          identifiant: 'metronum_arma_jackson',
          titre: 'Arma Jackson',
          dateDebut: '2026-03-11',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/',
        ),
        const Event(
          identifiant: 'metronum_ajar',
          titre: 'Ajar',
          dateDebut: '2026-03-20',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/',
        ),
        const Event(
          identifiant: 'metronum_marguerite',
          titre: 'Marguerite (Star Ac\')',
          dateDebut: '2026-03-28',
          horaires: '20h00',
          lieuNom: 'Le Metronum',
          lieuAdresse: '2 Rond-Point Madame de Mondonville, 31200 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://lemetronum.fr/',
        ),

        // ── Le Bikini (source: lebikini.com) ──
        const Event(
          identifiant: 'bikini_mayhem',
          titre: 'Mayhem + Marduk + Immolation',
          dateDebut: '2026-02-12',
          horaires: '19h30',
          lieuNom: 'Le Bikini',
          lieuAdresse: 'Rue Hermes, 31520 Ramonville-Saint-Agne',
          commune: 'Ramonville-Saint-Agne',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.lebikini.com/2026/02/12/mayhem-marduk-immolation',
        ),
        const Event(
          identifiant: 'bikini_boulevard_des_airs',
          titre: 'Boulevard des Airs + Maheva',
          dateDebut: '2026-02-14',
          horaires: '19h30',
          lieuNom: 'Le Bikini',
          lieuAdresse: 'Rue Hermes, 31520 Ramonville-Saint-Agne',
          commune: 'Ramonville-Saint-Agne',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.lebikini.com/2026/02/14/boulevard-des-airs',
        ),
        const Event(
          identifiant: 'bikini_miki',
          titre: 'Miki + Vickie Cherie',
          dateDebut: '2026-02-18',
          horaires: '19h30',
          lieuNom: 'Le Bikini',
          lieuAdresse: 'Rue Hermes, 31520 Ramonville-Saint-Agne',
          commune: 'Ramonville-Saint-Agne',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.lebikini.com/2026/02/18/miki',
        ),
        const Event(
          identifiant: 'bikini_ofenbach',
          titre: 'Ofenbach : Cloned (live)',
          dateDebut: '2026-02-20',
          horaires: '19h30',
          lieuNom: 'Le Bikini',
          lieuAdresse: 'Rue Hermes, 31520 Ramonville-Saint-Agne',
          commune: 'Ramonville-Saint-Agne',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.lebikini.com/2026/02/20/ofenbach-cloned-live',
        ),
        const Event(
          identifiant: 'bikini_kataklysm',
          titre: 'Kataklysm + Vader + Blood Red Throne',
          dateDebut: '2026-02-26',
          horaires: '19h30',
          lieuNom: 'Le Bikini',
          lieuAdresse: 'Rue Hermes, 31520 Ramonville-Saint-Agne',
          commune: 'Ramonville-Saint-Agne',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.lebikini.com/2026/02/26/kataklysm-special-guests-vader-and-blood-red-throne',
        ),
        const Event(
          identifiant: 'bikini_myd',
          titre: 'Myd (live) + Forward',
          dateDebut: '2026-02-27',
          horaires: '19h30',
          lieuNom: 'Le Bikini',
          lieuAdresse: 'Rue Hermes, 31520 Ramonville-Saint-Agne',
          commune: 'Ramonville-Saint-Agne',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.lebikini.com/2026/02/27/myd-live',
        ),
        const Event(
          identifiant: 'bikini_yvnnis',
          titre: 'Yvnnis + Enock',
          dateDebut: '2026-02-28',
          horaires: '19h30',
          lieuNom: 'Le Bikini',
          lieuAdresse: 'Rue Hermes, 31520 Ramonville-Saint-Agne',
          commune: 'Ramonville-Saint-Agne',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.lebikini.com/2026/02/28/yvnnis',
        ),

        // ── Candlelight by Fever – Chapelle du CHU Hôtel-Dieu Saint-Jacques ──
        const Event(
          identifiant: 'candlelight_einaudi_1',
          titre: 'Candlelight : Hommage a Ludovico Einaudi',
          dateDebut: '2026-02-28',
          horaires: '17h00',
          lieuNom: 'Chapelle du CHU Hotel-Dieu Saint-Jacques',
          lieuAdresse: '2 Rue Viguerie, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '20-39€',
          reservationUrl: 'https://feverup.com/m/143172',
        ),
        const Event(
          identifiant: 'candlelight_einaudi_2',
          titre: 'Candlelight : Hommage a Ludovico Einaudi',
          dateDebut: '2026-03-28',
          horaires: '19h00',
          lieuNom: 'Chapelle du CHU Hotel-Dieu Saint-Jacques',
          lieuAdresse: '2 Rue Viguerie, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '20-39€',
          reservationUrl: 'https://feverup.com/m/143172',
        ),
        const Event(
          identifiant: 'candlelight_einaudi_3',
          titre: 'Candlelight : Hommage a Ludovico Einaudi',
          dateDebut: '2026-05-09',
          horaires: '21h00',
          lieuNom: 'Chapelle du CHU Hotel-Dieu Saint-Jacques',
          lieuAdresse: '2 Rue Viguerie, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '20-39€',
          reservationUrl: 'https://feverup.com/m/143172',
        ),
        const Event(
          identifiant: 'candlelight_mozart_chopin',
          titre: 'Candlelight : De Mozart a Chopin',
          dateDebut: '2026-02-28',
          horaires: '19h00',
          lieuNom: 'Chapelle du CHU Hotel-Dieu Saint-Jacques',
          lieuAdresse: '2 Rue Viguerie, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '28-43€',
          reservationUrl: 'https://feverup.com/m/359869',
        ),
        const Event(
          identifiant: 'candlelight_pink_floyd',
          titre: 'Candlelight : Hommage a Pink Floyd',
          dateDebut: '2026-03-29',
          horaires: '19h00',
          lieuNom: 'Chapelle du CHU Hotel-Dieu Saint-Jacques',
          lieuAdresse: '2 Rue Viguerie, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '28-43€',
          reservationUrl: 'https://feverup.com/m/168241',
        ),

        // ── Candlelight by Fever – Palais Consulaire CCI de Toulouse ──
        const Event(
          identifiant: 'candlelight_abba',
          titre: 'Candlelight : Hommage a ABBA',
          dateDebut: '2026-02-13',
          horaires: '19h00',
          lieuNom: 'Palais Consulaire - CCI de Toulouse',
          lieuAdresse: '2 Rue d\'Alsace-Lorraine, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '20-47€',
          reservationUrl: 'https://feverup.com/m/119430',
        ),
        const Event(
          identifiant: 'candlelight_queen',
          titre: 'Candlelight : Hommage a Queen',
          dateDebut: '2026-02-28',
          horaires: '19h00',
          lieuNom: 'Palais Consulaire - CCI de Toulouse',
          lieuAdresse: '2 Rue d\'Alsace-Lorraine, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '23-47€',
          reservationUrl: 'https://feverup.com/m/273235',
        ),
        const Event(
          identifiant: 'candlelight_queen_2',
          titre: 'Candlelight : Hommage a Queen',
          dateDebut: '2026-05-01',
          horaires: '19h00',
          lieuNom: 'Palais Consulaire - CCI de Toulouse',
          lieuAdresse: '2 Rue d\'Alsace-Lorraine, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '23-47€',
          reservationUrl: 'https://feverup.com/m/273235',
        ),
        const Event(
          identifiant: 'candlelight_hisaishi',
          titre: 'Candlelight : Hommage a Joe Hisaishi',
          dateDebut: '2026-02-15',
          horaires: '19h00',
          lieuNom: 'Palais Consulaire - CCI de Toulouse',
          lieuAdresse: '2 Rue d\'Alsace-Lorraine, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '27-46€',
          reservationUrl: 'https://feverup.com/m/287650',
        ),
        const Event(
          identifiant: 'candlelight_coldplay_dragons',
          titre: 'Candlelight : Coldplay VS Imagine Dragons',
          dateDebut: '2026-03-15',
          horaires: '19h00',
          lieuNom: 'Palais Consulaire - CCI de Toulouse',
          lieuAdresse: '2 Rue d\'Alsace-Lorraine, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '24-39€',
          reservationUrl: 'https://feverup.com/m/176691',
        ),
        const Event(
          identifiant: 'candlelight_celine_dion',
          titre: 'Candlelight : Hommage a Celine Dion',
          dateDebut: '2026-03-14',
          horaires: '19h00',
          lieuNom: 'Chapelle des Carmelites',
          lieuAdresse: '1 Rue de Perigord, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '20-40€',
          reservationUrl: 'https://feverup.com/m/258153',
        ),
        const Event(
          identifiant: 'candlelight_coldplay',
          titre: 'Candlelight : Hommage a Coldplay',
          dateDebut: '2026-04-04',
          horaires: '19h00',
          lieuNom: 'Palais Consulaire - CCI de Toulouse',
          lieuAdresse: '2 Rue d\'Alsace-Lorraine, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '24-39€',
          reservationUrl: 'https://feverup.com/m/168279',
        ),
        const Event(
          identifiant: 'candlelight_80s',
          titre: 'Candlelight : Le Meilleur des Annees 80',
          dateDebut: '2026-04-18',
          horaires: '19h00',
          lieuNom: 'Chapelle du CHU Hotel-Dieu Saint-Jacques',
          lieuAdresse: '2 Rue Viguerie, 31000 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '20-39€',
          reservationUrl: 'https://feverup.com/m/380259',
        ),

        // ── Casino Barriere Toulouse (source: casinosbarriere.com + infoconcert.com) ──
        const Event(
          identifiant: 'cb_jimmy_sax',
          titre: 'Jimmy Sax - Toi & Moi',
          dateDebut: '2026-03-05',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '39-68€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_legende_balavoine',
          titre: 'Legende Balavoine',
          dateDebut: '2026-03-10',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '39-59€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_linh',
          titre: 'Linh',
          dateDebut: '2026-03-11',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '25-35€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_gregoire',
          titre: 'Gregoire',
          dateDebut: '2026-04-10',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_poetic_lover',
          titre: 'Poetic Lover',
          dateDebut: '2026-05-30',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          tarifNormal: '60-76€',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
        const Event(
          identifiant: 'cb_laurent_voulzy',
          titre: 'Laurent Voulzy',
          dateDebut: '2026-06-04',
          horaires: '20h30',
          lieuNom: 'Casino Barriere Toulouse',
          lieuAdresse: '18 Chemin de la Loge, 31100 Toulouse',
          commune: 'Toulouse',
          categorie: 'Concert',
          type: 'Concert',
          manifestationGratuite: 'non',
          reservationUrl: 'https://www.casinosbarriere.com/toulouse/spectacles',
        ),
      ];
}
