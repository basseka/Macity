import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Theatre Sorano depuis theatre-sorano.fr/la-saison/.
///
/// Strategie :
/// 1. Fetch la page saison HTML
/// 2. Parser les <li class="lien-spectacle"> : dates, type, auteur, titre, lien detail
/// 3. Convertir en [Event], filtrer J+30, trier par date
class TheatreSoranoScraper {
  TheatreSoranoScraper._();

  static const _saisonUrl = 'https://www.theatre-sorano.fr/la-saison/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Regex pour extraire chaque <li> spectacle.
  /// Capture : (1) contenu du <a> avec href+style, (2) lien "En savoir +"
  static final _liRegex = RegExp(
    r"""<li\s+class="lien-spectacle[^"]*">\s*<a\s+href="([^"]*)"[^>]*class="spectacles"[^>]*style="background:\s*url\('([^']*)'\)[^"]*"[^>]*>(.*?)</a>\s*<div\s+class="boutons">\s*<a\s+href="([^"]*)"[^>]*>""",
    dotAll: true,
  );

  /// Regex dates : "18 → 19 nov. 2025" ou "le 22 novembre 2025"
  static final _dateRangeRegex = RegExp(
    r'(\d{1,2})\s*(?:→|->)\s*(\d{1,2})\s+(\w+)\.?\s+(\d{4})',
  );
  static final _dateSingleRegex = RegExp(
    r'le\s+(\d{1,2})\s+(\w+)\s+(\d{4})',
    caseSensitive: false,
  );

  /// Extraire type, auteur, titre depuis le contenu du <a>.
  static final _typeRegex = RegExp(
    r'<p\s+class="type petit">(.*?)</p>',
    dotAll: true,
  );
  static final _auteurRegex = RegExp(
    r'<p\s+class="auteur petit">(.*?)</p>',
    dotAll: true,
  );
  static final _titreRegex = RegExp(
    r'<p\s+class="letitre">(.*?)</p>',
    dotAll: true,
  );

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_saisonUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = <Event>[];

      for (final match in _liRegex.allMatches(html)) {
        final detailUrl = match.group(1) ?? '';
        final cardHtml = match.group(3) ?? '';
        final savoirPlusUrl = match.group(4) ?? '';

        // Titre
        final titreMatch = _titreRegex.firstMatch(cardHtml);
        final titre = titreMatch != null
            ? _cleanHtml(titreMatch.group(1) ?? '')
            : '';
        if (titre.isEmpty) continue;

        // Type (Theatre, Danse, etc.)
        final typeMatch = _typeRegex.firstMatch(cardHtml);
        final type = typeMatch != null
            ? _cleanHtml(typeMatch.group(1) ?? '')
            : 'Spectacle';

        // Auteur / metteur en scene
        final auteurMatch = _auteurRegex.firstMatch(cardHtml);
        final auteur = auteurMatch != null
            ? _cleanHtml(auteurMatch.group(1) ?? '')
            : '';

        // Dates
        String? dateDebut;
        String? dateFin;

        final rangeMatch = _dateRangeRegex.firstMatch(cardHtml);
        if (rangeMatch != null) {
          final dayStart = rangeMatch.group(1)!;
          final dayEnd = rangeMatch.group(2)!;
          final month = rangeMatch.group(3)!;
          final year = rangeMatch.group(4)!;
          dateDebut = _buildIsoDate(dayStart, month, year);
          dateFin = _buildIsoDate(dayEnd, month, year);
        } else {
          final singleMatch = _dateSingleRegex.firstMatch(cardHtml);
          if (singleMatch != null) {
            final day = singleMatch.group(1)!;
            final month = singleMatch.group(2)!;
            final year = singleMatch.group(3)!;
            dateDebut = _buildIsoDate(day, month, year);
            dateFin = dateDebut;
          }
        }

        if (dateDebut == null) continue;

        final url = savoirPlusUrl.isNotEmpty ? savoirPlusUrl : detailUrl;
        final slug = Uri.tryParse(url)
                ?.pathSegments
                .where((s) => s.isNotEmpty)
                .lastOrNull ??
            titre.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
        final id = 'sorano_${slug}_$dateDebut';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: auteur.isNotEmpty
              ? '$type · $auteur'
              : type,
          descriptifLong: auteur.isNotEmpty
              ? '$titre\n$type\n$auteur'
              : '$titre\n$type',
          dateDebut: dateDebut,
          dateFin: dateFin ?? dateDebut,
          lieuNom: 'Theatre Sorano',
          lieuAdresse: '35 Allees Jules Guesde',
          commune: 'Toulouse',
          codePostal: 31400,
          type: type,
          categorie: 'Theatre',
          reservationUrl: url,
        ),);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final cutoff = today.add(const Duration(days: 30));

      final upcoming = events.where((e) {
        final d = DateTime.tryParse(e.dateDebut);
        if (d == null) return false;
        // Garder les events dont la date de fin n'est pas passee
        final fin = DateTime.tryParse(e.dateFin) ?? d;
        return !fin.isBefore(today) && d.isBefore(cutoff);
      }).toList();

      upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return upcoming;
    } catch (_) {
      return [];
    }
  }

  static String? _buildIsoDate(String day, String month, String year) {
    final d = int.tryParse(day);
    final y = int.tryParse(year);
    final monthClean = month.toLowerCase().replaceAll('.', '');
    final m = _frenchMonths[monthClean];
    if (d == null || y == null || m == null) return null;
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  static const _frenchMonths = {
    'janvier': 1, 'jan': 1, 'janv': 1,
    'fevrier': 2, 'février': 2, 'fev': 2, 'févr': 2,
    'mars': 3, 'mar': 3,
    'avril': 4, 'avr': 4,
    'mai': 5,
    'juin': 6,
    'juillet': 7, 'juil': 7,
    'aout': 8, 'août': 8,
    'septembre': 9, 'sept': 9, 'sep': 9,
    'octobre': 10, 'oct': 10,
    'novembre': 11, 'nov': 11,
    'decembre': 12, 'décembre': 12, 'dec': 12, 'déc': 12,
  };

  static String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '\u201D')
        .replaceAll('&ldquo;', '\u201C')
        .replaceAll('&#8211;', '\u2013')
        .replaceAll('&#8217;', '\u2019')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
