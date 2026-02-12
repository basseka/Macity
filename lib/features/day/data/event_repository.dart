import 'package:pulz_app/features/day/data/event_api_service.dart';
import 'package:pulz_app/features/day/data/open_agenda_api_service.dart';
import 'package:pulz_app/features/day/data/day_curated_data.dart';
import 'package:pulz_app/features/day/data/concert_toulouse_service.dart';
import 'package:pulz_app/features/day/data/festival_toulouse_service.dart';
import 'package:pulz_app/features/day/data/opera_toulouse_service.dart';
import 'package:pulz_app/features/day/data/djset_toulouse_service.dart';
import 'package:pulz_app/features/day/data/showcase_toulouse_service.dart';
import 'package:pulz_app/features/day/data/spectacle_toulouse_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/domain/models/open_agenda_event.dart';

class EventRepository {
  final EventApiService _eventApi;
  final OpenAgendaApiService _openAgendaApi;
  final ConcertToulouseService _concertService;
  final FestivalToulouseService _festivalService;
  final OperaToulouseService _operaService;
  final DjSetToulouseService _djSetService;
  final ShowcaseToulouseService _showcaseService;
  final SpectacleToulouseService _spectacleService;

  EventRepository({
    EventApiService? eventApi,
    OpenAgendaApiService? openAgendaApi,
    ConcertToulouseService? concertService,
    FestivalToulouseService? festivalService,
    OperaToulouseService? operaService,
    DjSetToulouseService? djSetService,
    ShowcaseToulouseService? showcaseService,
    SpectacleToulouseService? spectacleService,
  })  : _eventApi = eventApi ?? EventApiService(),
        _openAgendaApi = openAgendaApi ?? OpenAgendaApiService(),
        _concertService = concertService ?? ConcertToulouseService(),
        _festivalService = festivalService ?? FestivalToulouseService(),
        _operaService = operaService ?? OperaToulouseService(),
        _djSetService = djSetService ?? DjSetToulouseService(),
        _showcaseService = showcaseService ?? ShowcaseToulouseService(),
        _spectacleService = spectacleService ?? SpectacleToulouseService();

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

  Future<List<Event>> _fetchToulouseEvents(String subcategory) async {
    switch (subcategory) {
      case 'Cette Semaine':
        return _fetchThisWeekAll();
      case 'Concert':
        return _concertService.fetchUpcomingConcerts();
      case 'Festival':
        return _festivalService.fetchUpcomingFestivals();
      case 'Opera':
        return _operaService.fetchUpcomingOperas();
      case 'DJ set':
        return _djSetService.fetchUpcomingDjSets();
      case 'Showcase':
        return _showcaseService.fetchUpcomingShowcases();
      case 'Spectacle':
        return _spectacleService.fetchUpcomingSpectacles();
      case 'Boxe':
        return DayCuratedData.getBoxeToulouse();
      case 'Natation':
        return DayCuratedData.getNatationToulouse();
      default:
        return _eventApi.fetchByCategory(subcategory);
    }
  }

  /// Agrege les resultats des 5 rubriques et filtre sur 7 jours glissants.
  Future<List<Event>> _fetchThisWeekAll() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(const Duration(days: 7));

    // Agreger les 6 rubriques en parallele (pas de recherche API propre)
    final results = await Future.wait([
      _concertService.fetchUpcomingConcerts().catchError((_) => <Event>[]),
      _festivalService.fetchUpcomingFestivals().catchError((_) => <Event>[]),
      _operaService.fetchUpcomingOperas().catchError((_) => <Event>[]),
      _djSetService.fetchUpcomingDjSets().catchError((_) => <Event>[]),
      _showcaseService.fetchUpcomingShowcases().catchError((_) => <Event>[]),
      _spectacleService.fetchUpcomingSpectacles().catchError((_) => <Event>[]),
    ]);

    // Merge tout
    final all = <Event>[];
    for (final list in results) {
      all.addAll(list);
    }

    // Filtrer sur 7 jours glissants
    final thisWeek = all.where((e) {
      final d = DateTime.tryParse(e.dateDebut);
      if (d == null) return false;
      return !d.isBefore(today) && d.isBefore(endDate);
    }).toList();

    // Dedup par titre normalise + date
    final seen = <String>{};
    final deduped = <Event>[];
    for (final e in thisWeek) {
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
    final keyword = subcategory == 'Cette Semaine' ? null : subcategory;
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
