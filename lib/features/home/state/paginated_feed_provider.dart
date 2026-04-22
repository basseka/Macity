import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/sport/data/supabase_api_service.dart';
import 'package:pulz_app/features/sport/domain/models/supabase_match.dart';

class PaginatedFeedState {
  final List<Event> events;
  final List<SupabaseMatch> matches;
  final bool isLoading;
  final bool hasMore;

  const PaginatedFeedState({
    this.events = const [],
    this.matches = const [],
    this.isLoading = false,
    this.hasMore = true,
  });
}

/// Taille d'une page du feed. 200 permet de couvrir en moyenne 4-5 jours
/// d'events a Toulouse (40-50 events/jour en semaine), ce qui evite que les
/// events recemment scrapes d'un jour dense tombent en page 2 et passent
/// inapercus parce que l'user ne scrolle pas jusqu'au bout.
const _pageSize = 200;

final paginatedFeedProvider =
    StateNotifierProvider<PaginatedFeedNotifier, PaginatedFeedState>(
  (ref) {
    // Surveiller la ville — recree le notifier quand elle change
    ref.watch(selectedCityProvider);
    return PaginatedFeedNotifier(ref);
  },
);

class PaginatedFeedNotifier extends StateNotifier<PaginatedFeedState> {
  final Ref _ref;
  final _service = ScrapedEventsSupabaseService();
  final _matchService = SupabaseApiService();
  int _offset = 0;
  bool _loadingNext = false;
  List<String>? _rubriques;
  List<Event> _pendingUserEvents = [];

  PaginatedFeedNotifier(this._ref) : super(const PaginatedFeedState()) {
    _loadInitial();
  }

  /// Pour le tri du feed : les events multi-jours en cours (date_debut < today, date_fin >= today)
  /// sont triés comme s'ils commençaient aujourd'hui, pour ne pas noyer le feed.
  static String _effectiveDate(Event e) {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (e.dateDebut.compareTo(todayStr) < 0 && e.dateFin.isNotEmpty && e.dateFin.compareTo(todayStr) >= 0) {
      return todayStr;
    }
    return e.dateDebut;
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _city => _ref.read(selectedCityProvider);

  Future<void> _loadInitial() async {
    state = const PaginatedFeedState(isLoading: true);

    try {
      // Le feed affiche toutes les rubriques, independamment des preferences utilisateur.
      final rubriques = ['day', 'culture', 'night', 'family', 'food'];
      _rubriques = rubriques;

      final (events, rawCount) = await _service.fetchAllEvents(
        dateGte: _todayStr,
        ville: _city,
        limit: _pageSize,
        offset: 0,
        rubriques: rubriques,
      );
      _offset = _pageSize;

      // Matchs (une seule fois)
      List<SupabaseMatch> matches = [];
      try {
        matches = await _matchService.fetchMatches(
          ville: _city,
          dateGte: _todayStr,
        );
      } catch (e) {
        debugPrint('[PaginatedFeed] matches error: $e');
      }

      // User events — attendre qu'ils soient charges si la liste est vide
      var userEvents = _ref.read(userEventsProvider);
      if (userEvents.isEmpty) {
        // Attendre un peu que _init() finisse
        await Future.delayed(const Duration(milliseconds: 500));
        userEvents = _ref.read(userEventsProvider);
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final userFiltered = userEvents.where((ue) {
        if (ue.ville.toLowerCase() != _city.toLowerCase()) return false;
        final d = DateTime.tryParse(ue.date);
        if (d == null) return false;
        return !DateTime(d.year, d.month, d.day).isBefore(today);
      }).map((ue) => ue.toEvent()).toList();

      // Merge : user events seulement dans la plage de dates des scraped events
      final lastScrapedDate = events.isNotEmpty ? events.last.dateDebut : _todayStr;
      final userInRange = userFiltered.where((ue) => ue.dateDebut.compareTo(lastScrapedDate) <= 0).toList();
      _pendingUserEvents = userFiltered.where((ue) => ue.dateDebut.compareTo(lastScrapedDate) > 0).toList();

      final allEvents = [...events, ...userInRange];
      // Tri : events multi-jours en cours triés comme s'ils commençaient aujourd'hui
      allEvents.sort((a, b) => _effectiveDate(a).compareTo(_effectiveDate(b)));

      final hasMoreResult = rawCount >= _pageSize;

      state = PaginatedFeedState(
        events: allEvents,
        matches: matches,
        isLoading: false,
        hasMore: hasMoreResult,
      );
    } catch (e) {
      debugPrint('[PaginatedFeed] initial error: $e');
      state = const PaginatedFeedState(isLoading: false, hasMore: false);
    }
  }

  Future<void> loadNextPage() async {
    debugPrint('[PaginatedFeed] loadNextPage called. _loadingNext=$_loadingNext '
        'hasMore=${state.hasMore} offset=$_offset totalEvents=${state.events.length}');
    if (_loadingNext || !state.hasMore) {
      debugPrint('[PaginatedFeed] -> skipped (loadingNext or no more)');
      return;
    }
    _loadingNext = true;
    // Expose le loading pour que l'UI (auto-load sur filtre) ne fire pas en
    // boucle pendant qu'un fetch est en cours.
    state = PaginatedFeedState(
      events: state.events,
      matches: state.matches,
      isLoading: true,
      hasMore: state.hasMore,
    );

    try {
      final (newEvents, rawCount) = await _service.fetchAllEvents(
        dateGte: _todayStr,
        ville: _city,
        limit: _pageSize,
        offset: _offset,
        rubriques: _rubriques,
      );
      _offset += _pageSize;

      // Deduplication
      final existingIds = state.events.map((e) => e.identifiant).toSet();
      final unique = newEvents.where((e) => !existingIds.contains(e.identifiant)).toList();

      // Integrer les user events en attente
      List<Event> userToAdd;
      if (rawCount < _pageSize) {
        // Derniere page scraped → ajouter tous les user events restants
        userToAdd = _pendingUserEvents;
        _pendingUserEvents = [];
      } else {
        // Ajouter seulement ceux dans la plage
        final lastScrapedDate = newEvents.isNotEmpty ? newEvents.last.dateDebut : '';
        userToAdd = _pendingUserEvents.where((ue) => ue.dateDebut.compareTo(lastScrapedDate) <= 0).toList();
        _pendingUserEvents = _pendingUserEvents.where((ue) => ue.dateDebut.compareTo(lastScrapedDate) > 0).toList();
      }

      // Merge et re-trier par date
      final allEvents = [...state.events, ...unique, ...userToAdd];
      allEvents.sort((a, b) => _effectiveDate(a).compareTo(_effectiveDate(b)));

      final hasMoreResult = rawCount >= _pageSize;
      debugPrint('[PaginatedFeed] next page done. rawCount=$rawCount '
          'unique=${unique.length} total=${allEvents.length} '
          'hasMore=$hasMoreResult');

      state = PaginatedFeedState(
        events: allEvents,
        matches: state.matches,
        isLoading: false,
        hasMore: hasMoreResult,
      );
    } catch (e) {
      debugPrint('[PaginatedFeed] next page error: $e');
      state = PaginatedFeedState(
        events: state.events,
        matches: state.matches,
        isLoading: false,
        hasMore: state.hasMore,
      );
    } finally {
      _loadingNext = false;
    }
  }
}
