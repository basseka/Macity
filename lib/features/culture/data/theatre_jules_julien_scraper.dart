import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Fetch la programmation du Theatre Jules Julien depuis
/// l'API REST WordPress du Conservatoire de Toulouse :
/// conservatoire.toulouse.fr/wp-json/wp/v2/onct-events?onct-event-lieu=158
///
/// Chaque evenement contient dans son champ meta :
///   onct-event-day, onct-event-month, onct-event-year,
///   onct-event-hour, onct-event-minute, onct-event-duration,
///   onct-event-desc, onct-event-free-entrance, onct-event-past.
class TheatreJulesJulienScraper {
  TheatreJulesJulienScraper._();

  static const _apiUrl =
      'https://conservatoire.toulouse.fr/wp-json/wp/v2/onct-events';

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
          'onct-event-lieu': 158,
          'per_page': 100,
        },
      );

      final body = response.data;
      if (body == null || body.isEmpty) return [];

      final List<dynamic> items = json.decode(body);
      final events = <Event>[];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final item in items) {
        final meta = item['meta'] as Map<String, dynamic>? ?? {};

        // Ignorer les evenements passes
        if (meta['onct-event-past'] == true) continue;

        final day = _toInt(meta['onct-event-day']);
        final month = _toInt(meta['onct-event-month']);
        final year = _toInt(meta['onct-event-year']);
        final hour = _toInt(meta['onct-event-hour']);
        final minute = _toInt(meta['onct-event-minute']);

        if (day == 0 || month == 0 || year == 0) continue;

        final eventDate = DateTime(year, month, day);
        if (eventDate.isBefore(today)) continue;

        final dateStr =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final horaires =
            '${hour.toString().padLeft(2, '0')}h${minute.toString().padLeft(2, '0')}';

        // Calculer la date de fin depuis la duree
        final durationSecs = _toInt(meta['onct-event-duration']);
        String dateFin = dateStr;
        if (durationSecs > 0 && !_toBool(meta['onct-event-one-day'])) {
          final endTimestamp = _toInt(meta['onct-event-end-timestamp']);
          if (endTimestamp > 0) {
            final endDt =
                DateTime.fromMillisecondsSinceEpoch(endTimestamp * 1000);
            dateFin =
                '${endDt.year}-${endDt.month.toString().padLeft(2, '0')}-${endDt.day.toString().padLeft(2, '0')}';
          }
        }

        final titre = _cleanHtml(
          (item['title'] as Map<String, dynamic>?)?['rendered']?.toString() ??
              '',
        );
        if (titre.isEmpty) continue;

        final shortDesc =
            _cleanHtml(meta['onct-event-short-desc']?.toString() ?? '');
        final longDesc =
            _cleanHtml(meta['onct-event-desc']?.toString() ?? '');

        final isFree = _toBool(meta['onct-event-free-entrance']);

        final imageUrl = meta['onct-event-img']?.toString();

        final slug = item['slug']?.toString() ??
            titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        final id = 'julesjulien_${slug}_$dateStr';

        final link = item['link']?.toString() ?? '';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: shortDesc.isNotEmpty ? shortDesc : titre,
          descriptifLong: longDesc.isNotEmpty ? longDesc : titre,
          dateDebut: dateStr,
          dateFin: dateFin,
          horaires: horaires,
          datesAffichageHoraires: '$dateStr $horaires',
          lieuNom: 'Theatre Jules Julien',
          lieuAdresse: '4 rue Jules Julien',
          commune: 'Toulouse',
          codePostal: 31400,
          type: 'Theatre',
          categorie: 'Theatre',
          tarifNormal: isFree ? 'Gratuit' : '',
          reservationUrl: link.isNotEmpty ? link : '',
          photoPath: imageUrl,
        ),);
      }

      events.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return events;
    } catch (_) {
      return [];
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
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
        .replaceAll('&#8211;', '\u2013')
        .replaceAll('&#8217;', '\u2019')
        .replaceAll('&#038;', '&')
        .replaceAll('&#8230;', '\u2026')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
