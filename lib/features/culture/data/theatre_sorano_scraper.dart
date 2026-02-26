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

  /// Date ISO depuis l'URL : /spectacles/SLUG/2026-03-11/
  static final _urlDateRegex = RegExp(r'/(\d{4}-\d{2}-\d{2})/?');

  /// Dates textuelles (sans annee) : "11 → 13 mars", "le 13 avril",
  /// "31 mars → 2 avril", "6 → 21 mai"
  static final _datesBlockRegex = RegExp(
    r'<div\s+class="dates">\s*(.*?)\s*</div>',
    dotAll: true,
  );

  /// "11 → 13 mars" ou "6 → 21 mai"
  static final _dateRangeRegex = RegExp(
    r'(\d{1,2})\s*→\s*(\d{1,2})\s+(\w+)\.?',
  );

  /// "31 mars → 2 avril"
  static final _dateRangeCrossRegex = RegExp(
    r'(\d{1,2})\s+(\w+)\.?\s*→\s*(\d{1,2})\s+(\w+)\.?',
  );

  /// "le 13 avril"
  static final _dateSingleRegex = RegExp(
    r'le\s+(\d{1,2})\s+(\w+)\.?',
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
        final imageUrl = match.group(2) ?? '';
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

        // Date d'affichage brute
        final datesBlockMatch = _datesBlockRegex.firstMatch(cardHtml);
        final datesRaw = datesBlockMatch != null
            ? _cleanHtml(datesBlockMatch.group(1) ?? '')
            : '';

        // Date ISO : priorite a l'URL (/2026-03-11/), fallback texte
        String? dateDebut;
        String? dateFin;

        final urlDateMatch = _urlDateRegex.firstMatch(detailUrl);
        if (urlDateMatch != null) {
          dateDebut = urlDateMatch.group(1);
        }

        // Inferrer l'annee depuis l'URL ou la saison courante
        final year = dateDebut?.substring(0, 4) ?? _currentSeasonYear();

        // Parser la plage de dates textuelles pour dateFin
        final crossMatch = _dateRangeCrossRegex.firstMatch(datesRaw);
        if (crossMatch != null) {
          dateDebut ??= _buildIsoDate(crossMatch.group(1)!, crossMatch.group(2)!, year);
          dateFin = _buildIsoDate(crossMatch.group(3)!, crossMatch.group(4)!, year);
        } else {
          final rangeMatch = _dateRangeRegex.firstMatch(datesRaw);
          if (rangeMatch != null) {
            dateDebut ??= _buildIsoDate(rangeMatch.group(1)!, rangeMatch.group(3)!, year);
            dateFin = _buildIsoDate(rangeMatch.group(2)!, rangeMatch.group(3)!, year);
          } else {
            final singleMatch = _dateSingleRegex.firstMatch(datesRaw);
            if (singleMatch != null) {
              dateDebut ??= _buildIsoDate(singleMatch.group(1)!, singleMatch.group(2)!, year);
            }
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
          datesAffichageHoraires: datesRaw,
          lieuNom: 'Theatre Sorano',
          lieuAdresse: '35 Allees Jules Guesde',
          commune: 'Toulouse',
          codePostal: 31400,
          type: type,
          categorie: 'Theatre',
          reservationUrl: url,
          photoPath: imageUrl.isNotEmpty ? imageUrl : null,
        ),);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final upcoming = events.where((e) {
        final fin = DateTime.tryParse(e.dateFin) ?? DateTime.tryParse(e.dateDebut);
        if (fin == null) return false;
        return !fin.isBefore(today);
      }).toList();

      upcoming.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
      return upcoming;
    } catch (_) {
      return [];
    }
  }

  /// Construit une date ISO a partir du jour, mois francais et annee.
  static String? _buildIsoDate(String day, String month, String year) {
    final d = int.tryParse(day);
    final y = int.tryParse(year);
    final monthClean = month.toLowerCase().replaceAll('.', '');
    final m = _frenchMonths[monthClean];
    if (d == null || y == null || m == null) return null;
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  /// Annee de la saison en cours (sept→dec = annee+1, jan→aout = annee).
  static String _currentSeasonYear() {
    final now = DateTime.now();
    return now.month >= 9 ? '${now.year + 1}' : '${now.year}';
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
