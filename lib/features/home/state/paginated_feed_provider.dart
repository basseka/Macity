import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/features/onboarding/state/onboarding_provider.dart';
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

const _pageSize = 100;

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

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get _city => _ref.read(selectedCityProvider);

  Future<void> _loadInitial() async {
    state = const PaginatedFeedState(isLoading: true);

    try {
      // Preferences utilisateur
      final prefs = await _ref.read(userPreferencesProvider.future);
      final hasPrefs = prefs.isNotEmpty;
      final rubriques = <String>[];
      if (!hasPrefs || prefs.contains('day')) rubriques.add('day');
      if (!hasPrefs || prefs.contains('culture')) rubriques.add('culture');
      if (!hasPrefs || prefs.contains('night')) rubriques.add('night');
      if (!hasPrefs || prefs.contains('family')) rubriques.add('family');
      if (!hasPrefs || prefs.contains('food')) rubriques.add('food');
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
      final wantSport = !hasPrefs || prefs.contains('sport');
      if (wantSport) {
        try {
          matches = await _matchService.fetchMatches(
            ville: _city,
            dateGte: _todayStr,
          );
        } catch (e) {
          debugPrint('[PaginatedFeed] matches error: $e');
        }
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
      allEvents.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

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
    if (_loadingNext || !state.hasMore) return;
    _loadingNext = true;

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
      allEvents.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

      final hasMoreResult = rawCount >= _pageSize;

      state = PaginatedFeedState(
        events: allEvents,
        matches: state.matches,
        isLoading: false,
        hasMore: hasMoreResult,
      );
    } catch (e) {
      debugPrint('[PaginatedFeed] next page error: $e');
    } finally {
      _loadingNext = false;
    }
  }
}
