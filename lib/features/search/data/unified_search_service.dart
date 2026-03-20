import 'package:dio/dio.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/core/services/activity_service.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/search/domain/search_result.dart';
import 'package:pulz_app/features/sport/data/supabase_api_service.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

/// Orchestrates parallel search across scraped_events, matchs, user_events and etablissements.
class UnifiedSearchService {
  final ScrapedEventsSupabaseService _scrapedService;
  final SupabaseApiService _matchService;
  final UserEventSupabaseService _userEventService;
  final Dio _dio;

  UnifiedSearchService({
    ScrapedEventsSupabaseService? scrapedService,
    SupabaseApiService? matchService,
    UserEventSupabaseService? userEventService,
    Dio? dio,
  })  : _scrapedService = scrapedService ?? ScrapedEventsSupabaseService(),
        _matchService = matchService ?? SupabaseApiService(),
        _userEventService = userEventService ?? UserEventSupabaseService(),
        _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Retire les accents d'une chaine pour la recherche.
  static String _removeAccents(String input) {
    const accents = 'àâäáãåèéêëìíîïòóôöõùúûüýÿñçœæ';
    const plain  = 'aaaaaaeeeeiiiioooooouuuuyyncoea';
    var result = input;
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], plain[i]);
    }
    return result;
  }

  /// Search all sources in parallel and return deduplicated, sorted results.
  Future<List<SearchResult>> search(String query, {String? ville}) async {
    ActivityService.instance.search(query: query);
    final normalized = _removeAccents(query.toLowerCase());
    final queryLower = normalized;

    // Chercher avec et sans accents pour couvrir les deux cas
    final futureScraped = _scrapedService.searchEvents(normalized, limit: 30);
    final futureMatches = _matchService.searchMatches(normalized, limit: 15);
    final futureUserEvents = _userEventService.searchEvents(normalized, limit: 15);
    final futureVenues = _searchVenues(normalized, ville: ville, limit: 20);

    final results = await Future.wait([
      futureScraped,
      futureMatches,
      futureUserEvents,
      futureVenues,
    ]);

    final scrapedEvents = results[0] as List<Event>;
    final matches = results[1] as List<SupabaseMatch>;
    final userEvents = results[2] as List<UserEvent>;
    final venues = results[3] as List<VenueResult>;

    final searchResults = <SearchResult>[];

    // Wrap scraped events
    for (final event in scrapedEvents) {
      searchResults.add(EventResult(
        event: event,
        relevance: _eventRelevance(event, queryLower),
        date: event.dateDebut,
      ));
    }

    // Wrap matches
    for (final match in matches) {
      searchResults.add(MatchResult(
        match: match,
        relevance: _matchRelevance(match, queryLower),
        date: match.date,
      ));
    }

    // Wrap user events (converted to Event via toEvent())
    for (final userEvent in userEvents) {
      final event = userEvent.toEvent();
      searchResults.add(EventResult(
        event: event,
        relevance: _userEventRelevance(userEvent, queryLower),
        date: userEvent.date,
      ));
    }

    // Add venue results
    searchResults.addAll(venues);

    // Deduplicate by deduplicationKey
    final seen = <String>{};
    final deduplicated = <SearchResult>[];
    for (final r in searchResults) {
      if (seen.add(r.deduplicationKey)) {
        deduplicated.add(r);
      }
    }

    // Sort by relevance (asc) then date (asc)
    deduplicated.sort((a, b) {
      final cmp = a.relevance.compareTo(b.relevance);
      if (cmp != 0) return cmp;
      return a.date.compareTo(b.date);
    });

    return deduplicated;
  }

  /// Recherche dans la table etablissements (restaurants, bars, commerces).
  Future<List<VenueResult>> _searchVenues(String query, {String? ville, int limit = 20}) async {
    try {
      final params = <String, String>{
        'select': 'id,nom,categorie,adresse,horaires,telephone,site_web,lien_maps',
        'is_active': 'eq.true',
        'or': '(nom.ilike.*$query*,categorie.ilike.*$query*,adresse.ilike.*$query*)',
        'order': 'nom.asc',
        'limit': '$limit',
      };
      if (ville != null && ville.isNotEmpty) {
        params['ville'] = 'ilike.$ville';
      }
      final response = await _dio.get(
        'etablissements',
        queryParameters: params,
      );
      final data = response.data as List;
      final q = query.toLowerCase();
      return data.map((json) {
        final j = json as Map<String, dynamic>;
        final name = j['nom'] as String? ?? '';
        final cat = j['categorie'] as String? ?? '';
        final relevance = name.toLowerCase().contains(q) ? 0
            : cat.toLowerCase().contains(q) ? 1
            : 2;
        return VenueResult(
          id: '${j['id'] ?? name}',
          name: name,
          categorie: cat,
          adresse: j['adresse'] as String? ?? '',
          horaires: j['horaires'] as String? ?? '',
          telephone: j['telephone'] as String? ?? '',
          siteWeb: j['site_web'] as String? ?? '',
          lienMaps: j['lien_maps'] as String? ?? '',
          relevance: relevance,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Relevance scoring ──

  int _eventRelevance(Event event, String q) {
    if (event.titre.toLowerCase().contains(q)) return 0;
    if (event.lieuNom.toLowerCase().contains(q) ||
        event.descriptifCourt.toLowerCase().contains(q)) return 1;
    return 2;
  }

  int _matchRelevance(SupabaseMatch match, String q) {
    if (match.equipe1.toLowerCase().contains(q) ||
        match.equipe2.toLowerCase().contains(q)) return 0;
    if (match.lieu.toLowerCase().contains(q) ||
        match.competition.toLowerCase().contains(q)) return 1;
    return 2;
  }

  int _userEventRelevance(UserEvent userEvent, String q) {
    if (userEvent.titre.toLowerCase().contains(q)) return 0;
    if (userEvent.lieuNom.toLowerCase().contains(q) ||
        userEvent.description.toLowerCase().contains(q)) {
      return 1;
    }
    return 2;
  }
}
