import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/day/data/open_agenda_api_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/domain/models/open_agenda_event.dart';

class EventRepository {
  final OpenAgendaApiService _openAgendaApi;
  final ScrapedEventsSupabaseService _scrapedService;

  EventRepository({
    OpenAgendaApiService? openAgendaApi,
    ScrapedEventsSupabaseService? scrapedService,
  })  : _openAgendaApi = openAgendaApi ?? OpenAgendaApiService(),
        _scrapedService = scrapedService ?? ScrapedEventsSupabaseService();

  /// Fetch events pour n'importe quelle ville via les scraped events Supabase.
  /// Fallback sur OpenAgenda si aucun résultat scrapé.
  Future<List<Event>> fetchEvents({
    required String city,
    required String subcategory,
    String? lieuNom,
  }) async {
    // "A venir" = tous les events day de la ville
    if (subcategory == 'A venir') {
      return _fetchAllUpcoming(city);
    }

    // Essayer les scraped events (fonctionne pour toutes les villes scrapées)
    final source = _subcategoryToSource[subcategory];
    if (source != null) {
      final events = await _scrapedService.fetchEvents(
        rubrique: 'day',
        source: source,
        dateGte: _todayStr(),
        lieuNom: lieuNom,
        ville: city,
      );
      if (events.isNotEmpty) return _dedup(events);
    }

    // Chercher dans toutes les rubriques par type de manifestation
    final (allEvents, _) = await _scrapedService.fetchAllEvents(
      dateGte: _todayStr(),
      ville: city,
      limit: 50,
    );
    final keyword = subcategory.toLowerCase();
    final filtered = allEvents.where((e) {
      final cat = e.categorie.toLowerCase();
      final type = e.type.toLowerCase();
      final titre = e.titre.toLowerCase();
      return cat.contains(keyword) || type.contains(keyword) || titre.contains(keyword);
    }).toList();
    if (filtered.isNotEmpty) return _dedup(filtered);

    // Fallback OpenAgenda pour les villes/catégories sans scraped events
    final openAgendaEvents = await _openAgendaApi.fetchEvents(
      city: city,
      keyword: subcategory,
    );
    return openAgendaEvents.map(_convertOpenAgendaToEvent).toList();
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Mapping des sous-categories Day vers les source IDs en base.
  static const _subcategoryToSource = <String, String>{
    'Concert': 'day_concert',
    'Festival': 'day_festival',
    'Opera': 'day_opera',
    'DJ set': 'day_djset',
    'Showcase': 'day_showcase',
    'Spectacle': 'day_spectacle',
    'Stand up': 'day_standup',
    'Fete musique': 'day_fete_musique',
    'Autres': 'day_other',
  };

  /// Agrège tous les events day d'une ville depuis la DB (avec et sans photo).
  Future<List<Event>> _fetchAllUpcoming(String city) async {
    final all = await _scrapedService.fetchEvents(
      rubrique: 'day',
      dateGte: _todayStr(),
      ville: city,
      requirePhoto: false,
    );

    // Si aucun scraped event, fallback OpenAgenda
    if (all.isEmpty) {
      final openAgendaEvents = await _openAgendaApi.fetchEvents(city: city);
      return openAgendaEvents.map(_convertOpenAgendaToEvent).toList();
    }

    final deduped = _dedup(all);

    // Tri par categorie puis date
    deduped.sort((a, b) {
      final catCmp = _categoryOrder(a).compareTo(_categoryOrder(b));
      if (catCmp != 0) return catCmp;
      return a.dateDebut.compareTo(b.dateDebut);
    });

    return deduped;
  }

  /// Dedup par titre normalisé + date.
  /// Priorité : source du lieu (theatre_capitole, bikini, etc.) > source générique (day_concert, day_opera).
  static List<Event> _dedup(List<Event> events) {
    final byKey = <String, Event>{};
    for (final e in events) {
      final key =
          '${e.titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}|${e.dateDebut}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = e;
      } else {
        // Garder celui avec la source la plus spécifique (lieu d'accueil)
        if (_sourcePriority(e.identifiant) < _sourcePriority(existing.identifiant)) {
          byKey[key] = e;
        }
      }
    }
    return byKey.values.toList();
  }

  /// Priorité des sources : plus le nombre est bas, plus la source est prioritaire.
  /// Les sources de lieux spécifiques (theatre_*, bikini_*, etc.) sont prioritaires.
  static int _sourcePriority(String identifiant) {
    final id = identifiant.toLowerCase();
    // Source du lieu d'accueil = priorité max
    if (id.startsWith('theatre_') ||
        id.startsWith('bikini_') ||
        id.startsWith('zenith_') ||
        id.startsWith('casino_') ||
        id.startsWith('rex_') ||
        id.startsWith('bascala_') ||
        id.startsWith('metronum_') ||
        id.startsWith('comdt_') ||
        id.startsWith('opera_tls_') ||
        id.startsWith('meett_') ||
        id.startsWith('cave_poesie_') ||
        id.startsWith('filaplomb_')) {
      return 0;
    }
    // Source spécifique ville (ex: festik, songkick)
    if (id.startsWith('festik_') || id.startsWith('sk_') || id.startsWith('tm_') || id.startsWith('eb_')) {
      return 1;
    }
    // Source générique
    return 2;
  }

  /// Ordre d'affichage des rubriques.
  static int _categoryOrder(Event e) {
    final cat = e.categorie.toLowerCase();
    final type = e.type.toLowerCase();
    if (cat.contains('concert') || type.contains('concert')) return 0;
    if (cat.contains('spectacle') || type.contains('spectacle')) return 1;
    if (cat.contains('festival') || type.contains('festival')) return 2;
    if (cat.contains('opera') || type.contains('opera')) return 3;
    if (cat.contains('showcase') || type.contains('showcase')) return 4;
    if (cat.contains('dj') || type.contains('dj')) return 5;
    if (cat.contains('fete') || cat.contains('fête') || type.contains('fete') || type.contains('fête')) return 6;
    return 7;
  }

  Event _convertOpenAgendaToEvent(OpenAgendaEvent oa) {
    return Event(
      identifiant: oa.uid,
      titre: oa.title,
      descriptifCourt: oa.description,
      descriptifLong: oa.longDescription,
      dateDebut: oa.firstDate,
      dateFin: oa.lastDate,
      lieuNom: oa.locationName,
      lieuAdresse: oa.locationAddress,
      commune: oa.locationCity,
      manifestationGratuite: oa.isFree ? 'oui' : 'non',
      reservationUrl: oa.link,
    );
  }
}
