import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Theatre du Grand Rond depuis
/// grand-rond.org/programmation.
///
/// Structure HTML :
/// <div class="container-fluid contenu_XX">  (tp/jp/ap/ev)
///   <div class="row">
///     <div class="col-md-6 bloc_spectacle"><img ...></div>
///     <div class="col-md-6 bloc_spectacle">
///       <h3>TITRE</h3>
///       <div class="etiquette XX">TYPE</div>
///       Compagnie : <strong>CIE</strong>
///       <p><strong>Du 29 au 31 janvier 2026, ... à 21h\nGenre : ...</strong></p>
///       <p>Description...</p>
///       <a href="URL" class="bouton_plus">En savoir +</a>
///     </div>
///   </div>
/// </div>
class TheatreGrandRondScraper {
  TheatreGrandRondScraper._();

  static const _programUrl = 'https://www.grand-rond.org/programmation';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Image dans le premier bloc_spectacle (sibling)
  static final _imgBlocRegex = RegExp(
    r'<div class="col-md-6 bloc_spectacle">\s*<img[^>]+src="([^"]*)"',
  );

  /// Bloc spectacle : <h3>TITRE</h3> ... <a href="URL" class="bouton_plus">
  static final _blocRegex = RegExp(
    r'<div class="col-md-6 bloc_spectacle">\s*<h3>(.*?)</h3>(.*?)<a\s+href="([^"]*)"[^>]*class="bouton_plus"',
    dotAll: true,
  );

  /// Etiquette type
  static final _etiquetteRegex = RegExp(
    r'<div class="etiquette \w+">(.*?)</div>',
  );

  /// Compagnie
  static final _compagnieRegex = RegExp(
    r'Compagnie\s*:\s*<strong>(.*?)</strong>',
    dotAll: true,
  );

  /// Premier paragraphe bold avec dates
  static final _datesParagraphRegex = RegExp(
    r'<p><strong>(.*?)</strong>',
    dotAll: true,
  );

  /// "Du 29 au 31 janvier 2026"
  static final _dateRangeRegex = RegExp(
    r'[Dd]u\s+(\d{1,2})\s+au\s+(\d{1,2})\s+(\w+)\s+(\d{4})',
  );

  /// "Du 31 mars au 2 avril 2026" (cross-month)
  static final _dateRangeCrossRegex = RegExp(
    r'[Dd]u\s+(\d{1,2})\s+(\w+)\s+au\s+(\d{1,2})\s+(\w+)\s+(\d{4})',
  );

  /// "Lundi 2 mars 2026"
  static final _dateSingleRegex = RegExp(
    r'(?:lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)\s+(\d{1,2})\s+(\w+)\s+(\d{4})',
    caseSensitive: false,
  );

  /// Horaire "à 21h", "à 19h", "à 21h00"
  static final _horaireRegex = RegExp(
    r'\u00e0\s+(\d{1,2})\s*h\s*(\d{2})?',
  );

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_programUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = <Event>[];

      final imageUrls = _imgBlocRegex
          .allMatches(html)
          .map((m) => m.group(1))
          .toList();
      var imgIdx = 0;

      for (final match in _blocRegex.allMatches(html)) {
        final titre = _cleanHtml(match.group(1) ?? '');
        final infoHtml = match.group(2) ?? '';
        final url = match.group(3) ?? '';

        if (titre.isEmpty) continue;

        // Type
        final etiqMatch = _etiquetteRegex.firstMatch(infoHtml);
        final type = etiqMatch != null
            ? _cleanHtml(etiqMatch.group(1) ?? '')
            : 'Spectacle';

        // Compagnie
        final cieMatch = _compagnieRegex.firstMatch(infoHtml);
        final compagnie = cieMatch != null
            ? _cleanHtml(cieMatch.group(1) ?? '')
            : '';

        // Dates text
        final datesParagraph = _datesParagraphRegex.firstMatch(infoHtml);
        final datesText = datesParagraph != null
            ? _cleanHtml(datesParagraph.group(1) ?? '')
            : '';

        // Parse dates
        String? dateDebut;
        String? dateFin;

        // Cross-month range first: "Du 31 mars au 2 avril 2026"
        final crossMatch = _dateRangeCrossRegex.firstMatch(datesText);
        if (crossMatch != null) {
          dateDebut = _buildIsoDate(
            crossMatch.group(1)!,
            crossMatch.group(2)!,
            crossMatch.group(5)!,
          );
          dateFin = _buildIsoDate(
            crossMatch.group(3)!,
            crossMatch.group(4)!,
            crossMatch.group(5)!,
          );
        }

        // Same-month range: "Du 29 au 31 janvier 2026"
        if (dateDebut == null) {
          final rangeMatch = _dateRangeRegex.firstMatch(datesText);
          if (rangeMatch != null) {
            dateDebut = _buildIsoDate(
              rangeMatch.group(1)!,
              rangeMatch.group(3)!,
              rangeMatch.group(4)!,
            );
            dateFin = _buildIsoDate(
              rangeMatch.group(2)!,
              rangeMatch.group(3)!,
              rangeMatch.group(4)!,
            );
          }
        }

        // Single date: "Lundi 2 mars 2026"
        if (dateDebut == null) {
          final singleMatch = _dateSingleRegex.firstMatch(datesText);
          if (singleMatch != null) {
            dateDebut = _buildIsoDate(
              singleMatch.group(1)!,
              singleMatch.group(2)!,
              singleMatch.group(3)!,
            );
            dateFin = dateDebut;
          }
        }

        if (dateDebut == null) continue;

        // Image
        final imageUrl = imgIdx < imageUrls.length ? imageUrls[imgIdx] : null;
        imgIdx++;

        // Horaire
        String horaires = '';
        final horaireMatch = _horaireRegex.firstMatch(datesText);
        if (horaireMatch != null) {
          final h = horaireMatch.group(1) ?? '';
          final m = horaireMatch.group(2) ?? '00';
          horaires = '${h}h$m';
        }

        final slug = Uri.tryParse(url)
                ?.pathSegments
                .where((s) => s.isNotEmpty)
                .lastOrNull ??
            titre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        final id = 'grandrond_${slug}_$dateDebut';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: [
            type,
            if (compagnie.isNotEmpty) compagnie,
          ].join(' \u00B7 '),
          descriptifLong: [
            titre,
            if (compagnie.isNotEmpty) compagnie,
            type,
          ].join('\n'),
          dateDebut: dateDebut,
          dateFin: dateFin ?? dateDebut,
          datesAffichageHoraires: datesText.length > 80
              ? datesText.substring(0, 80)
              : datesText,
          horaires: horaires,
          lieuNom: 'Theatre du Grand Rond',
          lieuAdresse: '23 Rue des Potiers',
          commune: 'Toulouse',
          codePostal: 31000,
          type: type,
          categorie: 'Theatre',
          reservationUrl: url,
          photoPath: imageUrl,
        ),);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final upcoming = events.where((e) {
        final fin =
            DateTime.tryParse(e.dateFin) ?? DateTime.tryParse(e.dateDebut);
        if (fin == null) return false;
        return !fin.isBefore(today);
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
        .replaceAll('&rsquo;', '\u2019')
        .replaceAll('&lsquo;', '\u2018')
        .replaceAll('&rdquo;', '\u201D')
        .replaceAll('&ldquo;', '\u201C')
        .replaceAll('&agrave;', '\u00E0')
        .replaceAll('&eacute;', '\u00E9')
        .replaceAll('&egrave;', '\u00E8')
        .replaceAll('&ecirc;', '\u00EA')
        .replaceAll('&ocirc;', '\u00F4')
        .replaceAll('&ucirc;', '\u00FB')
        .replaceAll('&ccedil;', '\u00E7')
        .replaceAll('&hellip;', '\u2026')
        .replaceAll('&#8211;', '\u2013')
        .replaceAll('&#8217;', '\u2019')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
