import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulz_app/core/constants/api_constants.dart';
import 'package:pulz_app/core/network/dio_client.dart';
import 'package:pulz_app/core/network/supabase_interceptor.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Service qui lit les evenements scrapes depuis la table `scraped_events`
/// de Supabase. Les scrapers s'executent cote serveur (Edge Functions + pg_cron)
/// et l'app ne fait que lire les donnees.
class ScrapedEventsSupabaseService {
  final Dio _dio;

  ScrapedEventsSupabaseService({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = DioClient.withBaseUrl(ApiConstants.supabaseRestUrl);
    dio.interceptors.add(SupabaseInterceptor());
    return dio;
  }

  /// Fetch scraped events filtered by rubrique and optional source/date.
  ///
  /// [sourceNotIn] excludes events whose source is in the given list
  /// (PostgREST `not.in.()` filter).
  Future<List<Event>> fetchEvents({
    required String rubrique,
    String? source,
    String? dateGte,
    List<String>? sourceNotIn,
    String? lieuNom,
    String? ville,
    String? categorie,
    int limit = 1000,
    int offset = 0,
    bool requirePhoto = true,
  }) async {
    final params = <String, String>{
      'select': '*',
      'rubrique': 'eq.$rubrique',
      'order': 'date_debut.asc',
      'limit': '$limit',
      'offset': '$offset',
    };
    // Filtrer les events sans photo cote serveur (PostgREST)
    // not.is.null exclut NULL, neq. exclut les strings vides
    if (requirePhoto) {
      params['photo_url'] = 'neq.';
    }
    if (source != null) {
      params['source'] = 'eq.$source';
    } else if (sourceNotIn != null && sourceNotIn.isNotEmpty) {
      params['source'] = 'not.in.(${sourceNotIn.join(",")})';
    }
    if (dateGte != null) {
      // Inclure les events multi-jours dont date_fin >= today
      params['or'] = '(date_debut.gte.$dateGte,date_fin.gte.$dateGte)';
    }
    if (lieuNom != null) params['lieu_nom'] = 'ilike.*$lieuNom*';
    if (ville != null) params['ville'] = 'ilike.$ville';
    if (categorie != null) params['categorie_de_la_manifestation'] = 'eq.$categorie';

    final response = await _dio.get(
      'scraped_events',
      queryParameters: params,
    );
    final data = response.data as List;
    // Parse sur un isolate pour ne pas bloquer le main thread
    if (requirePhoto) {
      return compute(_parseAndFilter, data);
    }
    return compute(_parseAll, data);
  }

  /// Fetch all events across rubriques, sorted by date, with pagination.
  /// Returns (filteredEvents, rawDbCount) to correctly determine hasMore.
  ///
  /// Fait 2 requêtes en parallèle :
  ///  1. Events qui commencent aujourd'hui ou après (date_debut >= today)
  ///  2. Events multi-jours en cours (date_debut < today AND date_fin >= today)
  /// Puis fusionne et trie.
  Future<(List<Event>, int)> fetchAllEvents({
    String? dateGte,
    String? ville,
    int limit = 50,
    int offset = 0,
    List<String>? rubriques,
  }) async {
    final commonParams = <String, String>{
      'select': '*',
      // Tri primaire par date de l'event, secondaire par horaire.
      // Sans order secondaire, les events du meme jour sont renvoyes dans un
      // ordre dependant du plan Postgres (souvent par id d'insertion) — ce
      // qui pousse les events recemment scrapes en fin de bucket, parfois
      // hors de la page 1. Ordonner par horaires.asc donne un ordre
      // chronologique reel dans la journee (matin -> soir), et surtout stable.
      'order': 'date_debut.asc,horaires.asc',
      'photo_url': 'neq.',
    };
    if (ville != null) commonParams['ville'] = 'ilike.$ville';
    if (rubriques != null && rubriques.isNotEmpty) {
      commonParams['rubrique'] = 'in.(${rubriques.join(",")})';
    }

    // 1. Events futurs (date_debut >= today) — paginé normalement
    final futureParams = Map<String, String>.from(commonParams);
    futureParams['limit'] = '$limit';
    futureParams['offset'] = '$offset';
    if (dateGte != null) futureParams['date_debut'] = 'gte.$dateGte';

    // 2. Events multi-jours en cours (date_debut < today AND date_fin >= today) — tous, une seule fois
    final ongoingParams = Map<String, String>.from(commonParams);
    ongoingParams['limit'] = '200';
    ongoingParams['offset'] = '0';
    if (dateGte != null) {
      ongoingParams['date_debut'] = 'lt.$dateGte';
      ongoingParams['date_fin'] = 'gte.$dateGte';
    }

    final results = await Future.wait([
      _dio.get('scraped_events', queryParameters: futureParams),
      if (dateGte != null && offset == 0)
        _dio.get('scraped_events', queryParameters: ongoingParams),
    ]);

    final futureData = results[0].data as List;
    final ongoingData = results.length > 1 ? results[1].data as List : <dynamic>[];

    final futureEvents = await compute(_parseAndFilter, futureData);
    final ongoingEvents = ongoingData.isNotEmpty
        ? await compute(_parseAndFilter, ongoingData)
        : <Event>[];

    // Dedup (au cas ou un event serait dans les deux)
    final seenIds = futureEvents.map((e) => e.identifiant).toSet();
    final uniqueOngoing = ongoingEvents.where((e) => !seenIds.contains(e.identifiant)).toList();

    final allEvents = [...uniqueOngoing, ...futureEvents];
    return (allEvents, futureData.length);
  }

  /// Fetch a single event by its identifiant.
  Future<Event?> fetchEventById(String identifiant) async {
    final response = await _dio.get(
      'scraped_events',
      queryParameters: {
        'select': '*',
        'identifiant': 'eq.$identifiant',
        'limit': '1',
      },
    );
    final data = response.data as List;
    if (data.isEmpty) return null;
    try {
      return Event.fromJson(data.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Search events by name, description, lieu, or category across all rubriques.
  Future<List<Event>> searchEvents(String query, {int limit = 30}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await _dio.get(
      'scraped_events',
      queryParameters: <String, String>{
        'select': '*',
        'or':
            '(nom_de_la_manifestation.ilike.*$query*,descriptif_court.ilike.*$query*,lieu_nom.ilike.*$query*,type_de_manifestation.ilike.*$query*,categorie_de_la_manifestation.ilike.*$query*)',
        'date_debut': 'gte.$today',
        'photo_url': 'not.is.null',
        'order': 'date_debut.asc',
        'limit': '$limit',
      },
    );
    final data = response.data as List;
    return compute(_parseAndFilter, data);
  }
}

/// Top-level function (required for compute/isolate).
/// Parse JSON rows safely, skip malformed, filter empty photo_url.
List<Event> _parseAndFilter(List data) {
  final results = <Event>[];
  for (final item in data) {
    try {
      final event = Event.fromJson(item as Map<String, dynamic>);
      if (event.photoPath != null && event.photoPath!.isNotEmpty) {
        results.add(event);
      }
    } catch (_) {
      // skip malformed event
    }
  }
  return results;
}

/// Parse all events without photo filter.
List<Event> _parseAll(List data) {
  final results = <Event>[];
  for (final item in data) {
    try {
      results.add(Event.fromJson(item as Map<String, dynamic>));
    } catch (_) {}
  }
  return results;
}
