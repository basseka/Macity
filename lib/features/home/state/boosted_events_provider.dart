import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/city/domain/city_aliases.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/user_event.dart';

String _today() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

Future<int> _getConfigInt(String key, int defaultValue) async {
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    final response = await dio.get('app_config', queryParameters: {
      'select': 'value',
      'key': 'eq.$key',
      'limit': '1',
    });
    final data = response.data as List;
    if (data.isNotEmpty) {
      return int.tryParse(data.first['value'] as String) ?? defaultValue;
    }
  } catch (_) {}
  return defaultValue;
}

Future<List<UserEvent>> _fetchByPriority(String city, String priority, int limit) async {
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());

    // Filtre par metropole entiere (events Blagnac visibles depuis Toulouse).
    // Si la ville n'est pas dans la map d'aliases, retombe sur la ville seule.
    final aliases = cityAliasesFor(city);
    final orClause = aliases.map((c) => 'ville.ilike.$c').join(',');

    // Desambiguisation Saint-Denis 93 vs 974 (et autres homonymes futurs) :
    // si le dept canonique de la ville est connu, on filtre ville+dept en
    // tolerant les events legacy sans dept renseigne (`dept.is.null`).
    final dept = deptForCity(city);
    final params = <String, dynamic>{
      'select': '*',
      'priority': 'eq.$priority',
      'date': 'gte.${_today()}',
      'order': 'date.asc',
      'limit': '$limit',
    };
    if (dept != null) {
      params['and'] = '(or($orClause),or(dept.eq.$dept,dept.is.null))';
    } else {
      params['or'] = '($orClause)';
    }

    final response = await dio.get('user_events', queryParameters: params);

    final data = response.data as List;
    return data.map((e) => UserEvent.fromSupabaseJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint('[BoostedEvents] error fetching $priority: $e');
    return [];
  }
}

// ── Admin-pinned events merge ─────────────────────────────────────────
//
// Les pins admin (table admin_pins) peuvent referencer :
// - user_events (id) → on recupere la row telle quelle
// - scraped_events (identifiant) → on convertit en UserEvent synthetique
// Les pins s'ajoutent AU DESSUS des events P1/P2 (dedup par id) sans
// consommer le quota boosted_p1_max / boosted_p2_max.

Future<UserEvent?> _fetchUserEventById(String id) async {
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    final response = await dio.get('user_events', queryParameters: {
      'select': '*',
      'id': 'eq.$id',
      'limit': '1',
    });
    final data = response.data as List;
    if (data.isEmpty) return null;
    return UserEvent.fromSupabaseJson(data.first as Map<String, dynamic>);
  } catch (e) {
    debugPrint('[BoostedEvents] fetchUserEvent $id failed: $e');
    return null;
  }
}

/// Convertit une row `scraped_events` en `UserEvent` synthetique pour
/// l'affichage uniforme dans les carousels P1/P2.
UserEvent _scrapedRowToUserEvent(Map<String, dynamic> r) {
  final rubrique = r['rubrique'] as String? ?? 'day';
  final photoUrl = r['photo_url'] as String?;
  return UserEvent(
    id: r['identifiant'] as String,
    titre: r['nom_de_la_manifestation'] as String? ?? '',
    description: r['descriptif_court'] as String? ?? '',
    descriptionCourte: r['descriptif_court'] as String? ?? '',
    descriptionLongue: r['descriptif_long'] as String? ?? '',
    categorie: rubrique.toUpperCase(),
    rubrique: rubrique,
    date: r['date_debut'] as String? ?? '',
    heure: r['horaires'] as String? ?? '',
    lieuNom: r['lieu_nom'] as String? ?? '',
    lieuAdresse: r['lieu_adresse_2'] as String? ?? '',
    ville: r['commune'] as String? ?? '',
    photoUrl: photoUrl != null && photoUrl.isNotEmpty ? photoUrl : null,
    lienBilletterie: r['reservation_site_internet'] as String? ?? '',
    createdAt: DateTime.now(),
    dateFin: r['date_fin'] as String? ?? '',
    priority: 'ADMIN', // marqueur pour distinguer les pins admin
  );
}

Future<UserEvent?> _fetchScrapedAsUserEvent(String identifiant) async {
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    final response = await dio.get('scraped_events', queryParameters: {
      'select':
          'identifiant,nom_de_la_manifestation,date_debut,date_fin,horaires,lieu_nom,lieu_adresse_2,commune,photo_url,descriptif_court,descriptif_long,reservation_site_internet,source,rubrique',
      'identifiant': 'eq.$identifiant',
      'limit': '1',
    });
    final data = response.data as List;
    if (data.isEmpty) return null;
    return _scrapedRowToUserEvent(data.first as Map<String, dynamic>);
  } catch (e) {
    debugPrint('[BoostedEvents] fetchScraped $identifiant failed: $e');
    return null;
  }
}

Future<List<UserEvent>> _fetchAdminPinnedEvents(String pinType, String city) async {
  try {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final response = await dio.get('admin_pins', queryParameters: {
      'select': 'event_source,event_identifiant,display_city',
      'pin_type': 'eq.$pinType',
      'pinned_until': 'gte.$nowIso',
      'order': 'created_at.desc',
    });
    final pins = response.data as List;
    if (pins.isEmpty) return const [];
    // Pre-filtre par display_city quand il est renseigne (override admin) :
    // le pin n'est visible que pour les users connectes a cette ville,
    // independamment de la ville reelle de l'event. Pour les anciens pins
    // sans display_city, on retombe sur le filtre `e.ville` plus bas.
    // display_city = strict equality (override admin intentionnel,
    // pas elargi a la metropole).
    final cityLc = city.toLowerCase();
    final aliasesLc = cityAliasesLcFor(city);
    final filteredPins = pins.where((p) {
      final m = p as Map<String, dynamic>;
      final dc = m['display_city'] as String?;
      if (dc == null || dc.isEmpty) return true;
      return dc.toLowerCase() == cityLc;
    }).toList();
    if (filteredPins.isEmpty) return const [];
    // Le `event_source` enregistre est utilise comme HINT (ordre de lookup),
    // pas comme verite absolue : le feed peut historiquement avoir insere des
    // pins avec le mauvais source (cf bug feed_screen.dart hardcode
    // `scrapedEvents` pour tous les pins). Si la 1ere table est miss, on
    // retombe sur l'autre — ca rattrape les rows orphelines deja en DB.
    final futures = filteredPins.map<Future<(UserEvent?, String?)>>((p) async {
      final m = p as Map<String, dynamic>;
      final src = m['event_source'] as String;
      final id = m['event_identifiant'] as String;
      final dc = m['display_city'] as String?;
      final UserEvent? evt;
      if (src == 'user_events') {
        evt = await _fetchUserEventById(id) ?? await _fetchScrapedAsUserEvent(id);
      } else {
        evt = await _fetchScrapedAsUserEvent(id) ?? await _fetchUserEventById(id);
      }
      return (evt, dc);
    });
    final results = await Future.wait(futures);
    // Pour les pins avec display_city : deja pre-filtres ci-dessus, on garde.
    // Pour les pins sans display_city (legacy) : filtre par metropole entiere
    // via les aliases (events Blagnac visibles depuis Toulouse).
    return results
        .where((r) => r.$1 != null)
        .where((r) {
          final hasOverride = r.$2 != null && r.$2!.isNotEmpty;
          if (hasOverride) return true;
          final ville = r.$1!.ville;
          if (ville.isEmpty) return true;
          return aliasesLc.contains(ville.toLowerCase());
        })
        .map((r) => r.$1!)
        .toList();
  } catch (e) {
    debugPrint('[BoostedEvents] fetchAdminPinned $pinType failed: $e');
    return const [];
  }
}

/// Events boostés P1 "A la une" + pins admin (featured).
/// Les pins s'ajoutent EN TETE de la liste (admin au-dessus des P1).
final boostedEventsProvider = FutureProvider<List<UserEvent>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final max = await _getConfigInt('boosted_p1_max', 5);
  final results = await Future.wait([
    _fetchByPriority(city, 'P1', max),
    _fetchAdminPinnedEvents('featured', city),
  ]);
  final p1 = results[0];
  final pinned = results[1];
  if (pinned.isEmpty) return p1;
  final pinnedIds = pinned.map((e) => e.id).toSet();
  // Admin pins en premier + P1 events non-deja-pinnes a la suite
  return [...pinned, ...p1.where((e) => !pinnedIds.contains(e.id))];
});

/// Events boostés P2 "Au top" + pins admin (top).
final boostedP2EventsProvider = FutureProvider<List<UserEvent>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final max = await _getConfigInt('boosted_p2_max', 6);
  final results = await Future.wait([
    _fetchByPriority(city, 'P2', max),
    _fetchAdminPinnedEvents('top', city),
  ]);
  final p2 = results[0];
  final pinned = results[1];
  if (pinned.isEmpty) return p2;
  final pinnedIds = pinned.map((e) => e.id).toSet();
  return [...pinned, ...p2.where((e) => !pinnedIds.contains(e.id))];
});
