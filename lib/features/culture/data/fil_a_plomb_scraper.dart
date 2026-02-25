import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Theatre le Fil a Plomb depuis
/// theatrelefilaplomb.fr/programmation-tout-public/ et
/// theatrelefilaplomb.fr/programmation-jeune-public/.
///
/// Chaque spectacle est un lien <a> dont le texte contient :
///   "TITRE – Du JOUR DD au JOUR DD MOIS YYYY à HHhMM"
///   "TITRE – Le JOUR DD MOIS YYYY à HHhMM"
/// On parse le texte du lien pour en extraire titre, date debut, date fin, horaire.
class FilAPlombScraper {
  FilAPlombScraper._();

  static const _urls = [
    'https://theatrelefilaplomb.fr/programmation-tout-public/',
    'https://theatrelefilaplomb.fr/programmation-jeune-public/',
  ];

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Regex pour extraire les liens spectacle avec dates.
  static final _linkRegex = RegExp(
    r'<a\s+href="(https://theatrelefilaplomb\.fr/[a-z0-9-]+/)"[^>]*>([^<]+)</a>',
  );

  /// "Du JOUR DD au JOUR DD MOIS YYYY à HHhMM"
  static final _rangeRegex = RegExp(
    r'Du\s+\w+\s+(\d{1,2})\s+au\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+[àa]\s+(\d{1,2})h(\d{2})?',
    caseSensitive: false,
  );

  /// "Le JOUR DD MOIS YYYY à HHhMM"
  static final _singleRegex = RegExp(
    r'Le\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+[àa]\s+(\d{1,2})h(\d{2})?',
    caseSensitive: false,
  );

  /// "Du DD au DD MOIS YYYY" (variante sans jour de la semaine)
  static final _rangeShortRegex = RegExp(
    r'Du\s+(\d{1,2})\s+au\s+(\d{1,2})\s+(\w+)\s+(\d{4})',
    caseSensitive: false,
  );

  /// Mois cross (ex: "Du mardi 28 octobre au samedi 01 novembre 2025")
  static final _rangeCrossRegex = RegExp(
    r'Du\s+\w+\s+(\d{1,2})\s+(\w+)\s+au\s+\w+\s+(\d{1,2})\s+(\w+)\s+(\d{4})\s+[àa]\s+(\d{1,2})h(\d{2})?',
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

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final allEvents = <Event>[];
      final results = await Future.wait(
        _urls.map((url) => _fetchPage(url)),
      );
      for (final list in results) {
        allEvents.addAll(list);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final upcoming = allEvents.where((e) {
        final fin = DateTime.tryParse(e.dateFin) ?? DateTime.tryParse(e.dateDebut);
        return fin != null && !fin.isBefore(today);
      }).toList();

      upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return upcoming;
    } catch (_) {
      return [];
    }
  }

  static Future<List<Event>> _fetchPage(String url) async {
    try {
      final response = await _dio.get<String>(url);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = <Event>[];
      final seen = <String>{};

      for (final match in _linkRegex.allMatches(html)) {
        final linkUrl = match.group(1) ?? '';
        final rawText = _cleanHtml(match.group(2) ?? '');

        // Ignorer les liens de navigation
        if (!rawText.contains('\u2013') && !rawText.contains('–')) continue;

        // Separer titre et dates via le tiret cadratin
        final dashIndex = rawText.contains('\u2013')
            ? rawText.indexOf('\u2013')
            : rawText.indexOf('–');
        if (dashIndex < 0) continue;

        final titre = rawText.substring(0, dashIndex).trim();
        if (titre.isEmpty) continue;

        final datePart = rawText.substring(dashIndex + 1).trim();

        // Parser les dates
        final dates = _parseDates(datePart);
        if (dates == null) continue;

        final id = 'filaplomb_${titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}_${dates.dateDebut}';
        if (!seen.add(id)) continue;

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: titre,
          descriptifLong: '$titre\n$datePart',
          dateDebut: dates.dateDebut,
          dateFin: dates.dateFin,
          horaires: dates.horaires,
          datesAffichageHoraires: datePart,
          lieuNom: 'Theatre le Fil a Plomb',
          lieuAdresse: '30 rue de la Chaine',
          commune: 'Toulouse',
          codePostal: 31000,
          type: 'Theatre',
          categorie: 'Theatre',
          reservationUrl: linkUrl,
        ),);
      }

      return events;
    } catch (_) {
      return [];
    }
  }

  static _ParsedDates? _parseDates(String text) {
    // Essayer d'abord le format cross-mois :
    // "Du mardi 28 octobre au samedi 01 novembre 2025 à 15h30"
    final crossMatch = _rangeCrossRegex.firstMatch(text);
    if (crossMatch != null) {
      final d1 = int.tryParse(crossMatch.group(1)!);
      final m1 = _moisFr[crossMatch.group(2)!.toLowerCase()];
      final d2 = int.tryParse(crossMatch.group(3)!);
      final m2 = _moisFr[crossMatch.group(4)!.toLowerCase()];
      final y = int.tryParse(crossMatch.group(5)!);
      final h = crossMatch.group(6) ?? '';
      final min = crossMatch.group(7) ?? '00';
      if (d1 != null && m1 != null && d2 != null && m2 != null && y != null) {
        return _ParsedDates(
          dateDebut: _isoDate(y, m1, d1),
          dateFin: _isoDate(y, m2, d2),
          horaires: '${h}h$min',
        );
      }
    }

    // "Du JOUR DD au JOUR DD MOIS YYYY à HHhMM"
    final rangeMatch = _rangeRegex.firstMatch(text);
    if (rangeMatch != null) {
      final d1 = int.tryParse(rangeMatch.group(1)!);
      final d2 = int.tryParse(rangeMatch.group(2)!);
      final m = _moisFr[rangeMatch.group(3)!.toLowerCase()];
      final y = int.tryParse(rangeMatch.group(4)!);
      final h = rangeMatch.group(5) ?? '';
      final min = rangeMatch.group(6) ?? '00';
      if (d1 != null && d2 != null && m != null && y != null) {
        return _ParsedDates(
          dateDebut: _isoDate(y, m, d1),
          dateFin: _isoDate(y, m, d2),
          horaires: '${h}h$min',
        );
      }
    }

    // "Du DD au DD MOIS YYYY" (sans jour de semaine)
    final rangeShortMatch = _rangeShortRegex.firstMatch(text);
    if (rangeShortMatch != null) {
      final d1 = int.tryParse(rangeShortMatch.group(1)!);
      final d2 = int.tryParse(rangeShortMatch.group(2)!);
      final m = _moisFr[rangeShortMatch.group(3)!.toLowerCase()];
      final y = int.tryParse(rangeShortMatch.group(4)!);
      if (d1 != null && d2 != null && m != null && y != null) {
        return _ParsedDates(
          dateDebut: _isoDate(y, m, d1),
          dateFin: _isoDate(y, m, d2),
          horaires: '',
        );
      }
    }

    // "Le JOUR DD MOIS YYYY à HHhMM"
    final singleMatch = _singleRegex.firstMatch(text);
    if (singleMatch != null) {
      final d = int.tryParse(singleMatch.group(1)!);
      final m = _moisFr[singleMatch.group(2)!.toLowerCase()];
      final y = int.tryParse(singleMatch.group(3)!);
      final h = singleMatch.group(4) ?? '';
      final min = singleMatch.group(5) ?? '00';
      if (d != null && m != null && y != null) {
        return _ParsedDates(
          dateDebut: _isoDate(y, m, d),
          dateFin: _isoDate(y, m, d),
          horaires: '${h}h$min',
        );
      }
    }

    return null;
  }

  static String _isoDate(int year, int month, int day) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ParsedDates {
  final String dateDebut;
  final String dateFin;
  final String horaires;

  const _ParsedDates({
    required this.dateDebut,
    required this.dateFin,
    required this.horaires,
  });
}
