import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du 3T Cafe Theatre (new.3tcafetheatre.com).
///
/// Strategie en 2 etapes :
/// 1. Lister les spectacles via l'API REST WordPress
///    GET /wp-json/wp/v2/spectacle?per_page=100
/// 2. Pour chaque spectacle, fetch la page HTML et extraire les dates
///    depuis les <h4> avec spans .un / .deux / .trois
///
/// Chaque date produit un [Event] distinct.
class ThreeTScraper {
  ThreeTScraper._();

  static const _apiUrl =
      'https://new.3tcafetheatre.com/wp-json/wp/v2/spectacle';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ));

  /// Regex pour les blocs date dans les pages spectacle.
  /// <h4><span class="un">vendredi</span><span class="deux">5 Mar</span><span class="trois">20h</span></h4>
  static final _dateBlockRegex = RegExp(
    r'<h4[^>]*><span class="un">([^<]*)</span><span class="deux">([^<]*)</span><span class="trois">([^<]*)</span></h4>',
  );

  /// Tarif unique : 28€
  static final _tarifUniqueRegex = RegExp(r'Tarif unique\s*:?\s*(\d+)\s*€');

  /// Plein : 28€ / Réduit ou Plein 27€, Réduit 24€...
  static final _tarifPleinRegex = RegExp(r'Plein\s*:?\s*(\d+)\s*€');

  static const _moisAbrev = <String, int>{
    'jan': 1,
    'fév': 2,
    'fev': 2,
    'mar': 3,
    'avr': 4,
    'mai': 5,
    'jun': 6,
    'jui': 7,
    'aoû': 8,
    'aou': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'déc': 12,
    'dec': 12,
  };

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      // --- Etape 1 : lister tous les spectacles via l'API ---
      final spectacles = await _fetchAllSpectacles();
      if (spectacles.isEmpty) return [];

      // --- Etape 2 : pour chaque spectacle, fetch les dates ---
      final events = <Event>[];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Fetch en parallele par lots de 10
      const batchSize = 10;
      for (var i = 0; i < spectacles.length; i += batchSize) {
        final batch = spectacles.skip(i).take(batchSize);
        final results = await Future.wait(
          batch.map((s) => _fetchSpectacleDates(s, today)),
        );
        for (final list in results) {
          events.addAll(list);
        }
      }

      events.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return events;
    } catch (_) {
      return [];
    }
  }

  /// Fetch la liste de tous les spectacles depuis l'API WP (2 pages max).
  static Future<List<_Spectacle>> _fetchAllSpectacles() async {
    final all = <_Spectacle>[];
    for (var page = 1; page <= 2; page++) {
      try {
        final response = await _dio.get<String>(
          _apiUrl,
          queryParameters: {
            'per_page': 100,
            'page': page,
            '_fields': 'id,slug,title,excerpt,link',
          },
        );
        final body = response.data;
        if (body == null || body.isEmpty) break;
        final List<dynamic> items = json.decode(body);
        if (items.isEmpty) break;
        for (final item in items) {
          final title = _cleanHtml(
            (item['title'] as Map<String, dynamic>?)?['rendered']?.toString() ?? '',
          );
          if (title.isEmpty) continue;
          final excerpt = _cleanHtml(
            (item['excerpt'] as Map<String, dynamic>?)?['rendered']?.toString() ?? '',
          );
          all.add(_Spectacle(
            slug: item['slug']?.toString() ?? '',
            title: title,
            excerpt: excerpt,
            link: item['link']?.toString() ?? '',
          ));
        }
      } catch (_) {
        break;
      }
    }
    return all;
  }

  /// Fetch la page HTML d'un spectacle et extraire les dates a venir.
  static Future<List<Event>> _fetchSpectacleDates(
    _Spectacle spectacle,
    DateTime today,
  ) async {
    try {
      final url = spectacle.link.isNotEmpty
          ? spectacle.link
          : 'https://new.3tcafetheatre.com/spectacle/${spectacle.slug}/';
      final response = await _dio.get<String>(url);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      // Extraire les dates (dedup car elles apparaissent 2x dans le HTML)
      final seenDates = <String>{};
      final dates = <_ShowDate>[];
      for (final match in _dateBlockRegex.allMatches(html)) {
        final datePart = match.group(2) ?? ''; // "5 Mar"
        final timePart = match.group(3) ?? ''; // "20h" ou "18h45"
        final key = '$datePart|$timePart';
        if (!seenDates.add(key)) continue;

        final parsed = _parseDate(datePart, today);
        if (parsed == null) continue;
        if (parsed.isBefore(today)) continue;

        dates.add(_ShowDate(date: parsed, time: timePart.trim()));
      }

      if (dates.isEmpty) return [];

      // Extraire le tarif
      final tarifMatch = _tarifUniqueRegex.firstMatch(html) ??
          _tarifPleinRegex.firstMatch(html);
      final tarif = tarifMatch != null ? '${tarifMatch.group(1)}€' : '';

      // Construire un Event par date
      return dates.map((d) {
        final dateStr =
            '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}';
        final id = '3t_${spectacle.slug}_$dateStr';
        return Event(
          identifiant: id,
          titre: spectacle.title,
          descriptifCourt: spectacle.excerpt.isNotEmpty
              ? spectacle.excerpt
              : spectacle.title,
          descriptifLong: spectacle.excerpt,
          dateDebut: dateStr,
          dateFin: dateStr,
          horaires: d.time,
          datesAffichageHoraires: '${_formatDateFr(d.date)} ${d.time}',
          lieuNom: '3T Cafe Theatre',
          lieuAdresse: '40 rue Gabriel Peri',
          commune: 'Toulouse',
          codePostal: 31000,
          type: 'Humour',
          categorie: 'Theatre',
          tarifNormal: tarif,
          reservationUrl: url,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Parse "5 Mar" ou "28 Fév" vers DateTime.
  /// Infere l'annee : si le mois est passe, c'est l'annee prochaine.
  static DateTime? _parseDate(String raw, DateTime today) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;

    final day = int.tryParse(parts[0]);
    if (day == null) return null;

    final monthStr = parts[1].toLowerCase();
    int? month;
    for (final entry in _moisAbrev.entries) {
      if (monthStr.startsWith(entry.key)) {
        month = entry.value;
        break;
      }
    }
    if (month == null) return null;

    // Inferer l'annee
    var year = today.year;
    final candidate = DateTime(year, month, day);
    // Si la date est > 2 mois dans le passe, c'est probablement l'annee prochaine
    if (candidate.isBefore(today.subtract(const Duration(days: 60)))) {
      year++;
    }
    return DateTime(year, month, day);
  }

  static String _formatDateFr(DateTime d) {
    const jours = ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'];
    const mois = [
      '', 'jan', 'fev', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aou', 'sep', 'oct', 'nov', 'dec',
    ];
    return '${jours[d.weekday - 1]} ${d.day} ${mois[d.month]}';
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
        .replaceAll('&#8230;', '\u2026')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _Spectacle {
  final String slug;
  final String title;
  final String excerpt;
  final String link;

  const _Spectacle({
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.link,
  });
}

class _ShowDate {
  final DateTime date;
  final String time;

  const _ShowDate({required this.date, required this.time});
}
