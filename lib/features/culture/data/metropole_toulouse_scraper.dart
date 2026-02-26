import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Configuration d'un lieu sur metropole.toulouse.fr.
class MetropoleVenueConfig {
  final String extId;
  final String idPrefix;
  final String lieuNom;
  final String lieuAdresse;
  final int codePostal;

  const MetropoleVenueConfig({
    required this.extId,
    required this.idPrefix,
    required this.lieuNom,
    required this.lieuAdresse,
    required this.codePostal,
  });
}

/// Scrape la programmation d'un lieu depuis
/// metropole.toulouse.fr/agenda?ext={extId}.
///
/// Strategie en 2 etapes :
/// 1. Lister les evenements via la page agenda filtree (2 pages max)
/// 2. Pour chaque evenement, fetch la page detail et parser le JSON-LD
///    (schema.org Event) qui contient startDate/endDate en ISO 8601.
class MetropoleToulouseScraper {
  MetropoleToulouseScraper._();

  static const _baseUrl = 'https://metropole.toulouse.fr';
  static const _listUrl = '$_baseUrl/agenda';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Regex pour extraire les liens evenement depuis la page liste.
  static final _eventLinkRegex = RegExp(
    r'<a\s+href="(/agenda/[a-z0-9][a-z0-9-]*)"[^>]*>([^<]+)</a>',
  );

  /// Regex pour extraire le bloc JSON-LD depuis une page detail.
  static final _jsonLdRegex = RegExp(
    r'<script\s+type="application/ld\+json"[^>]*>([\s\S]*?)</script>',
  );

  /// Regex pour "Gratuit" ou un tarif en euros.
  static final _tarifRegex = RegExp(
    r'(Gratuit|(\d+(?:[.,]\d+)?)\s*€)',
    caseSensitive: false,
  );

  static Future<List<Event>> fetchUpcomingEvents(
    MetropoleVenueConfig config,
  ) async {
    try {
      final slugs = <String>{};
      for (var page = 0; page <= 1; page++) {
        final pageSlugs = await _fetchListPage(config.extId, page);
        slugs.addAll(pageSlugs);
        if (pageSlugs.length < 12) break;
      }

      if (slugs.isEmpty) return [];

      final events = <Event>[];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final slugList = slugs.toList();
      const batchSize = 6;
      for (var i = 0; i < slugList.length; i += batchSize) {
        final batch = slugList.skip(i).take(batchSize);
        final results = await Future.wait(
          batch.map((slug) => _fetchEventDetail(slug, today, config)),
        );
        for (final event in results) {
          if (event != null) events.add(event);
        }
      }

      events.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return events;
    } catch (_) {
      return [];
    }
  }

  static Future<Set<String>> _fetchListPage(String extId, int page) async {
    try {
      final response = await _dio.get<String>(
        _listUrl,
        queryParameters: {
          'ext': extId,
          'page': page,
        },
      );
      final html = response.data;
      if (html == null || html.isEmpty) return {};

      final slugs = <String>{};
      for (final match in _eventLinkRegex.allMatches(html)) {
        final path = match.group(1) ?? '';
        final slug = path.replaceFirst('/agenda/', '');
        if (slug.isNotEmpty && !slug.contains('/')) {
          slugs.add(slug);
        }
      }
      return slugs;
    } catch (_) {
      return {};
    }
  }

  static Future<Event?> _fetchEventDetail(
    String slug,
    DateTime today,
    MetropoleVenueConfig config,
  ) async {
    try {
      final url = '$_baseUrl/agenda/$slug';
      final response = await _dio.get<String>(url);
      final html = response.data;
      if (html == null || html.isEmpty) return null;

      final jsonLdMatch = _jsonLdRegex.firstMatch(html);
      if (jsonLdMatch == null) return null;

      final jsonStr = jsonLdMatch.group(1) ?? '';
      final Map<String, dynamic> jsonLd = json.decode(jsonStr);

      final List<dynamic> graph = jsonLd['@graph'] ?? [];
      if (graph.isEmpty) return null;

      final item = graph[0] as Map<String, dynamic>;

      final titre = _cleanText(item['name']?.toString() ?? '');
      if (titre.isEmpty) return null;

      final startDateStr = item['startDate']?.toString() ?? '';
      if (startDateStr.isEmpty) return null;

      final startDt = DateTime.tryParse(startDateStr);
      if (startDt == null) return null;

      final endDateStr = item['endDate']?.toString() ?? '';
      final endDt = DateTime.tryParse(endDateStr);

      final endDate = endDt ?? startDt;
      final endDay = DateTime(endDate.year, endDate.month, endDate.day);
      if (endDay.isBefore(today)) return null;

      final dateDebut =
          '${startDt.year}-${startDt.month.toString().padLeft(2, '0')}-${startDt.day.toString().padLeft(2, '0')}';
      final dateFin = endDt != null
          ? '${endDt.year}-${endDt.month.toString().padLeft(2, '0')}-${endDt.day.toString().padLeft(2, '0')}'
          : dateDebut;

      final horaires =
          '${startDt.hour.toString().padLeft(2, '0')}h${startDt.minute.toString().padLeft(2, '0')}';

      final description = _cleanText(item['description']?.toString() ?? '');

      final imageUrl = (item['image'] as Map<String, dynamic>?)?['url']?.toString();

      final tarif = _extractTarif(html);

      final id = '${config.idPrefix}_${slug}_$dateDebut';

      return Event(
        identifiant: id,
        titre: titre,
        descriptifCourt: description.isNotEmpty ? description : titre,
        descriptifLong: description,
        dateDebut: dateDebut,
        dateFin: dateFin,
        horaires: horaires,
        datesAffichageHoraires: '$dateDebut $horaires',
        lieuNom: config.lieuNom,
        lieuAdresse: config.lieuAdresse,
        commune: 'Toulouse',
        codePostal: config.codePostal,
        type: 'Theatre',
        categorie: 'Theatre',
        tarifNormal: tarif,
        reservationUrl: url,
        photoPath: imageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static String _extractTarif(String html) {
    final match = _tarifRegex.firstMatch(html);
    if (match == null) return '';
    return match.group(0) ?? '';
  }

  static String _cleanText(String text) {
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
