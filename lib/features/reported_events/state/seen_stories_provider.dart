import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Set d'IDs des stories Map Live "deja vues" par ce device.
///
/// Persiste dans SharedPreferences. Une story est vue des que l'utilisateur
/// tape sur sa card (ouverture du PagedSheet). Les permanent fake stories sont
/// considerees vues d'office pour ne pas gonfler le compteur "nouveau".
class SeenStoriesNotifier extends StateNotifier<Set<String>> {
  SeenStoriesNotifier() : super(<String>{}) {
    _load();
  }

  static const _prefsKey = 'seen_map_live_stories';

  // Permanent fake stories : `permanent_fake_stories.dart` les expose avec ces
  // 3 IDs. On les marque vues d'office pour ne pas qu'elles apparaissent en
  // "nouveau" a chaque ouverture de l'app.
  static const _bootstrapSeen = <String>{
    'fake-story-permanent-1',
    'fake-story-permanent-2',
    'fake-story-permanent-3',
  };

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey)?.toSet() ?? <String>{};
    state = {..._bootstrapSeen, ...stored};
  }

  Future<void> markSeen(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    final prefs = await SharedPreferences.getInstance();
    // On ne persiste que les vraies stories (pas les bootstrap fakes, inutile).
    final toPersist = state.difference(_bootstrapSeen).toList();
    await prefs.setStringList(_prefsKey, toPersist);
  }
}

final seenStoriesProvider =
    StateNotifierProvider<SeenStoriesNotifier, Set<String>>(
  (_) => SeenStoriesNotifier(),
);
