import 'package:dio/dio.dart';
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
  }) async {
    final params = <String, String>{
      'select': '*',
      'rubrique': 'eq.$rubrique',
      'order': 'date_debut.asc',
    };
    if (source != null) {
      params['source'] = 'eq.$source';
    } else if (sourceNotIn != null && sourceNotIn.isNotEmpty) {
      params['source'] = 'not.in.(${sourceNotIn.join(",")})';
    }
    if (dateGte != null) params['date_debut'] = 'gte.$dateGte';
    if (lieuNom != null) params['lieu_nom'] = 'ilike.*$lieuNom*';

    final response = await _dio.get(
      'scraped_events',
      queryParameters: params,
    );
    final data = response.data as List;
    return data.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
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
        'order': 'date_debut.asc',
        'limit': '$limit',
      },
    );
    final data = response.data as List;
    return data.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }
}
