import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Fetch la programmation du Theatre du Pave depuis
/// l'API REST Tribe Events Calendar :
/// theatredupave.org/wp-json/tribe/events/v1/events
///
/// Chaque evenement contient directement : title, start_date, end_date,
/// url, image, cost.
class TheatreDuPaveScraper {
  TheatreDuPaveScraper._();

  static const _apiUrl =
      'https://theatredupave.org/wp-json/tribe/events/v1/events';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ));

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await _dio.get<String>(
        _apiUrl,
        queryParameters: {
          'per_page': 50,
          'start_date': dateStr,
        },
      );

      final body = response.data;
      if (body == null || body.isEmpty) return [];

      final Map<String, dynamic> result = json.decode(body);
      final List<dynamic> items = result['events'] ?? [];
      final events = <Event>[];

      for (final item in items) {
        final titre = _cleanHtml(item['title']?.toString() ?? '');
        if (titre.isEmpty) continue;

        final startDate = item['start_date']?.toString() ?? '';
        if (startDate.isEmpty) continue;

        final dateDebut = startDate.substring(0, 10);
        final endDate = item['end_date']?.toString() ?? '';
        final dateFin =
            endDate.isNotEmpty ? endDate.substring(0, 10) : dateDebut;

        // Horaire depuis start_date (format "2026-03-15 20:30:00")
        final horaires = startDate.length >= 16
            ? '${startDate.substring(11, 13)}h${startDate.substring(14, 16)}'
            : '';

        final url = item['url']?.toString() ?? '';
        final cost = item['cost']?.toString() ?? '';
        final imageUrl = (item['image'] as Map<String, dynamic>?)?['url']?.toString();
        final slug = item['slug']?.toString() ?? titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        final id = 'pave_${slug}_$dateDebut';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: titre,
          descriptifLong: titre,
          dateDebut: dateDebut,
          dateFin: dateFin,
          horaires: horaires,
          datesAffichageHoraires: '$dateDebut $horaires',
          lieuNom: 'Theatre du Pave',
          lieuAdresse: '34 rue Maran',
          commune: 'Toulouse',
          codePostal: 31400,
          type: 'Theatre',
          categorie: 'Theatre',
          tarifNormal: cost,
          reservationUrl: url,
          photoPath: imageUrl,
        ));
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
        .replaceAll('&#8211;', '\u2013')
        .replaceAll('&#8217;', '\u2019')
        .replaceAll('&#038;', '&')
        .replaceAll('&#8230;', '\u2026')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
