import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/day/data/user_event_supabase_service.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';
import 'package:pulz_app/features/search/domain/search_result.dart';
import 'package:pulz_app/features/sport/data/supabase_api_service.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

/// Orchestrates parallel search across scraped_events, matchs, and user_events.
class UnifiedSearchService {
  final ScrapedEventsSupabaseService _scrapedService;
  final SupabaseApiService _matchService;
  final UserEventSupabaseService _userEventService;

  UnifiedSearchService({
    ScrapedEventsSupabaseService? scrapedService,
    SupabaseApiService? matchService,
    UserEventSupabaseService? userEventService,
  })  : _scrapedService = scrapedService ?? ScrapedEventsSupabaseService(),
        _matchService = matchService ?? SupabaseApiService(),
        _userEventService = userEventService ?? UserEventSupabaseService();

  /// Search all sources in parallel and return deduplicated, sorted results.
  Future<List<SearchResult>> search(String query) async {
    final queryLower = query.toLowerCase();

    final futureScraped = _scrapedService.searchEvents(query, limit: 30);
    final futureMatches = _matchService.searchMatches(query, limit: 15);
    final futureUserEvents = _userEventService.searchEvents(query, limit: 15);

    final results = await Future.wait([
      futureScraped,
      futureMatches,
      futureUserEvents,
    ]);

    final scrapedEvents = results[0] as List<Event>;
    final matches = results[1] as List<SupabaseMatch>;
    final userEvents = results[2] as List<UserEvent>;

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
