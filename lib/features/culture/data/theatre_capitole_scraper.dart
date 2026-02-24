import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Fetch la programmation du Theatre du Capitole depuis
/// l'API REST WordPress : opera.toulouse.fr/wp-json/wp/v2/onct-events.
///
/// Chaque evenement contient dans `meta` :
/// - onct-event-day / month / year : date de debut
/// - onct-event-timestamp / end-timestamp : timestamps UNIX
/// - onct-event-desc / short-desc : descriptions HTML
/// - onct-event-registration-link : lien billetterie
/// - onct-event-past : true si passe
class TheatreCapitoleScraper {
  TheatreCapitoleScraper._();

  static const _apiUrl =
      'https://opera.toulouse.fr/wp-json/wp/v2/onct-events';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(
        _apiUrl,
        queryParameters: {
          'per_page': 50,
          '_fields': 'id,title,link,meta',
        },
      );

      final body = response.data;
      if (body == null || body.isEmpty) return [];

      final List<dynamic> items = json.decode(body);
      final events = <Event>[];

      for (final item in items) {
        final meta = item['meta'] as Map<String, dynamic>? ?? {};

        // Filtrer les evenements passes
        if (meta['onct-event-past'] == true) continue;

        final titleObj = item['title'] as Map<String, dynamic>? ?? {};
        final titre = _cleanHtml(titleObj['rendered']?.toString() ?? '');
        if (titre.isEmpty) continue;

        final day = (meta['onct-event-day'] as num?)?.toInt() ?? 0;
        final month = (meta['onct-event-month'] as num?)?.toInt() ?? 0;
        final year = (meta['onct-event-year'] as num?)?.toInt() ?? 0;
        if (day == 0 || month == 0 || year == 0) continue;

        final dateDebut =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

        // Date de fin via end-timestamp
        String dateFin = dateDebut;
        final endTs = (meta['onct-event-end-timestamp'] as num?)?.toInt();
        if (endTs != null && endTs > 0) {
          final endDt =
              DateTime.fromMillisecondsSinceEpoch(endTs * 1000, isUtc: true);
          dateFin =
              '${endDt.year}-${endDt.month.toString().padLeft(2, '0')}-${endDt.day.toString().padLeft(2, '0')}';
        }

        // Horaire
        final hour = (meta['onct-event-hour'] as num?)?.toInt();
        final minute = (meta['onct-event-minute'] as num?)?.toInt() ?? 0;
        final horaires = hour != null
            ? '${hour}h${minute.toString().padLeft(2, '0')}'
            : '';

        // Description
        final desc = _cleanHtml(
            meta['onct-event-desc']?.toString() ?? '',);
        final shortDesc = _cleanHtml(
            meta['onct-event-short-desc']?.toString() ?? '',);

        // Lien billetterie
        final regLink =
            meta['onct-event-registration-link']?.toString() ?? '';
        final detailLink = item['link']?.toString() ?? '';
        final freeEntrance = meta['onct-event-free-entrance'] == true;

        final slug = Uri.tryParse(detailLink)
                ?.pathSegments
                .where((s) => s.isNotEmpty)
                .lastOrNull ??
            titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        final id = 'capitole_${slug}_$dateDebut';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: shortDesc.isNotEmpty ? shortDesc : titre,
          descriptifLong: desc.isNotEmpty ? desc : titre,
          dateDebut: dateDebut,
          dateFin: dateFin,
          datesAffichageHoraires: horaires.isNotEmpty
              ? '$dateDebut $horaires'
              : dateDebut,
          horaires: horaires,
          lieuNom: 'Theatre du Capitole',
          lieuAdresse: 'Place du Capitole',
          commune: 'Toulouse',
          codePostal: 31000,
          type: freeEntrance ? 'Gratuit' : 'Opera',
          categorie: 'Theatre',
          tarifNormal: freeEntrance ? 'Gratuit' : '',
          reservationUrl: regLink.isNotEmpty ? regLink : detailLink,
        ),);
      }

      events.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return events;
    } catch (_) {
      return [];
    }
  }

  static String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&rsquo;', '\u2019')
        .replaceAll('&lsquo;', '\u2018')
        .replaceAll('&rdquo;', '\u201D')
        .replaceAll('&ldquo;', '\u201C')
        .replaceAll('&#8211;', '\u2013')
        .replaceAll('&#8217;', '\u2019')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
