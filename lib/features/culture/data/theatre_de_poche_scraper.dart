import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Theatre de Poche Toulouse depuis
/// theatredepochetoulouse.fr/la-programmation-2/.
///
/// Strategie en 2 etapes :
/// 1. Decouvrir les sous-pages mois depuis la page principale
///    (liens vers /la-programmation-2/mars/, /la-programmation-2/avril/, etc.)
/// 2. Pour chaque page mois, parser les blocs spectacle :
///    <h3>DATE</h3> <p>HEURE</p> <a href="URL"><img alt="TITRE"></a>
///
/// Formats de date dans les <h3> :
///   "6 février"           → date unique
///   "4 et 5 février"      → 2 dates
///   "Du 25 au 28 février" → plage de dates
class TheatreDePocheScraper {
  TheatreDePocheScraper._();

  static const _baseUrl = 'https://theatredepochetoulouse.fr';
  static const _progUrl = '$_baseUrl/la-programmation-2/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Regex pour trouver les liens mois depuis la page principale.
  /// <a href="https://theatredepochetoulouse.fr/la-programmation-2/mars/">
  static final _monthLinkRegex = RegExp(
    r'<a\s+href="(https://theatredepochetoulouse\.fr/la-programmation-2/([a-z-]+)/)"',
  );

  /// "6 février" ou "6 mars"
  static final _singleDateRegex = RegExp(
    r'^(\d{1,2})\s+(\w+)$',
  );

  /// "4 et 5 février"
  static final _multiDateRegex = RegExp(
    r'^(\d{1,2})\s+et\s+(\d{1,2})\s+(\w+)$',
    caseSensitive: false,
  );

  /// "Du 25 au 28 février"
  static final _rangeDateRegex = RegExp(
    r'^Du\s+(\d{1,2})\s+au\s+(\d{1,2})\s+(\w+)$',
    caseSensitive: false,
  );

  static const _moisFr = <String, int>{
    'janvier': 1,
    'fevrier': 2,
    'février': 2,
    'mars': 3,
    'avril': 4,
    'mai': 5,
    'juin': 6,
    'juillet': 7,
    'août': 8,
    'aout': 8,
    'septembre': 9,
    'octobre': 10,
    'novembre': 11,
    'decembre': 12,
    'décembre': 12,
  };

  /// Mapping slug URL → numero de mois.
  static const _slugToMonth = <String, int>{
    'janvier': 1,
    'janvier-2': 1,
    'fevrier': 2,
    'mars': 3,
    'avril': 4,
    'mai': 5,
    'juin': 6,
    'juillet': 7,
    'aout': 8,
    'septembre': 9,
    'octobre': 10,
    'novembre': 11,
    'decembre': 12,
  };

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      // --- Etape 1 : decouvrir les pages mois ---
      final monthUrls = await _discoverMonthPages();
      if (monthUrls.isEmpty) return [];

      // --- Etape 2 : scraper chaque page mois ---
      final events = <Event>[];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final results = await Future.wait(
        monthUrls.map((m) => _fetchMonthPage(m, today)),
      );
      for (final list in results) {
        events.addAll(list);
      }

      events.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return events;
    } catch (_) {
      return [];
    }
  }

  /// Fetch la page principale et retourner les URLs des pages mois.
  static Future<List<_MonthPage>> _discoverMonthPages() async {
    try {
      final response = await _dio.get<String>(_progUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final pages = <String, _MonthPage>{};
      for (final match in _monthLinkRegex.allMatches(html)) {
        final url = match.group(1)!;
        final slug = match.group(2)!;
        // Eviter les doublons
        if (!pages.containsKey(slug)) {
          final monthNum = _slugToMonth[slug];
          if (monthNum != null) {
            pages[slug] = _MonthPage(url: url, slug: slug, month: monthNum);
          }
        }
      }
      return pages.values.toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch une page mois et parser les spectacles.
  static Future<List<Event>> _fetchMonthPage(
    _MonthPage monthPage,
    DateTime today,
  ) async {
    try {
      final response = await _dio.get<String>(monthPage.url);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = <Event>[];
      final seen = <String>{};

      // Strategie : decouper le HTML en blocs par <h3>
      final h3Parts = html.split(RegExp(r'<h3[^>]*>'));
      for (var i = 1; i < h3Parts.length; i++) {
        final part = h3Parts[i];

        // Extraire le contenu du h3
        final h3End = part.indexOf('</h3>');
        if (h3End < 0) continue;
        final h3Content = _cleanHtml(part.substring(0, h3End)).trim();
        if (h3Content.isEmpty) continue;

        // Ignorer les h3 de navigation (ex: titres de section)
        if (!RegExp(r'\d').hasMatch(h3Content)) continue;

        final afterH3 = part.substring(h3End);

        // Extraire l'heure depuis le prochain <p>
        final timeMatch = RegExp(r'<p[^>]*>(\d{1,2}h\d{0,2})</p>').firstMatch(afterH3);
        final horaires = timeMatch != null ? timeMatch.group(1)! : '';

        // Extraire le lien et le titre depuis <a href="..."><img alt="...">
        final linkMatch = RegExp(
          r'<a\s+href="([^"]+)"[^>]*>\s*<img[^>]*?alt="([^"]*)"',
        ).firstMatch(afterH3);

        String url = '';
        String titre = '';
        if (linkMatch != null) {
          url = linkMatch.group(1) ?? '';
          titre = _cleanHtml(linkMatch.group(2) ?? '');
        }

        // Fallback : titre depuis le texte du lien
        if (titre.isEmpty) {
          final altMatch = RegExp(r'alt="([^"]+)"').firstMatch(afterH3);
          if (altMatch != null) titre = _cleanHtml(altMatch.group(1)!);
        }
        if (titre.isEmpty) continue;

        // Parser les dates depuis le h3
        final dates = _parseDates(h3Content, monthPage.month, today);
        if (dates.isEmpty) continue;

        // Creer un event par date (pour les plages multi-jours, on prend debut/fin)
        final dateDebut = dates.first;
        final dateFin = dates.last;

        final dateDebutStr = _isoDate(dateDebut);
        final dateFinStr = _isoDate(dateFin);

        // Filtrer les evenements passes
        if (dateFin.isBefore(today)) continue;

        final slug = titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        final id = 'poche_${slug}_$dateDebutStr';
        if (!seen.add(id)) continue;

        // S'assurer que l'URL est absolue
        if (url.isNotEmpty && !url.startsWith('http')) {
          url = '$_baseUrl$url';
        }

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: titre,
          descriptifLong: titre,
          dateDebut: dateDebutStr,
          dateFin: dateFinStr,
          horaires: horaires,
          datesAffichageHoraires: '$h3Content $horaires',
          lieuNom: 'Theatre de Poche',
          lieuAdresse: '2 rue du Poids de l\'Huile',
          commune: 'Toulouse',
          codePostal: 31000,
          type: 'Theatre',
          categorie: 'Theatre',
          reservationUrl: url,
        ),);
      }

      return events;
    } catch (_) {
      return [];
    }
  }

  /// Parse les dates depuis le texte du h3.
  /// Retourne une liste de DateTime (1 element pour date unique, 2 pour plage).
  static List<DateTime> _parseDates(
    String text,
    int fallbackMonth,
    DateTime today,
  ) {
    // "Du 25 au 28 février"
    final rangeMatch = _rangeDateRegex.firstMatch(text);
    if (rangeMatch != null) {
      final d1 = int.tryParse(rangeMatch.group(1)!);
      final d2 = int.tryParse(rangeMatch.group(2)!);
      final m = _moisFr[rangeMatch.group(3)!.toLowerCase()] ?? fallbackMonth;
      if (d1 != null && d2 != null) {
        final year = _inferYear(m, d1, today);
        return [DateTime(year, m, d1), DateTime(year, m, d2)];
      }
    }

    // "4 et 5 février"
    final multiMatch = _multiDateRegex.firstMatch(text);
    if (multiMatch != null) {
      final d1 = int.tryParse(multiMatch.group(1)!);
      final d2 = int.tryParse(multiMatch.group(2)!);
      final m = _moisFr[multiMatch.group(3)!.toLowerCase()] ?? fallbackMonth;
      if (d1 != null && d2 != null) {
        final year = _inferYear(m, d1, today);
        return [DateTime(year, m, d1), DateTime(year, m, d2)];
      }
    }

    // "6 février"
    final singleMatch = _singleDateRegex.firstMatch(text);
    if (singleMatch != null) {
      final d = int.tryParse(singleMatch.group(1)!);
      final m = _moisFr[singleMatch.group(2)!.toLowerCase()] ?? fallbackMonth;
      if (d != null) {
        final year = _inferYear(m, d, today);
        return [DateTime(year, m, d)];
      }
    }

    // Fallback : essayer d'extraire juste un nombre (jour) sans mois
    final dayOnly = RegExp(r'(\d{1,2})').firstMatch(text);
    if (dayOnly != null) {
      final d = int.tryParse(dayOnly.group(1)!);
      if (d != null) {
        final year = _inferYear(fallbackMonth, d, today);
        return [DateTime(year, fallbackMonth, d)];
      }
    }

    return [];
  }

  static int _inferYear(int month, int day, DateTime today) {
    var year = today.year;
    final candidate = DateTime(year, month, day);
    if (candidate.isBefore(today.subtract(const Duration(days: 60)))) {
      year++;
    }
    return year;
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

class _MonthPage {
  final String url;
  final String slug;
  final int month;

  const _MonthPage({
    required this.url,
    required this.slug,
    required this.month,
  });
}
