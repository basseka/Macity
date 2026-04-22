import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
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

    final response = await dio.get(
      'user_events',
      queryParameters: {
        'select': '*',
        'priority': 'eq.$priority',
        'date': 'gte.${_today()}',
        'ville': 'ilike.$city',
        'order': 'date.asc',
        'limit': '$limit',
      },
    );

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
      'select': 'event_source,event_identifiant',
      'pin_type': 'eq.$pinType',
      'pinned_until': 'gte.$nowIso',
      'order': 'created_at.desc',
    });
    final pins = response.data as List;
    if (pins.isEmpty) return const [];
    final futures = pins.map<Future<UserEvent?>>((p) {
      final m = p as Map<String, dynamic>;
      final src = m['event_source'] as String;
      final id = m['event_identifiant'] as String;
      if (src == 'user_events') return _fetchUserEventById(id);
      return _fetchScrapedAsUserEvent(id);
    });
    final results = await Future.wait(futures);
    // Filtre par ville selectionnee (case insensitive, exact match).
    // Si l'event n'a pas de ville renseignee, on le garde (fallback safe).
    final cityLc = city.toLowerCase();
    return results.whereType<UserEvent>().where((e) {
      if (e.ville.isEmpty) return true;
      return e.ville.toLowerCase() == cityLc;
    }).toList();
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
