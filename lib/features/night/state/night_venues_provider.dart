import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/venues_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/commerce/data/commerce_repository.dart';
import 'package:pulz_app/features/commerce/domain/models/commerce.dart';
import 'package:pulz_app/features/night/data/night_bars_data.dart';
import 'package:pulz_app/core/database/app_database.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';
import 'package:pulz_app/features/day/state/user_events_provider.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/mode/state/mode_subcategory_provider.dart';

/// Tags qui utilisent les donnees curatees au lieu de la base locale.
const _curatedTags = {'Bar de nuit', 'Bar a cocktails', 'Pub', 'Club Discotheque', 'Epicerie de nuit', 'Tabac de nuit', 'Hotel', 'SOS Apero', 'Bar a chicha', 'Spicy', 'Coquin', 'Strip'};

/// Sub_grid parents → liste de leurs enfants pour le count.
const _subGridChildren = <String, List<String>>{
  'Spicy': ['Coquin', 'Strip'],
};

/// Aliases de sous-categorie → onglet night. Quand un user_event a une
/// sous-categorie semantiquement proche (ex: "DJ set", "Showcase", "Soiree"
/// = clubbing), on veut qu'il remonte dans l'onglet correspondant meme si le
/// nom exact ne contient pas le tag.
const _nightCategoryAliases = <String, Set<String>>{
  'club discotheque': {
    'dj set',
    'showcase',
    'soiree',
    'soirée',
    'soiree privee',
    'club',
    'clubbing',
    'afterclub',
  },
  'bar de nuit': {'bar', 'afterwork', 'after work', 'apero', 'apéro'},
  'bar a cocktails': {'cocktail', 'cocktails', 'mixologie'},
  'pub': {'pub', 'biere', 'bière', 'taproom'},
  'bar a chicha': {'chicha', 'shisha', 'narguile'},
};

/// Match "tolerant" entre la sous-categorie d'un user_event et un onglet night.
/// Couvre 3 cas :
///   1. Match direct bidirectionnel (ex: cat="Club" matche tag="Club Discotheque")
///   2. Alias curated : "DJ set"/"Showcase"/"Soiree" → Club Discotheque
///   3. Insensible a la casse et aux accents
bool matchesNightCategoryTag(String eventCategorie, String searchTag) {
  final cat = eventCategorie.toLowerCase().trim();
  final tag = searchTag.toLowerCase().trim();
  if (cat.isEmpty || tag.isEmpty) return false;
  if (cat.contains(tag) || tag.contains(cat)) return true;
  final aliases = _nightCategoryAliases[tag];
  if (aliases != null && aliases.any((a) => cat.contains(a))) return true;
  return false;
}

/// Evenements utilisateur filtres pour la rubrique "night".
final nightUserEventsProvider = Provider<List<Event>>((ref) {
  final city = ref.watch(selectedCityProvider);
  final allUserEvents = ref.watch(userEventsProvider);
  return allUserEvents
      .where((ue) =>
          ue.rubrique == 'night' &&
          ue.ville.toLowerCase() == city.toLowerCase())
      .map((ue) => ue.toEvent())
      .toList();
});

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Evenements scrapes des clubs de nuit (Nine Club + Etoile) depuis la DB.
final nightScrapedEventsProvider = FutureProvider<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  return ScrapedEventsSupabaseService().fetchEvents(
    rubrique: 'night',
    dateGte: _todayStr(),
    ville: city,
  );
});

/// Filtre les events pour ne garder que ceux a venir (>= aujourd'hui).
List<Event> _upcomingOnly(List<Event> events) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return events.where((e) {
    final d = DateTime.tryParse(e.dateDebut);
    return d != null && !d.isBefore(today);
  }).toList();
}

int _nightUserCount(List<Event> userEvents, List<Event> scrapedEvents, String searchTag) {
  if (searchTag == 'A venir') {
    return _upcomingOnly(userEvents).length + _upcomingOnly(scrapedEvents).length;
  }
  return userEvents.where((e) => matchesNightCategoryTag(e.categorie, searchTag)).length;
}

final nightCategoryCountProvider =
    FutureProvider.family<int, String>((ref, searchTag) async {
  final userEvents = ref.watch(nightUserEventsProvider);
  final scrapedEvents = ref.watch(nightScrapedEventsProvider).valueOrNull ?? [];
  final uc = _nightUserCount(userEvents, scrapedEvents, searchTag);
  if (searchTag == 'A venir') {
    return uc;
  }
  if (_curatedTags.contains(searchTag)) {
    final city = ref.watch(selectedCityProvider);
    // Si c'est un sub_grid parent, additionner les counts des enfants
    final children = _subGridChildren[searchTag];
    if (children != null) {
      try {
        var total = 0;
        for (final child in children) {
          total += await VenuesSupabaseService().countVenues(
            mode: 'night', ville: city, category: child,
          );
        }
        return total + uc;
      } catch (_) {
        return uc;
      }
    }
    try {
      final count = await VenuesSupabaseService().countVenues(
        mode: 'night', ville: city, category: searchTag,
      );
      return count + uc;
    } catch (_) {
      return NightBarsData.toulouseBars
          .where((b) => b.categorie == searchTag && b.ville.toLowerCase() == city.toLowerCase())
          .length + uc;
    }
  }
  final city = ref.watch(selectedCityProvider);
  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  final venues = await repository.searchByVille(ville: city, query: searchTag);
  return venues.length + uc;
});

/// 4 sous-categories de bars affichees sur la carte combinee.
const nightBarCategories = ['Bar de nuit', 'Bar a cocktails', 'Pub', 'Bar a chicha'];

/// Sous-categories Spicy (Coquin + Strip) pour la carte combinee.
const nightSpicyCategories = ['Coquin', 'Strip'];

/// Tous les etablissements Spicy (Coquin + Strip) de la ville courante.
final nightSpicyForMapProvider = FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final results = <CommerceModel>[];
  for (final cat in nightSpicyCategories) {
    try {
      final venues = await VenuesSupabaseService().fetchVenues(
        mode: 'night', ville: city, category: cat,
      );
      if (venues.isNotEmpty) {
        results.addAll(venues);
        continue;
      }
    } catch (_) {}
    results.addAll(NightBarsData.toulouseBars.where((b) =>
        b.categorie == cat &&
        b.ville.toLowerCase() == city.toLowerCase()));
  }
  return _dedupeByNameAndPosition(results);
});

/// Tous les bars (4 types combines) de la ville courante. Utilise par la vue
/// carte des bars avec pins colores par type.
final nightBarsForMapProvider = FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final results = <CommerceModel>[];
  for (final cat in nightBarCategories) {
    try {
      final venues = await VenuesSupabaseService().fetchVenues(
        mode: 'night', ville: city, category: cat,
      );
      if (venues.isNotEmpty) {
        results.addAll(venues);
        continue;
      }
    } catch (_) {}
    results.addAll(NightBarsData.toulouseBars.where((b) =>
        b.categorie == cat &&
        b.ville.toLowerCase() == city.toLowerCase()));
  }
  return _dedupeByNameAndPosition(results);
});

/// Tous les clubs/discotheques de la ville courante, independamment de la
/// sous-categorie selectionnee. Utilise par la vue carte des clubs.
///
/// Dedupliqué sur (nom + lat + lng) pour ne pas empiler des markers
/// identiques quand la DB a plusieurs rows pour le meme etablissement.
final nightClubsForMapProvider = FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  List<CommerceModel> venues;
  try {
    venues = await VenuesSupabaseService().fetchVenues(
      mode: 'night', ville: city, category: 'Club Discotheque',
    );
    if (venues.isEmpty) {
      venues = NightBarsData.toulouseBars
          .where((b) =>
              b.categorie == 'Club Discotheque' &&
              b.ville.toLowerCase() == city.toLowerCase())
          .toList();
    }
  } catch (_) {
    venues = NightBarsData.toulouseBars
        .where((b) =>
            b.categorie == 'Club Discotheque' &&
            b.ville.toLowerCase() == city.toLowerCase())
        .toList();
  }
  return _dedupeByNameAndPosition(venues);
});

List<CommerceModel> _dedupeByNameAndPosition(List<CommerceModel> venues) {
  final seen = <String>{};
  final out = <CommerceModel>[];
  for (final v in venues) {
    final key = '${v.nom.trim().toLowerCase()}|${v.latitude.toStringAsFixed(5)}|${v.longitude.toStringAsFixed(5)}';
    if (seen.add(key)) out.add(v);
  }
  return out;
}

final nightVenuesProvider = FutureProvider<List<CommerceModel>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final category = ref.watch(nightCategoryProvider);

  if (_curatedTags.contains(category)) {
    try {
      final venues = await VenuesSupabaseService().fetchVenues(
        mode: 'night', ville: city, category: category,
      );
      if (venues.isNotEmpty) return venues;
    } catch (_) {}
    // Fallback statique — filtrer aussi par ville
    return NightBarsData.toulouseBars
        .where((b) => b.categorie == category && b.ville.toLowerCase() == city.toLowerCase())
        .toList();
  }

  final db = AppDatabase();
  final repository = CommerceRepository(db: db);
  return repository.searchByVille(ville: city, query: category);
});
