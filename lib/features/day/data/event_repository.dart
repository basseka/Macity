import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/data/open_agenda_api_service.dart';
import 'package:pulz_app/features/day/data/day_curated_data.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/domain/models/open_agenda_event.dart';

class EventRepository {
  final EventApiService _eventApi;
  final OpenAgendaApiService _openAgendaApi;
  final ScrapedEventsSupabaseService _scrapedService;

  EventRepository({
    EventApiService? eventApi,
    OpenAgendaApiService? openAgendaApi,
    ScrapedEventsSupabaseService? scrapedService,
  })  : _eventApi = eventApi ?? EventApiService(),
        _openAgendaApi = openAgendaApi ?? OpenAgendaApiService(),
        _scrapedService = scrapedService ?? ScrapedEventsSupabaseService();

  /// Fetch events: Toulouse uses OpenDataSoft, other cities use OpenAgenda
  Future<List<Event>> fetchEvents({
    required String city,
    required String subcategory,
  }) async {
    if (city == 'Toulouse') {
      return _fetchToulouseEvents(subcategory);
    } else {
      return _fetchNationalEvents(city, subcategory);
    }
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
  };

  Future<List<Event>> _fetchToulouseEvents(String subcategory) async {
    if (subcategory == 'A venir') {
      return _fetchAllUpcoming();
    }
    if (subcategory == 'Boxe') {
      return DayCuratedData.getBoxeToulouse();
    }
    if (subcategory == 'Natation') {
      return DayCuratedData.getNatationToulouse();
    }
    final source = _subcategoryToSource[subcategory];
    if (source != null) {
      return _scrapedService.fetchEvents(
        rubrique: 'day',
        source: source,
        dateGte: _todayStr(),
      );
    }
    return _eventApi.fetchByCategory(subcategory);
  }

  /// Agrege tous les events day depuis la DB.
  Future<List<Event>> _fetchAllUpcoming() async {
    final all = await _scrapedService.fetchEvents(
      rubrique: 'day',
      dateGte: _todayStr(),
    );

    // Dedup par titre normalise + date
    final seen = <String>{};
    final deduped = <Event>[];
    for (final e in all) {
      final key =
          '${e.titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}|${e.dateDebut}';
      if (seen.add(key)) {
        deduped.add(e);
      }
    }

    // Tri par categorie puis date
    deduped.sort((a, b) {
      final catCmp = _categoryOrder(a).compareTo(_categoryOrder(b));
      if (catCmp != 0) return catCmp;
      return a.dateDebut.compareTo(b.dateDebut);
    });

    return deduped;
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
    return 6;
  }

  Future<List<Event>> _fetchNationalEvents(
    String city,
    String subcategory,
  ) async {
    final keyword = subcategory == 'A venir' ? null : subcategory;
    final openAgendaEvents = await _openAgendaApi.fetchEvents(
      city: city,
      keyword: keyword,
    );

    // Convert OpenAgendaEvent → Event for unified display
    return openAgendaEvents.map(_convertOpenAgendaToEvent).toList();
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
