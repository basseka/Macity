import 'package:dio/dio.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Scrape la programmation du Theatre du Pont Neuf depuis
/// theatredupontneuf.fr/spectacles25-26/.
///
/// Structure HTML : sections vc_row alternees avec :
/// - Colonne gauche : <h2><b>TITRE</b></h2> + <p> descriptions/casting
/// - Colonne droite : <h3>dates</h3> + <h3>horaire</h3> + <h2>tarif</h2>
/// - Separateur orange entre chaque spectacle
class TheatrePontNeufScraper {
  TheatrePontNeufScraper._();

  static const _spectaclesUrl =
      'https://www.theatredupontneuf.fr/spectacles25-26/';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120',
    },
  ),);

  /// Chaque spectacle est dans une section vc_row contenant 2 colonnes (sm-6).
  /// On capture la section entiere entre deux separateurs orange.
  static final _sectionRegex = RegExp(
    r'<div\s+class="wpb_column vc_column_container vc_col-sm-6">'
    r'<div class="vc_column-inner"><div class="wpb_wrapper">\s*'
    r'<div class="wpb_text_column wpb_content_element\s*">\s*'
    r'<div class="wpb_wrapper">\s*'
    r'(.*?)'
    r'</div>\s*</div>.*?'
    r'<div class="wpb_column vc_column_container vc_col-sm-6">'
    r'.*?'
    r'<div class="wpb_text_column wpb_content_element\s*">\s*'
    r'<div class="wpb_wrapper">\s*'
    r'(.*?)'
    r'</div>\s*</div>',
    dotAll: true,
  );

  /// Titre dans <h2><b>...</b></h2> ou <p>...</p> en premier paragraphe.
  static final _titreH2Regex = RegExp(
    r'<h2><b>(.*?)</b></h2>',
    dotAll: true,
  );
  static final _titrePRegex = RegExp(
    r'^<p>(.*?)</p>',
    dotAll: true,
  );

  /// Dates dans <h3>du ... au ...</h3> ou <h3>les ... et ...</h3> ou <h3>le ...</h3>.
  static final _dateH3Regex = RegExp(
    r'<h3>(.*?)</h3>',
    dotAll: true,
  );

  /// "du mardi 16 au samedi 20 septembre" ou "du mercredi 24 au vendredi 26 septembre"
  static final _dateRangeRegex = RegExp(
    r'du\s+\w+\s+(\d{1,2})\s+au\s+\w+\s+(\d{1,2})\s+(\w+)',
    caseSensitive: false,
  );

  /// "les jeudi 18 et vendredi 19 décembre"
  static final _dateLesRegex = RegExp(
    r'les?\s+\w+\s+(\d{1,2})\s+et\s+\w+\s+(\d{1,2})\s+(\w+)',
    caseSensitive: false,
  );

  /// "le vendredi 13 mars"
  static final _dateSingleRegex = RegExp(
    r'le\s+\w+\s+(\d{1,2})\s+(\w+)',
    caseSensitive: false,
  );

  /// Horaire "20H30" ou "20h30"
  static final _horaireRegex = RegExp(
    r'(\d{1,2})[Hh](\d{2})',
  );

  /// Tarif dans <h2>Tarif ... : X euros</h2>
  static final _tarifRegex = RegExp(
    r'Tarif[^:]*:\s*(.*?)(?:<|$)',
    caseSensitive: false,
    dotAll: true,
  );

  static Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final response = await _dio.get<String>(_spectaclesUrl);
      final html = response.data;
      if (html == null || html.isEmpty) return [];

      final events = <Event>[];

      for (final match in _sectionRegex.allMatches(html)) {
        final leftHtml = match.group(1) ?? '';
        final rightHtml = match.group(2) ?? '';

        if (leftHtml.isEmpty && rightHtml.isEmpty) continue;

        // Titre
        String titre = '';
        final titreH2 = _titreH2Regex.firstMatch(leftHtml);
        if (titreH2 != null) {
          titre = _cleanHtml(titreH2.group(1) ?? '');
        } else {
          final titreP = _titrePRegex.firstMatch(leftHtml);
          if (titreP != null) {
            titre = _cleanHtml(titreP.group(1) ?? '');
          }
        }
        if (titre.isEmpty) continue;

        // Description (tous les <p> restants)
        final descParts = <String>[];
        for (final p in RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true)
            .allMatches(leftHtml)) {
          final text = _cleanHtml(p.group(1) ?? '');
          if (text.isNotEmpty && text != titre) {
            descParts.add(text);
          }
        }
        final description = descParts.take(3).join('\n');

        // Dates
        String? dateDebut;
        String? dateFin;
        String dateAffichage = '';

        final dateH3 = _dateH3Regex.firstMatch(rightHtml);
        if (dateH3 != null) {
          final dateText = _cleanHtml(dateH3.group(1) ?? '');
          dateAffichage = dateText;

          final rangeMatch = _dateRangeRegex.firstMatch(dateText);
          if (rangeMatch != null) {
            dateDebut = _frenchDateToIso(
                '${rangeMatch.group(1)} ${rangeMatch.group(3)}',);
            dateFin = _frenchDateToIso(
                '${rangeMatch.group(2)} ${rangeMatch.group(3)}',);
          } else {
            final lesMatch = _dateLesRegex.firstMatch(dateText);
            if (lesMatch != null) {
              dateDebut = _frenchDateToIso(
                  '${lesMatch.group(1)} ${lesMatch.group(3)}',);
              dateFin = _frenchDateToIso(
                  '${lesMatch.group(2)} ${lesMatch.group(3)}',);
            } else {
              final singleMatch = _dateSingleRegex.firstMatch(dateText);
              if (singleMatch != null) {
                dateDebut = _frenchDateToIso(
                    '${singleMatch.group(1)} ${singleMatch.group(2)}',);
                dateFin = dateDebut;
              }
            }
          }
        }

        if (dateDebut == null) continue;

        // Horaire
        String horaires = '';
        final horaireMatch = _horaireRegex.firstMatch(rightHtml);
        if (horaireMatch != null) {
          horaires = '${horaireMatch.group(1)}h${horaireMatch.group(2)}';
        }

        // Tarif
        String tarif = '';
        final tarifMatch = _tarifRegex.firstMatch(rightHtml);
        if (tarifMatch != null) {
          tarif = _cleanHtml(tarifMatch.group(1) ?? '');
        }

        final slug = titre
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-|-$'), '');
        final id = 'pontneuf_${slug}_$dateDebut';

        events.add(Event(
          identifiant: id,
          titre: titre,
          descriptifCourt: description.isNotEmpty
              ? (description.length > 120
                  ? '${description.substring(0, 120)}...'
                  : description)
              : titre,
          descriptifLong: description.isNotEmpty ? description : titre,
          dateDebut: dateDebut,
          dateFin: dateFin ?? dateDebut,
          datesAffichageHoraires: dateAffichage,
          horaires: horaires,
          lieuNom: 'Theatre du Pont Neuf',
          lieuAdresse: '22 Rue des Amidonniers',
          commune: 'Toulouse',
          codePostal: 31000,
          type: 'Theatre',
          categorie: 'Theatre',
          tarifNormal: tarif,
          reservationUrl:
              'https://www.theatredupontneuf.fr/evenements/reservations/',
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

  static String? _frenchDateToIso(String? dateText) {
    if (dateText == null || dateText.isEmpty) return null;
    final regex = RegExp(r'(\d{1,2})\s+(\w+)');
    final match = regex.firstMatch(dateText);
    if (match == null) return null;

    final dayStr = match.group(1);
    final monthRaw = match.group(2);
    if (dayStr == null || monthRaw == null) return null;
    final day = int.tryParse(dayStr);
    if (day == null) return null;

    final month = _frenchMonths[monthRaw.toLowerCase()];
    if (month == null) return null;

    final now = DateTime.now();
    var year = now.year;
    final candidate = DateTime(year, month, day);
    if (candidate.isBefore(now.subtract(const Duration(days: 60)))) {
      year++;
    }

    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  static const _frenchMonths = {
    'janvier': 1, 'fevrier': 2, 'février': 2,
    'mars': 3, 'avril': 4, 'mai': 5, 'juin': 6,
    'juillet': 7, 'aout': 8, 'août': 8,
    'septembre': 9, 'octobre': 10,
    'novembre': 11, 'decembre': 12, 'décembre': 12,
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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
